//
//  Camcorder.m
//  AVCaptureDataAssetWriterExample
//
//  Created by Kwang Sik Moon on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Camcorder.h"

@implementation Camcorder

@synthesize isRecording;
@synthesize preview;
@synthesize delegate;
@synthesize referenceOrientation;

//jsfjlsfsfjlsflsdfsd
//1


//2
- (id)init {
    self = [super init];
    
    if (self != nil) {
        referenceOrientation = UIDeviceOrientationLandscapeLeft;
        
        [self initCaptureSession];
    }
    
    return self;
}

- (void)dealloc {
    [self releaseVideoSettings];
    [self releaseAudioSettings];
    [self releaseCurrentVideoWriter];
    [self releaseStandbyVideoWriter];    
    [self releaseCurrentAudioWriter];
    [self releaseStandbyAudioWriter];

    [super dealloc];
}

- (void)initCaptureSession 
{
    NSError *error;
    // Setup the video input
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    // Setup the video output
    videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoOutput.alwaysDiscardsLateVideoFrames = NO;
    videoOutput.videoSettings =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];     
    
    // Setup the audio input
    AVCaptureDevice *audioDevice     = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error ];     
    // Setup the audio output
    audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    // Create the session
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession addInput:videoInput];
    [captureSession addInput:audioInput];
    [captureSession addOutput:videoOutput];
    [captureSession addOutput:audioOutput];
    videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
    
    captureSession.sessionPreset = AVCaptureSessionPreset640x480;

    // Setup the queue
    dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
    [videoOutput setSampleBufferDelegate:self queue:queue];
    [audioOutput setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    videoOrientation = [videoConnection videoOrientation];
    
	/*We start the capture*/
	[captureSession startRunning];
}

- (void)videoSettings 
{
    // Add video input
    float bitsPerPixel = 11.4;  // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
    int bitPerSecond = captureWidth*captureHeight*bitsPerPixel;
    videoCompressionProps = [[NSDictionary alloc] initWithObjectsAndKeys:
                             [NSNumber numberWithDouble:bitPerSecond], AVVideoAverageBitRateKey,
                             [NSNumber numberWithInteger:frameRate], AVVideoMaxKeyFrameIntervalKey, 
                             nil ];
    
//    videoCompressionProps = [[NSDictionary alloc] initWithObjectsAndKeys:
//                             AVVideoProfileLevelH264Main30, AVVideoProfileLevelKey, nil];
    
    videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, 
                     [NSNumber numberWithInt:captureWidth], AVVideoWidthKey, 
                     [NSNumber numberWithInt:captureHeight], AVVideoHeightKey,
                     videoCompressionProps, AVVideoCompressionPropertiesKey,
                     nil];
}

- (void)audioSettings 
{
    // Add the audio input
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    //acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    audioOutputSettings = nil;
    audioOutputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                           [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                           [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                           [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                           nil];
}

- (void)releaseVideoSettings 
{
    if (videoCompressionProps != nil)[videoCompressionProps release];videoCompressionProps = nil;
    if (videoSettings != nil)[videoSettings release];videoSettings = nil;
}

- (void)releaseAudioSettings 
{
    if (audioOutputSettings != nil)[audioOutputSettings release];audioOutputSettings = nil;
}

- (NSURL*) outputVideoURL 
{
    NSURL* URL;
    static int index = 0;
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//	[dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
//    URL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@_%d%@", 
//                                  NSTemporaryDirectory(), 
//                                  [dateFormatter stringFromDate:[NSDate date]],
//                                  index++,
//                                  @".mov"]];
//    [dateFormatter release];
    
    URL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@video_%d%@", 
                                  NSTemporaryDirectory(), 
                                  index++,
                                  @".mov"]];

    return URL;
}

- (NSURL*) outputAudioURL 
{
    NSURL* URL;
    static int index = 0;
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//	[dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
//    URL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@_%d%@", 
//                                  NSTemporaryDirectory(), 
//                                  [dateFormatter stringFromDate:[NSDate date]],
//                                  index++,
//                                  @".m4a"]];
//    [dateFormatter release];
    
    URL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@audio_%d%@", 
                                  NSTemporaryDirectory(), 
                                  index++,
                                  @".mov"]];
    
    return URL;
}

- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
	CGFloat angle = 0.0;
	
	switch (orientation) {
		case AVCaptureVideoOrientationPortrait:
			angle = 0.0;
			break;
		case AVCaptureVideoOrientationPortraitUpsideDown:
			angle = M_PI;
			break;
		case AVCaptureVideoOrientationLandscapeRight:
			angle = -M_PI_2;
			break;
		case AVCaptureVideoOrientationLandscapeLeft:
			angle = M_PI_2;
			break;
		default:
			break;
	}
    
	return angle;
}

- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
	CGAffineTransform transform = CGAffineTransformIdentity;
    
	// Calculate offsets from an arbitrary reference orientation (portrait)
	CGFloat orientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:orientation];
	CGFloat videoOrientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:videoOrientation];
	
	// Find the difference in angle between the passed in orientation and the current video orientation
	CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
	transform = CGAffineTransformMakeRotation(angleOffset);
	
	return transform;
}

- (BOOL) setupCurrentVideoWriter 
{
    NSError *error = nil;
    NSURL* outputVideoURL = [self outputVideoURL];
    
    currentVideoWriter = [[AVAssetWriter alloc] initWithURL:outputVideoURL
                                                   fileType:AVFileTypeMPEG4
                                                      error:&error];
    NSParameterAssert(currentVideoWriter);
    [currentVideoWriter setMovieTimeScale:0];
    [currentVideoWriter setShouldOptimizeForNetworkUse:YES];
    
    currentVideoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo 
                                                             outputSettings:videoSettings];
    NSParameterAssert(currentVideoWriterInput);
    [currentVideoWriterInput setMediaTimeScale:0];
    currentVideoWriterInput.expectsMediaDataInRealTime = YES;
    currentVideoWriterInput.transform = [self transformFromCurrentVideoOrientationToOrientation:referenceOrientation];
    
    // add input
    [currentVideoWriter addInput:currentVideoWriterInput];
    
    return YES;
}

- (BOOL) setupCurrentAudioWriter 
{
    NSError *error = nil;
    NSURL* outputAudioURL = [self outputAudioURL];
    
    currentAudioWriter = [[AVAssetWriter alloc] initWithURL:outputAudioURL
                                                   fileType:AVFileTypeAppleM4A
                                                      error:&error];
    NSParameterAssert(currentAudioWriter);
        
    [currentAudioWriter setShouldOptimizeForNetworkUse:YES];
    
    currentAudioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio 
                                                             outputSettings:audioOutputSettings];
    currentAudioWriterInput.expectsMediaDataInRealTime = YES;
    
    // add input
    [currentAudioWriter addInput:currentAudioWriterInput];
    
    return YES;
}

- (BOOL) setupStandbyVideoWriter 
{
    if (standbyVideoWriter == nil) {
        NSError *error = nil;
        NSURL* outputVideoURL = [self outputVideoURL];
        standbyVideoWriter = [[AVAssetWriter alloc] initWithURL:outputVideoURL
                                                       fileType:AVFileTypeMPEG4
                                                          error:&error];
        NSParameterAssert(standbyVideoWriter);
        [standbyVideoWriter setMovieTimeScale:0];
        [standbyVideoWriter setShouldOptimizeForNetworkUse:YES];
        
        standbyVideoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo 
                                                                 outputSettings:videoSettings];
        NSParameterAssert(standbyVideoWriterInput);
        //[standbyVideoWriterInput setMediaTimeScale:0];
        standbyVideoWriterInput.expectsMediaDataInRealTime = YES;
        standbyVideoWriterInput.transform = [self transformFromCurrentVideoOrientationToOrientation:referenceOrientation];
        
        // add input
        [standbyVideoWriter addInput:standbyVideoWriterInput];
        
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL) setupStandbyAudioWriter 
{
    if (standbyAudioWriter == nil) {
        NSError *error = nil;
        NSURL* outputAudioURL = [self outputAudioURL];
        
        standbyAudioWriter = [[AVAssetWriter alloc] initWithURL:outputAudioURL
                                                       fileType:AVFileTypeAppleM4A
                                                          error:&error];
        
        NSParameterAssert(standbyAudioWriter);
        [standbyAudioWriter setShouldOptimizeForNetworkUse:YES];
        
        standbyAudioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio 
                                                                 outputSettings:audioOutputSettings];
        standbyAudioWriterInput.expectsMediaDataInRealTime = YES;
        
        // add input
        [standbyAudioWriter addInput:standbyAudioWriterInput];
        
        return YES;
    }
    else {
        return NO;
    }
}

- (void)releaseCurrentVideoWriter 
{
    if (currentVideoWriter != nil)[currentVideoWriter release];currentVideoWriter = nil;
    if (currentVideoWriterInput != nil)[currentVideoWriterInput release];currentVideoWriterInput = nil;
}

- (void)releaseCurrentAudioWriter 
{
    if (currentAudioWriter != nil)[currentAudioWriter release];currentAudioWriter = nil;
    if (currentAudioWriterInput != nil)[currentAudioWriterInput release];currentAudioWriterInput = nil;
}

- (void)releaseStandbyVideoWriter 
{    
    if (standbyVideoWriter != nil)[standbyVideoWriter release];standbyVideoWriter = nil;
    if (standbyVideoWriterInput != nil)[standbyVideoWriterInput release];standbyVideoWriterInput = nil;
}

- (void)releaseStandbyAudioWriter 
{
    if (standbyAudioWriter != nil)[standbyAudioWriter release];standbyAudioWriter = nil;
    if (standbyAudioWriterInput != nil)[standbyAudioWriterInput release];standbyAudioWriterInput = nil;
}

- (void)swithchVideoWriter 
{
    isCurVideoWriterInvalidate = YES;
    
    mustReleaseVideoWriter = currentVideoWriter;
    mustReleaseVideoWriterInput = currentVideoWriterInput;
    
    currentVideoWriter = standbyVideoWriter;
    currentVideoWriterInput = standbyVideoWriterInput;
    
    standbyVideoWriter = nil;
    standbyVideoWriterInput = nil;
}

- (void)swithchAudioWriter 
{
    isCurAudioWriterInvalidate = YES;
    
    mustReleaseAudioWriter = currentAudioWriter;
    mustReleaseAudioWriterInput = currentAudioWriterInput;
    
    currentAudioWriter = standbyAudioWriter;
    currentAudioWriterInput = standbyAudioWriterInput;
    
    standbyAudioWriter = nil;
    standbyAudioWriterInput = nil;
}

- (void)inspectWriter 
{
    if (isCurVideoWriterInvalidate) {
        [mustReleaseVideoWriter release];
        [mustReleaseVideoWriterInput release];
        isCurVideoWriterInvalidate = NO;
    }
    
    if (isCurAudioWriterInvalidate) {
        [mustReleaseAudioWriter release];
        [mustReleaseAudioWriterInput release];
        isCurAudioWriterInvalidate = NO;
    }
    
    if (standbyVideoWriter == nil) {
        [self setupStandbyVideoWriter];
    }
    if (standbyAudioWriter == nil) {
        [self setupStandbyAudioWriter];
    }    
}

-(void) newVideoSample:(CMSampleBufferRef)sampleBuffer
{     
    if( isRecording )
    {
        if( currentVideoWriter.status > AVAssetWriterStatusWriting ) {
            NSLog(@"Warning: writer status is %d", currentVideoWriter.status);
            if( currentVideoWriter.status == AVAssetWriterStatusFailed )
                NSLog(@"Error: %@", currentVideoWriter.error);
            return;
        }
        
        if (currentVideoWriterInput.readyForMoreMediaData == YES) {
            if( ![currentVideoWriterInput appendSampleBuffer:sampleBuffer] )
                NSLog(@"Unable to write to video input");
        }
        else {
            NSLog(@"readyForMoreMediaData(video) == NO");
        }
    }
}

-(void) newAudioSample:(CMSampleBufferRef)sampleBuffer
{     
    if( isRecording ) {
        if( currentAudioWriter.status > AVAssetWriterStatusWriting ) {
            NSLog(@"Warning: writer status is %d", currentAudioWriter.status);
            if( currentAudioWriter.status == AVAssetWriterStatusFailed )
                NSLog(@"Error: %@", currentAudioWriter.error);
            return;
        }
        
        if (currentAudioWriterInput.readyForMoreMediaData == YES) {
            if( ![currentAudioWriterInput appendSampleBuffer:sampleBuffer] )
                NSLog(@"Unable to write to audio input");
        }
        else {
            NSLog(@"readyForMoreMediaData(audio) == NO");
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didVideoOutputSampleBuffer:(CMSampleBufferRef)sampleBufferOrg
       fromConnection:(AVCaptureConnection *)connection
{
    if( !CMSampleBufferDataIsReady(sampleBufferOrg) ) {
        NSLog( @"sample buffer is not ready. Skipping sample" );
        return;
    }
    
    CMSampleBufferRef sampleBuffer;
    CMSampleTimingInfo timingInfo;
    CMSampleBufferGetSampleTimingInfo (sampleBufferOrg, 0, &timingInfo );
    
    CMTime pts = timingInfo.presentationTimeStamp;
    timingInfo.duration = CMTimeMake(pts.timescale/30, pts.timescale);
    CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sampleBufferOrg, 1, &timingInfo, &sampleBuffer);

    CMTime videoSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    if ((videoSampleTime.value - lastVideoFileWriteSampleTime.value) < 
        (videoSampleTime.timescale * secondsForFileCut) || 
        lastVideoFileWriteSampleTime.value == 0/*first sample write*/) 
    {
        
        if( currentVideoWriter.status != AVAssetWriterStatusWriting &&
           currentVideoWriter.status != AVAssetWriterStatusFailed) {
            if ( [currentVideoWriter startWriting] ) {
                lastVideoFileWriteSampleTime = videoSampleTime;
                [currentVideoWriter startSessionAtSourceTime:pts];
                [delegate camcorder:self recoringDidStartToOutputFileURL:currentVideoWriter.outputURL error:nil];
            }
        }
        //write sample
        if( currentVideoWriter.status == AVAssetWriterStatusWriting  )
            [self newVideoSample:sampleBuffer];
    }
    else {
        [currentVideoWriter finishWriting];
        [delegate camcorder:self recoringDidFinishToOutputFileURL:currentVideoWriter.outputURL error:nil];
        
        [self swithchVideoWriter];
        
        if( currentVideoWriter.status != AVAssetWriterStatusWriting  &&
           currentVideoWriter.status != AVAssetWriterStatusFailed) {
            if ( [currentVideoWriter startWriting] ) {
                lastVideoFileWriteSampleTime = videoSampleTime;
                [currentVideoWriter startSessionAtSourceTime:pts];
                [delegate camcorder:self recoringDidStartToOutputFileURL:currentVideoWriter.outputURL error:nil];
            }
        }
        
        //write sample
        if( currentVideoWriter.status == AVAssetWriterStatusWriting  )
            [self newVideoSample:sampleBuffer];
    }
    
    CFRelease(sampleBuffer);
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didAudioOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if( !CMSampleBufferDataIsReady(sampleBuffer) ) {
        NSLog( @"sample buffer is not ready. Skipping sample" );
        return;
    }
        
    CMTime audioSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    if ( (audioSampleTime.value - lastAudioFileWriteSampleTime.value) < 
        (audioSampleTime.timescale * secondsForFileCut) ||
        lastAudioFileWriteSampleTime.value == 0/*first sample write*/) {
        
        if( currentAudioWriter.status != AVAssetWriterStatusWriting &&
           currentAudioWriter.status != AVAssetWriterStatusFailed ) {
            if ( [currentAudioWriter startWriting] ) {
                lastAudioFileWriteSampleTime = audioSampleTime;
                [currentAudioWriter startSessionAtSourceTime:audioSampleTime];
                [delegate camcorder:self recoringDidStartToOutputFileURL:currentAudioWriter.outputURL error:nil];
            }
        }
        
        //write sample
        if( currentAudioWriter.status == AVAssetWriterStatusWriting  )
            [self newAudioSample:sampleBuffer];
    }
    else {
        [currentAudioWriter finishWriting];
        [delegate camcorder:self recoringDidFinishToOutputFileURL:currentAudioWriter.outputURL error:nil];
        
        [self swithchAudioWriter];
        
        if( currentAudioWriter.status != AVAssetWriterStatusWriting &&
           currentAudioWriter.status != AVAssetWriterStatusFailed ) {
            if ( [currentAudioWriter startWriting] ) {
                lastAudioFileWriteSampleTime = audioSampleTime;
                [currentAudioWriter startSessionAtSourceTime:audioSampleTime];
                [delegate camcorder:self recoringDidStartToOutputFileURL:currentAudioWriter.outputURL error:nil];
            }
        }
        
        //write sample
        if( currentAudioWriter.status == AVAssetWriterStatusWriting  )
            [self newAudioSample:sampleBuffer];
    }
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if( isRecording == YES ) {
        if (captureOutput == videoOutput) {
            [self captureOutput:captureOutput didVideoOutputSampleBuffer:sampleBuffer fromConnection:connection];
        }
        else if (captureOutput == audioOutput) {
            [self captureOutput:captureOutput didAudioOutputSampleBuffer:sampleBuffer fromConnection:connection];
        }
    }
} 

#pragma mark -
#pragma mark Camcorder interface
- (BOOL)startRecording 
{
    if( isRecording ) {
        return NO;
    }
    else {
        [self startRecordingForDropFileWithSeconds:MAX_RECORDING_SECOND 
                                         frameRate:30 captureWidth:480 captureHeight:320];
        return YES;
    }
}

- (BOOL)startRecordingForDropFileWithSeconds:(uint)sec frameRate:(uint)fRate 
                                captureWidth:(uint)width captureHeight:(uint)height 
{
    if( isRecording ) {
        return NO;
    }
    else {
        secondsForFileCut = sec;
        frameRate = fRate;
        captureWidth = width;
        captureHeight = height;
        
        videoConnection.videoMinFrameDuration = CMTimeMake(1, frameRate);
        videoConnection.videoMaxFrameDuration = CMTimeMake(1, frameRate);
        
        preview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, captureWidth, captureHeight)];
        
        [self videoSettings];
        [self audioSettings];

        [self setupCurrentVideoWriter];
        [self setupStandbyVideoWriter];
        [self setupCurrentAudioWriter];
        [self setupStandbyAudioWriter];

        //set preview
        prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: captureSession];
        prevLayer.frame = preview.layer.bounds;
        prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [preview.layer addSublayer: prevLayer];

        inspectWriterTimer = [[NSTimer scheduledTimerWithTimeInterval:secondsForFileCut/2.0 
                                                             target:self selector:@selector(inspectWriter) 
                                                           userInfo:nil repeats:YES] retain];
        
        isRecording = YES;
        return YES;
    }
}

- (BOOL)stopRecording 
{
    if (!isRecording) {
        return NO;
    }
    else{
        isRecording = NO;
        lastVideoFileWriteSampleTime.value = 0;
        lastAudioFileWriteSampleTime.value = 0;
        
        [inspectWriterTimer invalidate];
        [inspectWriterTimer release];
        
        [currentVideoWriter finishWriting];
        [delegate camcorder:self recoringDidFinishToOutputFileURL:currentVideoWriter.outputURL error:currentVideoWriter.error];

        [currentAudioWriter finishWriting];
        [delegate camcorder:self recoringDidFinishToOutputFileURL:currentAudioWriter.outputURL error:currentVideoWriter.error];
        
        [self releaseCurrentVideoWriter];
        [self releaseStandbyVideoWriter];
        [self releaseCurrentAudioWriter];
        [self releaseStandbyAudioWriter];
        
        return YES;
    }
}

@end
