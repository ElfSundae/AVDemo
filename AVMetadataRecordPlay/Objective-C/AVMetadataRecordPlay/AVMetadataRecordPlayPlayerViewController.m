/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Player view controller.
*/

@import AVFoundation;
@import CoreMedia;
@import ImageIO;

#import "AVMetadataRecordPlayPlayerViewController.h"
#import "AVMetadataRecordPlayAssetGridViewController.h"

@interface AVMetadataRecordPlayPlayerViewController () <AVPlayerItemMetadataOutputPushDelegate>

// Player
@property (nonatomic, weak) IBOutlet UIView *playerView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *playButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *pauseButton;

@property (nonatomic) AVPlayer *player;
@property (nonatomic) BOOL seekToZeroBeforePlay;
@property (nonatomic) AVAsset *playerAsset;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) CGAffineTransform defaultVideoTransform;

// Timed metadata
@property (nonatomic, weak) IBOutlet UISwitch *honorTimedMetadataTracksSwitch;
@property (nonatomic, weak) IBOutlet UILabel *locationOverlayLabel;

@property (nonatomic) AVPlayerItemMetadataOutput *itemMetadataOutput;
@property (nonatomic) BOOL honorTimedMetadataTracksDuringPlayback;
@property (nonatomic) CALayer *facesLayer;

@end

@implementation AVMetadataRecordPlayPlayerViewController

#pragma mark View Controller Life Cycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.playButton.enabled = NO;
	self.pauseButton.enabled = NO;
	
	self.facesLayer = [CALayer layer];
	self.playerView.layer.backgroundColor = [[UIColor darkGrayColor] CGColor];
	
	dispatch_queue_t metadataQueue = dispatch_queue_create( "com.example.metadataqueue", DISPATCH_QUEUE_SERIAL );
	self.itemMetadataOutput = [[AVPlayerItemMetadataOutput alloc] initWithIdentifiers:nil];
	[self.itemMetadataOutput setDelegate:self queue:metadataQueue];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Pause the player and start from the beginning if the view reappears.
	[self.player pause];
	if ( self.playerAsset ) {
		self.playButton.enabled = YES;
		self.pauseButton.enabled = NO;
		self.seekToZeroBeforePlay = NO;
		[self.player seekToTime:kCMTimeZero];
	}
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	/*
		If device is rotated manually while playing back, and before the next orientation track is received,
		then playerLayer's frame should be changed to match with the playerView bounds.
	*/
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		self.playerLayer.frame = self.playerView.layer.bounds;
	} completion:nil];
}

#pragma mark Segue

- (IBAction)unwindBackToPlayer:(UIStoryboardSegue *)sender
{
	// Pull any data from the view controller which initiated the unwind segue.
	AVMetadataRecordPlayAssetGridViewController *assetGridViewController = sender.sourceViewController;
	if ([assetGridViewController isKindOfClass:[AVMetadataRecordPlayAssetGridViewController class]]) {
		AVAsset *selectedAsset = assetGridViewController.selectedAsset;
		if ( selectedAsset && ( selectedAsset != self.playerAsset ) ) {
			[self setUpPlaybackForAsset:selectedAsset];
			self.playerAsset = selectedAsset;
		}
	}
}

#pragma mark Player

- (void)setUpPlaybackForAsset:(AVAsset *)asset
{
	dispatch_async( dispatch_get_main_queue(), ^{
		if ( self.player.currentItem ) {
			[self.player.currentItem removeOutput:self.itemMetadataOutput];
		}
		[self setUpPlayerForAsset:asset];
		self.playButton.enabled = YES;
		self.pauseButton.enabled = NO;
		[self removeAllSublayersFromLayer:self.facesLayer];
	} );
}

- (void)setUpPlayerForAsset:(AVAsset *)asset
{
	AVMutableComposition *mutableComposition = [AVMutableComposition composition];
	
	// Create a mutableComposition for all the tracks present in the asset.
	AVAssetTrack *sourceVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
	self.defaultVideoTransform = sourceVideoTrack.preferredTransform;
	
	AVAssetTrack *sourceAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
	
	AVMutableCompositionTrack *mutableCompositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	[mutableCompositionVideoTrack insertTimeRange:CMTimeRangeMake( kCMTimeZero, asset.duration ) ofTrack:sourceVideoTrack atTime:kCMTimeZero error:nil];
	AVMutableCompositionTrack *mutableCompositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	[mutableCompositionAudioTrack insertTimeRange:CMTimeRangeMake( kCMTimeZero, asset.duration ) ofTrack:sourceAudioTrack atTime:kCMTimeZero error:nil];
	
	for ( AVAssetTrack *metadataTrack in [asset tracksWithMediaType:AVMediaTypeMetadata] ) {
		if ( [self track:metadataTrack hasMetadataIdentifier:AVMetadataIdentifierQuickTimeMetadataDetectedFace] ||
			 [self track:metadataTrack hasMetadataIdentifier:AVMetadataIdentifierQuickTimeMetadataVideoOrientation] ||
			 [self track:metadataTrack hasMetadataIdentifier:AVMetadataIdentifierQuickTimeMetadataLocationISO6709] ) {
			AVMutableCompositionTrack *mutableCompositionMetadataTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeMetadata preferredTrackID:kCMPersistentTrackID_Invalid];
			
			NSError *error = nil;
			if ( ! [mutableCompositionMetadataTrack insertTimeRange:CMTimeRangeMake( kCMTimeZero, asset.duration ) ofTrack:metadataTrack atTime:kCMTimeZero error:&error] ) {
				NSLog( @"Could not insert time range into metadata mutable composition: %@", error );
			}
		}
	}
	
	// Get an instance of AVPlayerItem for the generated mutableComposition.
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:mutableComposition];
	[playerItem addOutput:self.itemMetadataOutput];
	
	if ( ! self.player ) {
		// Create AVPlayer with the generated instance of playerItem. Also add the facesLayer as subLayer to this playLayer.
		self.player = [AVPlayer playerWithPlayerItem:playerItem];
		self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
		
		self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
		self.playerLayer.backgroundColor = [UIColor darkGrayColor].CGColor;
		[self.playerLayer addSublayer:self.facesLayer];
		[self.playerView.layer addSublayer:self.playerLayer];
		self.facesLayer.frame = self.playerLayer.videoRect;
	}
	else {
		[self.player replaceCurrentItemWithPlayerItem:playerItem];
	}
	
	// Update the player layer to match the video's default transform. Disable animation so the transform applies immediately.
	[CATransaction begin];
	CATransaction.disableActions = YES;
	self.playerLayer.transform = CATransform3DMakeAffineTransform( self.defaultVideoTransform );
	self.playerLayer.frame = self.playerView.layer.bounds;
	[CATransaction commit];
	
	// When the player item has played to its end time we'll toggle the movie controller Pause button to be the Play button
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(playerItemDidReachEnd:)
												 name:AVPlayerItemDidPlayToEndTimeNotification
											   object:self.player.currentItem];
	
	self.seekToZeroBeforePlay = NO;
}

// Called when the player item has played to its end time.
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
	// After the movie has played to its end time, seek back to time zero to play it again.
	self.seekToZeroBeforePlay = YES;
	self.playButton.enabled = YES;
	self.pauseButton.enabled = NO;
	[self removeAllSublayersFromLayer:self.facesLayer];
}

- (IBAction)playButtonTapped:(id)sender
{
	if ( self.seekToZeroBeforePlay ) {
		self.seekToZeroBeforePlay = NO;
		[self.player seekToTime:kCMTimeZero];
		
		// Update the player layer to match the video's default transform.
		self.playerLayer.transform = CATransform3DMakeAffineTransform( self.defaultVideoTransform );
		self.playerLayer.frame = self.playerView.layer.bounds;
	}
	[self.player play];
	self.playButton.enabled = NO;
	self.pauseButton.enabled = YES;
}

- (IBAction)pauseButtonTapped:(id)sender
{
	[self.player pause];
	self.playButton.enabled = YES;
	self.pauseButton.enabled = NO;
}

#pragma mark Timed Metadata

- (IBAction)toggleHonorTimedMetadataTracksDuringPlayback:(id)sender
{
	if ( self.honorTimedMetadataTracksSwitch.on ) {
		self.honorTimedMetadataTracksDuringPlayback = YES;
	}
	else {
		self.honorTimedMetadataTracksDuringPlayback = NO;
		[self removeAllSublayersFromLayer:self.facesLayer];
		self.locationOverlayLabel.text = @"";
	}
}

- (void)metadataOutput:(AVPlayerItemMetadataOutput *)output didOutputTimedMetadataGroups:(NSArray *)groups fromPlayerItemTrack:(AVPlayerItemTrack *)track
{
	for ( AVTimedMetadataGroup *metadataGroup in groups ) {
		dispatch_async( dispatch_get_main_queue(), ^{
			
			// Sometimes the face/location track wouldn't contain any items because of scene change, we should remove previously drawn faceRects/locationOverlay in that case.
			if ( metadataGroup.items.count == 0 ) {
				if ( [self track:track.assetTrack hasMetadataIdentifier:AVMetadataIdentifierQuickTimeMetadataDetectedFace] ) {
					[self removeAllSublayersFromLayer:self.facesLayer];
				}
				else if ( [self track:track.assetTrack hasMetadataIdentifier:AVMetadataIdentifierQuickTimeMetadataLocationISO6709] ) {
					self.locationOverlayLabel.text = @"";
				}
			}
			else {
				if ( self.honorTimedMetadataTracksDuringPlayback ) {
					
					NSMutableArray *faceObjects = [NSMutableArray array];
					
					for ( AVMetadataItem *item in metadataGroup.items ) {
						// Detected face AVMetadataItems have their value property return AVMetadataFaceObjects
						if ( [item.identifier isEqualToString:AVMetadataIdentifierQuickTimeMetadataDetectedFace] ) {
							[faceObjects addObject:item.value];
						}
						else if ( [item.identifier isEqualToString:AVMetadataIdentifierQuickTimeMetadataVideoOrientation] &&
								  [item.dataType isEqualToString:(NSString *)kCMMetadataBaseDataType_SInt16] ) {
							AVAssetTrack *sourceVideoTrack = [self.playerAsset tracksWithMediaType:AVMediaTypeVideo][0];
							CMVideoDimensions videoDimensions = CMVideoFormatDescriptionGetDimensions( (CMVideoFormatDescriptionRef)sourceVideoTrack.formatDescriptions[0] );
							CGImagePropertyOrientation videoOrientation = ( (NSNumber *)item.value ).unsignedIntValue;
							CGAffineTransform orientationTransform = [self affineTransformFromVideoOrientation:videoOrientation forVideoDimensions:videoDimensions];
							CATransform3D rotationTransform = CATransform3DMakeAffineTransform(orientationTransform);
							
							// Remove face boxes before applying trasform and then re-draw them as we get new face coordinates.
							[self removeAllSublayersFromLayer:self.facesLayer];
							self.playerLayer.transform = rotationTransform;
							self.playerLayer.frame = self.playerView.layer.bounds;
						}
						else if ( [item.identifier isEqual:AVMetadataIdentifierQuickTimeMetadataLocationISO6709] &&
								  [item.dataType isEqualToString:(__bridge id)kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709] ) {
							self.locationOverlayLabel.text = (NSString *)item.value;
						}
						else {
							NSLog( @"Timed metadata: unrecognized metadata identifier: %@", item.identifier );
						}
					}
					if ( faceObjects.count > 0 ) {
						[self drawFaceMetadataRects:faceObjects];
					}
				}
			}
		} );
	}
}

- (BOOL)track:(AVAssetTrack *)track hasMetadataIdentifier:(NSString *)metadataIdentifer
{
	CMFormatDescriptionRef formatDescription = (__bridge CMFormatDescriptionRef)track.formatDescriptions.firstObject;
	if ( formatDescription ) {
		NSArray *metadataIdentifiers = (__bridge NSArray *)CMMetadataFormatDescriptionGetIdentifiers( formatDescription );
		if ( [metadataIdentifiers containsObject:metadataIdentifer] ) {
			return YES;
		}
	}
	return NO;
}

- (void)drawFaceMetadataRects:(NSArray *)faces
{
	dispatch_async( dispatch_get_main_queue(), ^{
		
		CGRect viewRect = self.playerLayer.videoRect;
		self.facesLayer.frame = viewRect;
		self.facesLayer.masksToBounds = YES;
		[self removeAllSublayersFromLayer:self.facesLayer];
		
		for ( AVMetadataObject *face in faces ) {
			
			CALayer *faceBox = [CALayer layer];
			CGRect faceRect = face.bounds;
			CGPoint viewFaceOrigin = CGPointMake( faceRect.origin.x * viewRect.size.width, faceRect.origin.y * viewRect.size.height );
			CGSize viewFaceSize = CGSizeMake( faceRect.size.width * viewRect.size.width, faceRect.size.height * viewRect.size.height );
			CGRect viewFaceBounds = CGRectMake( viewFaceOrigin.x, viewFaceOrigin.y, viewFaceSize.width, viewFaceSize.height );
			
			[CATransaction begin];
			CATransaction.disableActions = YES;
			[self.facesLayer addSublayer:faceBox];
			faceBox.masksToBounds = YES;
			faceBox.borderWidth = 2.0f;
			faceBox.borderColor = [UIColor colorWithRed:0.3f green:0.6f blue:0.9f alpha:0.7f].CGColor;
			faceBox.cornerRadius = 5.0f;
			faceBox.frame = viewFaceBounds;
			[CATransaction commit];
			
			[AVMetadataRecordPlayPlayerViewController updateAnimationForLayer:self.facesLayer removeAnimation:YES];
		}
	} );
}

#pragma mark Animation Utilities

+ (void)updateAnimationForLayer:(CALayer *)layer removeAnimation:(BOOL)remove
{
	if ( remove ) {
		[layer removeAnimationForKey:@"animateOpacity"];
	}
	
	if ( ! [layer animationForKey:@"animateOpacity"] ) {
		layer.hidden = NO;
		CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		opacityAnimation.duration = .3f;
		opacityAnimation.repeatCount = 1.f;
		opacityAnimation.autoreverses = YES;
		opacityAnimation.fromValue = @1.f;
		[opacityAnimation setToValue:@.0f];
		[layer addAnimation:opacityAnimation forKey:@"animateOpacity"];
	}
}

- (void)removeAllSublayersFromLayer:(CALayer *)layer
{
	[CATransaction begin];
	CATransaction.disableActions = YES;
	
	if ( layer ) {
		NSArray *sublayers = [layer.sublayers copy];
		for( CALayer *layer in sublayers ) {
			[layer removeFromSuperlayer];
		}
	}
	
	[CATransaction commit];
}

- (CGAffineTransform)affineTransformFromVideoOrientation:(CGImagePropertyOrientation)videoOrientation forVideoDimensions:(CMVideoDimensions)videoDimensions
{
	CGAffineTransform transform = CGAffineTransformIdentity;
	
	// Determine rotation and mirroring from tag value.
	int32_t rotationDegrees = 0;
	BOOL mirror = NO;
	
	switch ( videoOrientation )
	{
		case kCGImagePropertyOrientationUp:				rotationDegrees = 0;	mirror = NO;	break;
		case kCGImagePropertyOrientationUpMirrored:		rotationDegrees = 0;	mirror = YES;	break;
		case kCGImagePropertyOrientationDown:			rotationDegrees = 180;	mirror = NO;	break;
		case kCGImagePropertyOrientationDownMirrored:	rotationDegrees = 180;	mirror = YES;	break;
		case kCGImagePropertyOrientationLeft:			rotationDegrees = 270;	mirror = NO;	break;
		case kCGImagePropertyOrientationLeftMirrored:	rotationDegrees = 90;	mirror = YES;	break;
		case kCGImagePropertyOrientationRight:			rotationDegrees = 90;	mirror = NO;	break;
		case kCGImagePropertyOrientationRightMirrored:	rotationDegrees = 270;	mirror = YES;	break;
		
		default: return transform;
	}
	
	// Build the affine transform
	CGFloat angle = 0.0; // in radians
	CGFloat tx = 0.0;
	CGFloat ty = 0.0;
	
	switch ( rotationDegrees ) {
		case 90:
			angle = (CGFloat)( M_PI / 2.0 );
			tx = videoDimensions.height;
			ty = 0.0;
			break;
			
		case 180:
			angle = (CGFloat)M_PI;
			tx = videoDimensions.width;
			ty = videoDimensions.height;
			break;
			
		case 270:
			angle = (CGFloat)( M_PI / -2.0 );
			tx = 0.0;
			ty = videoDimensions.width;
			break;
			
		default:
			break;
	}
	
	// Rotate first, then translate to bring 0,0 to top left.
	if ( angle == 0.0 ) {	// and in this case, tx and ty will be 0.0
		transform = CGAffineTransformIdentity;
	}
	else {
		transform = CGAffineTransformMakeRotation( angle );
		transform = CGAffineTransformConcat( transform, CGAffineTransformMakeTranslation( tx, ty ) );
	}
	
	// If mirroring, flip along the proper axis.
	if ( mirror ) {
		transform = CGAffineTransformConcat( transform, CGAffineTransformMakeScale( -1.0, 1.0 ) );
		transform = CGAffineTransformConcat( transform, CGAffineTransformMakeTranslation( videoDimensions.height, 0.0 ) );
	}
	
	return transform;
}

@end
