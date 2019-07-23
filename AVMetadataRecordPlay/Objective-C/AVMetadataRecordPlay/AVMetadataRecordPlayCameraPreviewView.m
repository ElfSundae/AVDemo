/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Camera preview view.
*/

@import AVFoundation;

#import "AVMetadataRecordPlayCameraPreviewView.h"

@implementation AVMetadataRecordPlayCameraPreviewView

+ (Class)layerClass
{
	return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer
{
	return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session
{
	return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
	self.videoPreviewLayer.session = session;
}

@end
