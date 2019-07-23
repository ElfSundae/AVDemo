/*
     File: GSDocument.m
 Abstract: Main document
  Version: 1.3
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "GSDocument.h"

#import <AVFoundation/AVFoundation.h>

#import "GSPlayerView.h"

static void *GSPlayerItemStatusContext = &GSPlayerItemStatusContext;
NSString* const GSMouseDownNotification = @"GSMouseDownNotification";
NSString* const GSMouseUpNotification = @"GSMouseUpNotification";

@interface GSTimeSliderCell : NSSliderCell

@end

@interface GSTimeSlider : NSSlider

@end

// Custom NSSlider and NSSliderCell subclasses to track scrubbing

@implementation GSTimeSliderCell

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
	if (flag) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GSMouseUpNotification object:self];
	}
	[super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
}

@end

@implementation GSTimeSlider

- (void)mouseDown:(NSEvent *)theEvent
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GSMouseDownNotification object:self];
	[super mouseDown:theEvent];
}

@end

@interface GSDocument ()

@property (nonatomic, assign) IBOutlet GSPlayerView *playerView;
@property (nonatomic, assign) IBOutlet NSButton *playPauseButton;
@property (nonatomic, assign) IBOutlet GSTimeSlider *currentTimeSlider;
@property (nonatomic, assign) IBOutlet NSColorWell *chromaKeyColorWell;

@property double currentTime;
@property (readonly) double duration;

- (IBAction)togglePlayPause:(id)sender;

@end

@implementation GSDocument

{
	AVPlayer *_player;
    AVPlayerItem *_currentPlayerItem;
	float _playRateToRestore;
	id _observer;
}

#pragma mark -

- (id)init
{
	self = [super init];
	
	if (self)
	{
		_player = [[AVPlayer alloc] init];
		
		[self addTimeObserverToPlayer];
    }
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GSMouseDownNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GSMouseUpNotification object:nil];
	
	[_player removeTimeObserver:_observer];
	
	_player = nil;
	_currentPlayerItem = nil;
}

#pragma mark -

- (NSString *)windowNibName
{
	return @"GSDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
	[super windowControllerDidLoadNib:windowController];
	
    _currentPlayerItem = [_player currentItem];
	self.playerView.playerItem = _currentPlayerItem;
    
	[self.currentTimeSlider setDoubleValue:0.0];
	
	[self addObserver:self forKeyPath:@"self.player.currentItem.status" options:NSKeyValueObservingOptionNew context:GSPlayerItemStatusContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:_currentPlayerItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginScrubbing:) name:GSMouseDownNotification object:self.currentTimeSlider];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endScrubbing:) name:GSMouseUpNotification object:self.currentTimeSlider.cell];
}

- (void)close
{
	self.playerView = nil;
	
	self.playPauseButton = nil;
	
	self.currentTimeSlider = nil;
	
	self.chromaKeyColorWell = nil;
	
	[self removeObserver:self forKeyPath:@"self.player.currentItem.status"];
	
	[super close];
}

#pragma mark -

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
	if (playerItem)
	{
		[_player replaceCurrentItemWithPlayerItem:playerItem];
		return YES;
	}
	
	return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == GSPlayerItemStatusContext) {
		AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
		if (status == AVPlayerItemStatusReadyToPlay) {
			self.playerView.videoLayer.controlTimebase = _player.currentItem.timebase;
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -

- (IBAction)togglePlayPause:(id)sender
{
	if (CMTIME_COMPARE_INLINE([[_player currentItem] currentTime], >=, [[_player currentItem] duration]))
		[[_player currentItem] seekToTime:kCMTimeZero];
	
	[_player setRate:([_player rate] == 0.0f ? 1.0f : 0.0f)];
	
	[(NSButton *)sender setTitle:([_player rate] == 0.0f ? @"Play" : @"Pause")];
}

+ (NSSet *)keyPathsForValuesAffectingDuration
{
	return [NSSet setWithObjects:@"player.currentItem", @"player.currentItem.status", nil];
}

- (double)duration
{
	AVPlayerItem *playerItem = [_player currentItem];
	
	if ([playerItem status] == AVPlayerItemStatusReadyToPlay)
		return CMTimeGetSeconds([[playerItem asset] duration]);
	else
		return 0.f;
}

- (double)currentTime
{
	return CMTimeGetSeconds([_player currentTime]);
}

- (void)setCurrentTime:(double)time
{
	// Flush the previous enqueued sample buffers for display while scrubbing
	[self.playerView.videoLayer flush];
	
	[_player seekToTime:CMTimeMakeWithSeconds(time, 1)];
}

#pragma mark -

- (void)playerItemDidPlayToEndTime:(NSNotification *)notification
{
	[(NSButton *)self.playPauseButton setTitle:([_player rate] == 0.0f ? @"Play" : @"Pause")];
}

- (void)addTimeObserverToPlayer
{
	if (_observer)
		return;
    // __weak is used to ensure that a retain cycle between the document, player and notification block is not formed.
	__weak GSDocument* weakSelf = self;
	_observer = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 10) queue:dispatch_get_main_queue() usingBlock:
						  ^(CMTime time) {
							  [weakSelf syncScrubber];
						  }];
}

- (void)removeTimeObserverFromPlayer
{
	if (_observer)
	{
		[_player removeTimeObserver:_observer];
		_observer = nil;
	}
}

#pragma mark - Scrubbing Utilities

- (void)beginScrubbing:(NSNotification*)notification
{
	_playRateToRestore = [_player rate];
	
	[self removeTimeObserverFromPlayer];
	
	[_player setRate:0.0];
}

- (void)endScrubbing:(NSNotification*)notification
{
	[_player setRate:_playRateToRestore];
	
	[self addTimeObserverToPlayer];
}

- (void)syncScrubber
{
	double time = CMTimeGetSeconds([_player currentTime]);
	
	[self.currentTimeSlider setDoubleValue:time];
}

@end
