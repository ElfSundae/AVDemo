/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A simple UIApplication delegate class that adds the StreamingViewController
view to the window as a subview.
*/

@import UIKit;
#import "MyStreamingMovieViewController.h"

@interface MoviePlayerAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
	UIWindow *window;
    MyStreamingMovieViewController *streamingViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MyStreamingMovieViewController *streamingViewController;

@end

