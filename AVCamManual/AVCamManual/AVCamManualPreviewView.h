/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Camera preview.
*/

@import UIKit;

@class AVCaptureSession;

@interface AVCamManualPreviewView : UIView

@property (nonatomic) AVCaptureSession *session;

@end
