/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Custom map view which handles user interaction for seeking in video.
 */

@import Cocoa;
@import MapKit;

NSString *const AAPLMapViewSeekPositionKey;
// Notifications which post user interactions with the map

// Register for AAPLMapViewUserDidUpdateSeekPosition to be notified of a point on map where user right clicked, to seek video to correspond to that location. Use this notification in combination with AAPLMapViewSeekPositionKey to access the location where user clicked.
NSString *const AAPLMapViewUserDidUpdateSeekPositionNotification;

// Register for AAPLMapViewUserDidInteractWithMap to be notified of when a user dragged on map so we can stop centering the map with playback updates.
NSString *const AAPLMapViewUserDidInteractWithMapNotification;

@interface AAPLMapView : MKMapView
@end
