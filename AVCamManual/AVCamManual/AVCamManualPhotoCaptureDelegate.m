/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Photo capture delegate.
*/

#import "AVCamManualPhotoCaptureDelegate.h"

@import Photos;

@interface AVCamManualPhotoCaptureDelegate ()

@property (nonatomic, readwrite) AVCapturePhotoSettings *requestedPhotoSettings;
@property (nonatomic) void (^willCapturePhotoAnimation)();
@property (nonatomic) void (^completed)(AVCamManualPhotoCaptureDelegate *photoCaptureDelegate);

@property (nonatomic) NSData *jpegPhotoData;
@property (nonatomic) NSData *dngPhotoData;

@end

@implementation AVCamManualPhotoCaptureDelegate

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings willCapturePhotoAnimation:(void (^)())willCapturePhotoAnimation completed:(void (^)(AVCamManualPhotoCaptureDelegate *))completed
{
	self = [super init];
	if ( self ) {
		self.requestedPhotoSettings = requestedPhotoSettings;
		self.willCapturePhotoAnimation = willCapturePhotoAnimation;
		self.completed = completed;
	}
	return self;
}

- (void)didFinish
{
	self.completed( self );
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
	self.willCapturePhotoAnimation();
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error
{
	if ( error != nil ) {
		NSLog( @"Error capturing photo: %@", error );
		return;
	}
	
	self.jpegPhotoData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingRawPhotoSampleBuffer:(CMSampleBufferRef)rawSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error
{
	if ( error != nil ) {
		NSLog( @"Error capturing RAW photo: %@", error );
		return;
	}
	
	self.dngPhotoData = [AVCapturePhotoOutput DNGPhotoDataRepresentationForRawSampleBuffer:rawSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error
{
	if ( error != nil ) {
		NSLog( @"Error capturing photo: %@", error );
		[self didFinish];
		return;
	}
	
	if ( self.jpegPhotoData == nil && self.dngPhotoData == nil ) {
		NSLog( @"No photo data resource" );
		[self didFinish];
		return;
	}
	
	[PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
		if ( status == PHAuthorizationStatusAuthorized ) {
			
			NSURL *temporaryDNGFileURL;
			if ( self.dngPhotoData ) {
				temporaryDNGFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld.dng", resolvedSettings.uniqueID]]];
				[self.dngPhotoData writeToURL:temporaryDNGFileURL atomically:YES];
			}
			
			[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
				PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
				
				if ( self.jpegPhotoData ) {
					[creationRequest addResourceWithType:PHAssetResourceTypePhoto data:self.jpegPhotoData options:nil];
					
					if ( temporaryDNGFileURL ) {
						PHAssetResourceCreationOptions *companionDNGResourceOptions = [[PHAssetResourceCreationOptions alloc] init];
						companionDNGResourceOptions.shouldMoveFile = YES;
						[creationRequest addResourceWithType:PHAssetResourceTypeAlternatePhoto fileURL:temporaryDNGFileURL options:companionDNGResourceOptions];
					}
				}
				else {
					PHAssetResourceCreationOptions *dngResourceOptions = [[PHAssetResourceCreationOptions alloc] init];
					dngResourceOptions.shouldMoveFile = YES;
					[creationRequest addResourceWithType:PHAssetResourceTypePhoto fileURL:temporaryDNGFileURL options:dngResourceOptions];
				}
				
			} completionHandler:^( BOOL success, NSError * _Nullable error ) {
				if ( ! success ) {
					NSLog( @"Error occurred while saving photo to photo library: %@", error );
				}
				
				if ( [[NSFileManager defaultManager] fileExistsAtPath:temporaryDNGFileURL.path] ) {
					[[NSFileManager defaultManager] removeItemAtURL:temporaryDNGFileURL error:nil];
				}
				
				[self didFinish];
			}];
		}
		else {
			NSLog( @"Not authorized to save photo" );
			[self didFinish];
		}
	}];
}

@end
