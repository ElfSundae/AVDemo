/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The player's UIViewController class. 
  This controller manages the main view and a sublayer; the mainPlayerLayer. This controller also manages as a subview a UIImageView nammed loupeView. loupeView hosts a layer hirearchy that manages the zoomPlayerLayer.
  Users interact with the position of loupeView in respose to IBActions from a UIPanGestureRecognizer.
 */

@import UIKit;
@import AVFoundation;

@interface APLViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate>

@end
