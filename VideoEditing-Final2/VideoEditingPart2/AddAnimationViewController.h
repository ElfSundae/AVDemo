//
//  AddAnimationViewController.h
//  VideoEditingPart2
//
//  Created by Abdul Azeem Khan on 1/24/13.
//  Copyright (c) 2013 com.datainvent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonVideoViewController.h"

@interface AddAnimationViewController : CommonVideoViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *animationSelectSegment;

- (IBAction)loadAsset:(id)sender;
- (IBAction)generateOutput:(id)sender;

@end
