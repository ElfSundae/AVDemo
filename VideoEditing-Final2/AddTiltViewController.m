//
//  AddTiltViewController.m
//  VideoEditingPart2
//
//  Created by Abdul Azeem Khan on 3/19/13.
//  Copyright (c) 2013 com.datainvent. All rights reserved.
//

#import "AddTiltViewController.h"

@interface AddTiltViewController ()

@end

@implementation AddTiltViewController

- (IBAction)loadAsset:(id)sender {
    [self startMediaBrowserFromViewController:self usingDelegate:self];
}

- (IBAction)generateOutput:(id)sender {
    [self videoOutput];
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
    // 1 - Layer setup
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
 
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
 
    // 2 - Set up the transform
    CATransform3D identityTransform = CATransform3DIdentity;
 
    // 3 - Pick the direction
    if (_tiltSegment.selectedSegmentIndex == 0) {
        identityTransform.m34 = 1.0 / 1000; // greater the denominator lesser will be the transformation
    } else if (_tiltSegment.selectedSegmentIndex == 1) {
        identityTransform.m34 = 1.0 / -1000; // lesser the denominator lesser will be the transformation
    }
 
    // 4 - Rotate
    videoLayer.transform = CATransform3DRotate(identityTransform, M_PI/6.0, 1.0f, 0.0f, 0.0f);
 
    // 5 - Composition
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}
@end
