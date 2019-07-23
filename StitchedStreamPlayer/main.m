/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Entry point for the application. Creates the application object and
causes the event loop to start.
*/

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, nil);
	[pool release];
	return retVal;
}
