//
//  ViewController.m
//  AVCaptureDataAssetWriterExample
//
//  Created by Kwang Sik Moon on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    cam = [[Camcorder alloc] init];
    [cam setDelegate:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(IBAction) startRecording
{
    [self deleteTempDirFile];
    [cam startRecordingForDropFileWithSeconds:3 frameRate:30 captureWidth:640 captureHeight:480];
    [preview addSubview:cam.preview];
}

-(IBAction) stopRecording
{
    [cam stopRecording];
}

- (IBAction)deleteTempDirFile
{
    NSError* err = nil;
    NSArray* filesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:&err];
    for(NSString* str in filesArray) {
        NSString* path = [NSString stringWithFormat:@"%@%@",  NSTemporaryDirectory(), str];
        if (![[NSFileManager defaultManager] removeItemAtPath:path error:&err]) {
            NSLog(@"Error deleting existing file");
        }
    }
}

- (IBAction)displayTempDirFile 
{
    NSString* strFile = [NSString stringWithString:@"FILE\n"];
    NSError* err = nil;
    NSArray* filesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:&err];
    for(NSString* str in filesArray) {
        strFile = [strFile stringByAppendingFormat:@"%@,\n", str];
        NSLog(@"%@", str);
    }
    [fileView setText:strFile];
}

#pragma mark -
#pragma mark Camcorder Delegate
- (void)camcorder:(Camcorder*)camcorder recoringDidStartToOutputFileURL:(NSURL*)outputFileURL error:(NSError*)error {
    //NSLog(@"recording started to output file : URL: %@", outputFileURL);
}

- (void)camcorder:(Camcorder*)camcorder recoringDidFinishToOutputFileURL:(NSURL*)outputFileURL error:(NSError*)error {
    //NSLog(@"recording finished URL: %@", outputFileURL);
    
    //To do ...
}

@end
