//
//  Camcorder.h
//  AVCaptureDataAssetWriterExample
//
//  Created by Kwang Sik Moon on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <MobileCoreServices/MobileCoreServices.h>


#define MAX_RECORDING_SECOND 86400 //1day

@protocol CamcorderDelegate;

@interface Camcorder : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate> {
@private
    AVCaptureSession*           captureSession;
    AVCaptureVideoDataOutput*   videoOutput;
    AVCaptureAudioDataOutput*   audioOutput;
	AVCaptureVideoPreviewLayer* prevLayer;
    
    uint        frameRate;
    uint64_t    secondsForFileCut;
    uint        captureWidth;
    uint        captureHeight;
    
    NSDictionary *videoCompressionProps;
    NSDictionary *videoSettings;
    NSDictionary* audioOutputSettings;
    
    AVCaptureConnection* videoConnection;
    AVCaptureConnection* audioConnection;
    
    AVAssetWriter*      currentVideoWriter;
    AVAssetWriter*      currentAudioWriter;
    AVAssetWriterInput* currentVideoWriterInput;
    AVAssetWriterInput* currentAudioWriterInput;
    AVAssetWriter*      standbyVideoWriter;
    AVAssetWriter*      standbyAudioWriter;
    AVAssetWriterInput* standbyVideoWriterInput;
    AVAssetWriterInput* standbyAudioWriterInput;
    AVAssetWriter*      mustReleaseVideoWriter;
    AVAssetWriter*      mustReleaseAudioWriter;
    AVAssetWriterInput* mustReleaseVideoWriterInput;
    AVAssetWriterInput* mustReleaseAudioWriterInput;
    NSTimer*            inspectWriterTimer;
    BOOL                isCurVideoWriterInvalidate;
    BOOL                isCurAudioWriterInvalidate;
    
    CMTime  lastVideoFileWriteSampleTime;
    CMTime  lastAudioFileWriteSampleTime;
    
    AVCaptureVideoOrientation videoOrientation;
    AVCaptureVideoOrientation referenceOrientation;
@public
    BOOL                    isRecording;
    UIView*                 preview;
    id <CamcorderDelegate>  delegate;
}

@property (nonatomic, readonly)         BOOL isRecording;
@property (nonatomic, readonly)         UIView* preview;
@property (nonatomic, assign)           id <CamcorderDelegate> delegate;
@property (readwrite)                   AVCaptureVideoOrientation referenceOrientation; 

- (BOOL)startRecording;
- (BOOL)startRecordingForDropFileWithSeconds:(uint)sec frameRate:(uint)frameRate captureWidth:(uint)width captureHeight:(uint)height;
- (BOOL)stopRecording;

@end

@protocol CamcorderDelegate
@required
- (void)camcorder:(Camcorder*)camcorder recoringDidStartToOutputFileURL:(NSURL*)outputFileURL error:(NSError*)error;
- (void)camcorder:(Camcorder*)camcorder recoringDidFinishToOutputFileURL:(NSURL*)outputFileURL error:(NSError*)error;
@end