/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The player's view controller class. 
  This controller manages the main view and a sublayer; the mainPlayerLayer. This controller also manages as a subview a UIImageView nammed loupeView. loupeView hosts a layer hirearchy that manages the zoomPlayerLayer.
  Users interact with the position of loupeView in respose to IBActions from a UIPanGestureRecognizer.
 */

#import "APLViewController.h"

@import MobileCoreServices;
@import CoreMedia;

#define ZOOM_FACTOR 4.0
#define LOUPE_BEZEL_WIDTH 18.0


@interface APLViewController () <UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate>

{
	BOOL _haveSetupPlayerLayers;
}

@property AVPlayer *player;
@property AVPlayerLayer *zoomPlayerLayer;
@property AVPlayerLayer *mainPlayerLayer;
@property id notificationToken;

@property (weak) IBOutlet UINavigationBar *navigationBar;
@property (weak) IBOutlet UIImageView *loupeView;

@end

@implementation APLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	_player = [[AVPlayer alloc] init];
	_player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
	_haveSetupPlayerLayers = NO;
}

- (IBAction)handleTapFrom:(UITapGestureRecognizer *)recognizer
{
	self.navigationBar.hidden = !self.navigationBar.hidden;
}

- (IBAction)handlePanFrom:(UIPanGestureRecognizer *)recognizer
{
	CGPoint translation = [recognizer translationInView:self.view];
    
	recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
	                                     recognizer.view.center.y + translation.y);
	[recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	self.zoomPlayerLayer.position = CGPointMake(self.zoomPlayerLayer.position.x - translation.x * ZOOM_FACTOR,
	                                        self.zoomPlayerLayer.position.y - translation.y * ZOOM_FACTOR);
	[CATransaction commit];
}

- (void)viewDidLayoutSubviews
{
	if (!_haveSetupPlayerLayers) {
		// Main PlayerLayer.
		self.mainPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
		[self.view.layer insertSublayer:self.mainPlayerLayer below:self.loupeView.layer];
		self.mainPlayerLayer.frame = self.view.layer.bounds;

		// Build the loupe.
		// Content layer serves two functions:
		//  - An opaque black backdrop, since our AVPlayerLayers have a finite edge.
		//  - Applies a sub-layers only mask on behalf of the loupe view
		CALayer *contentLayer = [CALayer layer];
		contentLayer.frame = self.loupeView.bounds;
		contentLayer.backgroundColor = [[UIColor blackColor] CGColor];
		
		// The content layer has a circular mask applied.
		CAShapeLayer *maskLayer = [CAShapeLayer layer];
		maskLayer.frame = contentLayer.bounds;
		
		CGMutablePathRef circlePath = CGPathCreateMutable();
		CGPathAddEllipseInRect(circlePath, NULL, CGRectInset(self.loupeView.layer.bounds, LOUPE_BEZEL_WIDTH , LOUPE_BEZEL_WIDTH));
		
		maskLayer.path = circlePath;
		CGPathRelease(circlePath);
		
		contentLayer.mask = maskLayer;
		
		// Set up the zoom AVPlayerLayer.
		self.zoomPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
		CGSize zoomSize = CGSizeMake(self.view.layer.bounds.size.width * ZOOM_FACTOR, self.view.layer.bounds.size.height * ZOOM_FACTOR);
		self.zoomPlayerLayer.frame = CGRectMake((contentLayer.bounds.size.width /2) - (zoomSize.width /2),
											(contentLayer.bounds.size.height /2) - (zoomSize.height /2),
											zoomSize.width,
											zoomSize.height);
					
		[contentLayer addSublayer:self.zoomPlayerLayer];
		[self.loupeView.layer addSublayer:contentLayer];
		
		_haveSetupPlayerLayers = YES;
	}
}

- (IBAction)loadMovieFromCameraRoll:(id)sender
{
    [self.player pause];
    
    /* 
     Show the image picker controller as a popover (iPad) or as a modal view controller
    (iPhone and iPhone 6 plus).
     */
    UIImagePickerController *videoPicker = [[UIImagePickerController alloc] init];
    videoPicker.edgesForExtendedLayout = UIRectEdgeNone;
    videoPicker.modalPresentationStyle = UIModalPresentationPopover;
    videoPicker.delegate = self;
    // Initialize UIImagePickerController to select a movie from the camera roll.
    videoPicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie];
    
    UIPopoverPresentationController *popoverPresController = videoPicker.popoverPresentationController;
    popoverPresController.barButtonItem = sender;
    popoverPresController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popoverPresController.delegate = self;

    [self presentViewController:videoPicker animated:YES completion:^{
        // Done.
    }];
}

#pragma mark Image Picker Controller Delegate 

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSURL *url = info[UIImagePickerControllerReferenceURL];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
	[self.player replaceCurrentItemWithPlayerItem:item];
	
	self.notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:item queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note)
    {
		// Simple item playback rewind.
		[[self.player currentItem] seekToTime:kCMTimeZero];
	}];
	
	[self.player play];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
	
	// Make sure playback is resumed from any interruption.
    [self.player play];
}

# pragma mark - Popover Presentation Controller Delegate

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    
    // Called when a Popover is dismissed.
    
    // Make sure playback is resumed from any interruption.
    [self.player play];
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    // Return YES if the Popover should be dismissed.
    // Return NO if the Popover should not be dismissed.
    return YES;
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *__autoreleasing  _Nonnull *)view
{
    // Called when the Popover changes positon.
}

# pragma mark - Adaptive Presentation Controller Delegate

// Called for the iPhone only.
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationFullScreen;
    
    // Note: by returning this, you can force it to be a popover for iPhone!
    // return UIModalPresentationNone;
}

@end



@implementation UIImagePickerController (LandscapeOrientation)

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
