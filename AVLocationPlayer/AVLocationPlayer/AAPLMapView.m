/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Custom map view which handles user interaction for seeking in video.
 */

#import "AAPLMapView.h"

NSString *const AAPLMapViewSeekPositionKey = @"AAPLMapViewSeekPositionKey";
NSString *const AAPLMapViewUserDidUpdateSeekPositionNotification = @"AAPLMapViewUserDidUpdateSeekPositionNotification";
NSString *const AAPLMapViewUserDidInteractWithMapNotification = @"AAPLMapViewUserDidInteractWithMapNotification";

@implementation AAPLMapView

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];

	CLLocationCoordinate2D locCoord = [self convertPoint:localPoint toCoordinateFromView:self];
	CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:locCoord.latitude longitude:locCoord.longitude];
	
	NSNotification *notification = [NSNotification notificationWithName:AAPLMapViewUserDidUpdateSeekPositionNotification
																 object:self
															   userInfo:@{AAPLMapViewSeekPositionKey : newLocation}];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSNotification *notification = [NSNotification notificationWithName:AAPLMapViewUserDidInteractWithMapNotification
																 object:self
															   userInfo:nil];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
	
	[super mouseDragged:theEvent];
}

@end
