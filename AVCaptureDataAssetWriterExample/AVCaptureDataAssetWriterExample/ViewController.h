//
//  ViewController.h
//  AVCaptureDataAssetWriterExample
//
//  Created by Kwang Sik Moon on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Camcorder.h"

@interface ViewController : UIViewController <CamcorderDelegate>{
    Camcorder* cam;
    IBOutlet UIView* preview;
    IBOutlet UITextView* fileView;
}

@end
