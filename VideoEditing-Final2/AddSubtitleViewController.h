//
//  AddSubtitleViewController.h
//  VideoEditingPart2
//
//  Created by Abdul Azeem Khan on 3/19/13.
//  Copyright (c) 2013 com.datainvent. All rights reserved.
//

#import "CommonVideoViewController.h"

@interface AddSubtitleViewController : CommonVideoViewController


@property (weak, nonatomic) IBOutlet UITextField *subTitle1;
- (IBAction)loadAsset:(id)sender;
- (IBAction)generateOutput:(id)sender;

@end
