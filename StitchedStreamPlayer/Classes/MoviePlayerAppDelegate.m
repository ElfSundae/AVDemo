/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A simple UIApplication delegate class that adds the StreamingViewController
view to the window as a subview.
*/

#import "MoviePlayerAppDelegate.h"

@class MyStreamingMovieViewController;

@implementation MoviePlayerAppDelegate

@synthesize window;
@synthesize streamingViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{	
    // Specify the streaming view controller as the root view controller of the window
    window.rootViewController = streamingViewController;

    [window makeKeyAndVisible];
}

- (void)dealloc 
{
    [window release];
	[streamingViewController release];
	
    [super dealloc];
}

@end
