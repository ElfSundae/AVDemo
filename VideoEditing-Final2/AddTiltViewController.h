//
//  AddTiltViewController.h
//  VideoEditingPart2
//
//  Created by Abdul Azeem Khan on 3/19/13.
//  Copyright (c) 2013 com.datainvent. All rights reserved.
//

#import "CommonVideoViewController.h"

@interface AddTiltViewController : CommonVideoViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *tiltSegment;

- (IBAction)loadAsset:(id)sender;
- (IBAction)generateOutput:(id)sender;

@end
