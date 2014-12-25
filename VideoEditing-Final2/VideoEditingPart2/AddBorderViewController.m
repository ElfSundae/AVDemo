//
//  AddBorderViewController.m
//  VideoEditingPart2
//
//  Created by Abdul Azeem Khan on 1/24/13.
//  Copyright (c) 2013 com.datainvent. All rights reserved.
//

#import "AddBorderViewController.h"

@interface AddBorderViewController ()

@end

@implementation AddBorderViewController

- (IBAction)loadAsset:(id)sender {
    [self startMediaBrowserFromViewController:self usingDelegate:self];
}

- (IBAction)generateOutput:(id)sender {
  [self videoOutput];
}

- (UIImage *)imageWithColor:(UIColor *)color rectSize:(CGRect)imageSize {
    CGRect rect = imageSize;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
 
    return image;
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
    UIImage *borderImage = nil;
 
    if (_colorSegment.selectedSegmentIndex == 0) {
        borderImage = [self imageWithColor:[UIColor blueColor] rectSize:CGRectMake(0, 0, size.width, size.height)];
    } else if(_colorSegment.selectedSegmentIndex == 1) {
        borderImage = [self imageWithColor:[UIColor redColor] rectSize:CGRectMake(0, 0, size.width, size.height)];
    } else if(_colorSegment.selectedSegmentIndex == 2) {
        borderImage = [self imageWithColor:[UIColor greenColor] rectSize:CGRectMake(0, 0, size.width, size.height)];
    } else if(_colorSegment.selectedSegmentIndex == 3) {
        borderImage = [self imageWithColor:[UIColor whiteColor] rectSize:CGRectMake(0, 0, size.width, size.height)];
    }
    
    CALayer *backgroundLayer = [CALayer layer];
    [backgroundLayer setContents:(id)[borderImage CGImage]];
    backgroundLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [backgroundLayer setMasksToBounds:YES];
    
    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(_widthBar.value, _widthBar.value,
                                size.width-(_widthBar.value*2), size.height-(_widthBar.value*2));
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:backgroundLayer];
    [parentLayer addSublayer:videoLayer];
    
     composition.animationTool = [AVVideoCompositionCoreAnimationTool
                               videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

@end
