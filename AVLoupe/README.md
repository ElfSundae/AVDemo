### AVLoupe ###

===============================================================
Description:

This sample demonstrates how to use multiple synchronized AVPlayerLayer instances, associated with a single AVPlayer, to efficiently and with minimal code produce non-trivial presentation of timed visual media. The presentation effect achieved in this sample is of an interactive loupe, or magnifying glass, for video. This is similar to features that you might have seen offered for photos in iPhoto and Aperture. This sample was explored in the WWDC 2012 session 517: Real-Time Media Effects and Processing during Playback.

===============================================================
BUILD REQUIREMENTS:

iOS 9.0 SDK or later

===============================================================
RUNTIME REQUIREMENTS:

iOS 8.0 or later

===============================================================
PACKAGING LIST:

AppDelegate.m/.h:
 Standard Application Delegate.
ViewController.m/.h:
 The UIViewController subclass. This contains the view controller logic including 
playback.
ViewController_iPad.xib/_iPhone.xib:
 The viewController NIB. This contains the application's UI for iPad and iPhone 
respectively.
loupe@2x.png
 Application artwork.

===============================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1 - Replaced deprecated UIPopoverController with UIViewController presentation. Updated for iOS 9 SDK. Added Launch Storyboard. Other miscellaneous changes.

Version 1.0 - First Release

===============================================================
Copyright © 2012-2016 Apple Inc. All rights reserved.
