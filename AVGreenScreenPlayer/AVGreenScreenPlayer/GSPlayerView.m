/*
     File: GSPlayerView.m
 Abstract: Player view using AVPlayerItemVideoOutput with chroma key filter.
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

#import "GSPlayerView.h"

#define FREEWHEELING_PERIOD_IN_SECONDS 0.5
#define ADVANCE_INTERVAL_IN_SECONDS 0.1

@interface GSPlayerView ()
{
	AVPlayerItem *_playerItem;
	AVPlayerItemVideoOutput *_playerItemVideoOutput;
	CVDisplayLinkRef _displayLink;
	CMVideoFormatDescriptionRef _videoInfo;
	
	uint64_t _lastHostTime;
	dispatch_queue_t _queue;
}
@end

@interface GSPlayerView (AVPlayerItemOutputPullDelegate) <AVPlayerItemOutputPullDelegate>
@end

#pragma mark -

@implementation GSPlayerView

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext);

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self)
	{
        _videoInfo = nil;
        
		_queue = dispatch_queue_create(NULL, NULL);
		
		_playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB)}];
		if (_playerItemVideoOutput)
		{
			// Create a CVDisplayLink to receive a callback at every vsync
			CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
			CVDisplayLinkSetOutputCallback(_displayLink, displayLinkCallback, (__bridge void *)self);
			// Pause the displayLink till ready to conserve power
			CVDisplayLinkStop(_displayLink);
			// Request notification for media change in advance to start up displayLink or any setup necessary
			[_playerItemVideoOutput setDelegate:self queue:_queue];
			[_playerItemVideoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ADVANCE_INTERVAL_IN_SECONDS];
		}
		
		self.videoLayer = [[AVSampleBufferDisplayLayer alloc] init];
		self.videoLayer.bounds = self.bounds;
		self.videoLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
		self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
		self.videoLayer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);

		[self setLayer:self.videoLayer];
		[self setWantsLayer:YES];
		
		CIFilter *chromaKeyFilter = [CIFilter filterWithName:@"GSChromaKeyFilter"];
		[chromaKeyFilter setName:@"chromaKeyFilter"];
		
#if defined(MAC_OS_X_VERSION_10_9) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_9
		[self setLayerUsesCoreImageFilters:YES];
#endif
		
		[[self layer] setFilters:@[chromaKeyFilter]];
	}
	
	return self;
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	if (!newSuperview) {

        if (_videoInfo) {
            CFRelease(_videoInfo);
        }
		
		if (_displayLink)
		{
			CVDisplayLinkStop(_displayLink);
			CVDisplayLinkRelease(_displayLink);
		}

		dispatch_sync(_queue, ^{
			[_playerItemVideoOutput setDelegate:nil queue:NULL];
		});

	}
}

- (void)dealloc
{
	self.playerItem = nil;
	
	self.videoLayer = nil;
}

#pragma mark -

- (AVPlayerItem *)playerItem
{
	return _playerItem;
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem
{
	if (_playerItem != playerItem)
	{
		if (_playerItem)
			[_playerItem removeOutput:_playerItemVideoOutput];
		
		_playerItem = playerItem;
		
		if (_playerItem)
			[_playerItem addOutput:_playerItemVideoOutput];
	}
}

- (NSColor *)chromaKeyColor
{
	return [NSColor colorWithCIColor:[self valueForKeyPath:@"layer.filters.chromaKeyFilter.inputColor"]];
}

- (void)setChromaKeyColor:(NSColor *)chromaKeyColor
{
	// The chromaKeyColor is bound to the value of the chromaKeyColorWell in the xib
	[self setValue:[CIColor colorWithCGColor:[chromaKeyColor CGColor]] forKeyPath:@"layer.filters.chromaKeyFilter.inputColor"];
}

#pragma mark -

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer atTime:(CMTime)outputTime
{
	// CVPixelBuffer is wrapped in a CMSampleBuffer and then displayed on a AVSampleBufferDisplayLayer
	CMSampleBufferRef sampleBuffer = NULL;
	OSStatus err = noErr;

	if (!_videoInfo || !CMVideoFormatDescriptionMatchesImageBuffer(_videoInfo, pixelBuffer)) {
        if (_videoInfo) {
            CFRelease(_videoInfo);
            _videoInfo = nil;
        }
		err = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &_videoInfo);
	}

	if (err) {
		NSLog(@"Error at CMVideoFormatDescriptionCreateForImageBuffer %d", err);
	}
	
	// decodeTimeStamp is set to kCMTimeInvalid since we already receive decoded frames
	CMSampleTimingInfo sampleTimingInfo = {
		.duration = kCMTimeInvalid,
		.presentationTimeStamp = outputTime,
		.decodeTimeStamp = kCMTimeInvalid
	};

	// Wrap the pixel buffer in a sample buffer
	err = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, _videoInfo, &sampleTimingInfo, &sampleBuffer);
	
	if (err) {
		NSLog(@"Error at CMSampleBufferCreateForImageBuffer %d", err);
	}

	// Enqueue sample buffers which will be displayed at their above set presentationTimeStamp
	if (self.videoLayer.readyForMoreMediaData) {
		[self.videoLayer enqueueSampleBuffer:sampleBuffer];
	}
	
	CFRelease(sampleBuffer);
}

#pragma mark -

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext)
{
	GSPlayerView *self = (__bridge GSPlayerView *)displayLinkContext;
	AVPlayerItemVideoOutput *playerItemVideoOutput = self->_playerItemVideoOutput;
	
	// The displayLink calls back at every vsync (screen refresh)
	// Compute itemTime for the next vsync
	CMTime outputItemTime = [playerItemVideoOutput itemTimeForCVTimeStamp:*inOutputTime];
	if ([playerItemVideoOutput hasNewPixelBufferForItemTime:outputItemTime])
	{
		self->_lastHostTime = inOutputTime->hostTime;
		
		// Copy the pixel buffer to be displayed next and add it to AVSampleBufferDisplayLayer for display
		CVPixelBufferRef pixBuff = [playerItemVideoOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
		
		[self displayPixelBuffer:pixBuff atTime:outputItemTime];
		
		CVBufferRelease(pixBuff);
	}
	else
	{
		CMTime elapsedTime = CMClockMakeHostTimeFromSystemUnits(inNow->hostTime - self->_lastHostTime);
		if (CMTimeGetSeconds(elapsedTime) > FREEWHEELING_PERIOD_IN_SECONDS)
		{
			// No new images for a while.  Shut down the display link to conserve power, but request a wakeup call if new images are coming.
			
			CVDisplayLinkStop(displayLink);
			
			[playerItemVideoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ADVANCE_INTERVAL_IN_SECONDS];
		}
	}
	
	return kCVReturnSuccess;
}

@end

#pragma mark -

@implementation GSPlayerView (AVPlayerItemOutputPullDelegate)

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
	// Start running again.
	_lastHostTime = CVGetCurrentHostTime();
	
	CVDisplayLinkStart(_displayLink);
}

@end
