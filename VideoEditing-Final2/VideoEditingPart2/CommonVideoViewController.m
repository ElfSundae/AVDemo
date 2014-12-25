//
//  CommonVideoViewController.m
//  VideoEditingPart2
//
//  Created by Abdul Azeem Khan on 1/24/13.
//  Copyright (c) 2013 com.datainvent. All rights reserved.
//

#import "CommonVideoViewController.h"

@interface CommonVideoViewController ()

@end

@implementation CommonVideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)startMediaBrowserFromViewController:(UIViewController*)controller usingDelegate:(id)delegate {
  // 1 - Validations
  if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)
      || (delegate == nil)
      || (controller == nil)) {
    return NO;
  }

  // 2 - Get image picker
  UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
  mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
  mediaUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
  // Hides the controls for moving & scaling pictures, or for
  // trimming movies. To instead show the controls, use YES.
  mediaUI.allowsEditing = YES;
  mediaUI.delegate = delegate;

  // 3 - Display image picker
  [controller presentViewController:mediaUI animated:YES completion:nil];
  return YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  // 1 - Get media type
  NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];

  // 2 - Dismiss image picker
  [self dismissViewControllerAnimated:YES completion:nil];

  // 3 - Handle video selection
  if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
    self.videoAsset = [AVAsset assetWithURL:[info objectForKey:UIImagePickerControllerMediaURL]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asset Loaded" message:@"Video Asset Loaded"
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
  // no-op - override this method in the subclass
}

- (void)videoOutput
{
  // 1 - Early exit if there's no video file selected
  if (!self.videoAsset) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please Load a Video Asset First"
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    return;
  }

  // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
  AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

  // 3 - Video track
  AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                      preferredTrackID:kCMPersistentTrackID_Invalid];
  [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, self.videoAsset.duration)
                      ofTrack:[[self.videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                       atTime:kCMTimeZero error:nil];

  // 3.1 - Create AVMutableVideoCompositionInstruction
  AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
  mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.videoAsset.duration);

  // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
  AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
  AVAssetTrack *videoAssetTrack = [[self.videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
  UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
  BOOL isVideoAssetPortrait_  = NO;
  CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
  if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
    videoAssetOrientation_ = UIImageOrientationRight;
    isVideoAssetPortrait_ = YES;
  }
  if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
    videoAssetOrientation_ =  UIImageOrientationLeft;
    isVideoAssetPortrait_ = YES;
  }
  if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
    videoAssetOrientation_ =  UIImageOrientationUp;
  }
  if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
    videoAssetOrientation_ = UIImageOrientationDown;
  }
  [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
  [videolayerInstruction setOpacity:0.0 atTime:self.videoAsset.duration];

  // 3.3 - Add instructions
  mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];

  AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];

  CGSize naturalSize;
  if(isVideoAssetPortrait_){
    naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
  } else {
    naturalSize = videoAssetTrack.naturalSize;
  }

  float renderWidth, renderHeight;
  renderWidth = naturalSize.width;
  renderHeight = naturalSize.height;
  mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
  mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
  mainCompositionInst.frameDuration = CMTimeMake(1, 30);

  [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
  
  // 4 - Get path
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                           [NSString stringWithFormat:@"FinalVideo-%d.mov",arc4random() % 1000]];
  NSURL *url = [NSURL fileURLWithPath:myPathDocs];

  // 5 - Create exporter
  AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                    presetName:AVAssetExportPresetHighestQuality];
  exporter.outputURL=url;
  exporter.outputFileType = AVFileTypeQuickTimeMovie;
  exporter.shouldOptimizeForNetworkUse = YES;
  exporter.videoComposition = mainCompositionInst;
  [exporter exportAsynchronouslyWithCompletionHandler:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [self exportDidFinish:exporter];
    });
  }];
}

- (void)exportDidFinish:(AVAssetExportSession*)session {
  if (session.status == AVAssetExportSessionStatusCompleted) {
    NSURL *outputURL = session.outputURL;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
      [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
          if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
          } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
          }
        });
      }];
    }
  }
}

@end
