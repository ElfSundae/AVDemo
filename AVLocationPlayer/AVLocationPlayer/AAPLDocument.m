/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Application's main document which handles user interaction.
 */

@import AVFoundation;
@import AVKit;
@import CoreMedia;
@import MapKit;

#import "AAPLDocument.h"
#import "AAPLMapView.h"

@interface AAPLDocument () <AVPlayerItemMetadataOutputPushDelegate, MKMapViewDelegate>
{
	// Reader variables
	AVAssetReader							*_reader;
	AVAssetReaderTrackOutput				*_readerMetadataOutput;
	AVAssetReaderOutputMetadataAdaptor		*_metadataAdaptor;
	dispatch_queue_t						_readerQueue;
	
	// Output variable
	AVPlayerItemMetadataOutput				*_metadataOutput;
	
	// Location variables
	NSMutableArray							*_locationPoints;
	NSMutableArray							*_timeStamps;
	MKPointAnnotation						*_currentPin;
	BOOL									_shouldCenterMapView;
}

@property (weak) IBOutlet AVPlayerView		*playerView;
@property (weak) IBOutlet AAPLMapView		*mapView;

@end

@implementation AAPLDocument

- (instancetype)init
{
    self = [super init];
	
    if (self)
	{
		// Initialize reader queue to perform all reading related operations on a background queue
		_readerQueue = dispatch_queue_create("com.example.apple-samplecode.reader.queue", DISPATCH_QUEUE_SERIAL);
		
		// Initialize metadata output with location identifier to get delegate callbacks with location metadata groups
		dispatch_queue_t metadataQueue = dispatch_queue_create("com.example.apple-samplecode.metadata.queue", DISPATCH_QUEUE_SERIAL);
		_metadataOutput = [[AVPlayerItemMetadataOutput alloc] initWithIdentifiers:@[AVMetadataIdentifierQuickTimeMetadataLocationISO6709]];
		[_metadataOutput setDelegate:self queue:metadataQueue];
		
		_locationPoints = [NSMutableArray array];
		_timeStamps = [NSMutableArray array];
		_shouldCenterMapView = YES;
		
		// Listen for user interaction notifications from the map view
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(userDidSeekToNewPosition:)
													 name:AAPLMapViewUserDidUpdateSeekPositionNotification
												   object:self.mapView];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(userDidInteractWithMapView:)
													 name:AAPLMapViewUserDidInteractWithMapNotification
												   object:self.mapView];
    }
	
    return self;
}

- (void)dealloc
{
	// Remove observers listening for interactions from the map view
	[[NSNotificationCenter defaultCenter] removeObserver:self
											 name:AAPLMapViewUserDidUpdateSeekPositionNotification
												  object:self.mapView];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
												 name:AAPLMapViewUserDidInteractWithMapNotification
											   object:self.mapView];
}

- (NSString *)windowNibName
{
	return @"AAPLDocument";
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	
	AVURLAsset *asset = [AVURLAsset assetWithURL:self.fileURL];
	
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
	// Add metadata output to player item to get delegate callbacks during playback
	[playerItem addOutput:_metadataOutput];
	
	self.playerView.player = [AVPlayer playerWithPlayerItem:playerItem];
	self.mapView.delegate = self;
	
	[self readMetadataFromAsset:asset completionHandler:^(BOOL metadataAvailable) {
		// Draw path on map only if we have location metadata
		if (metadataAvailable)
			[self drawPathOnMap];
		else
			NSLog(@"The input movie %@ does not contain location metadata", asset.URL);
	}];
}

#pragma mark - Asset reading

- (void)readMetadataFromAsset:(AVAsset *)asset completionHandler:(void (^)(BOOL))completionHandler
{
	[asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
		// Dispatch all the reading work to a background queue, so we do not block the main thread
		dispatch_async(_readerQueue, ^{
			BOOL success = YES;
			NSError *error;
			
			success = ([asset statusOfValueForKey:@"tracks" error:&error] == AVKeyValueStatusLoaded);
			
			// Set up the AVAssetReader reading samples or flag an error
			if (success)
				success = [self setUpReaderForAsset:asset error:&error];
			// Start reading in the location metadata from asset reader output, which we can later draw on a map
			if (success)
				success = [self startReadingLocationMetadataReturningError:&error];
			
			// Call completion handler with the appropriate BOOL indicating presence or absence of metadata
			BOOL metadataAvailable = NO;
			if (success)
			{
				metadataAvailable = (_locationPoints.count > 0);
			}
			else
			{
				[_reader cancelReading];
			}
			
			// The completion handler involves changes to the map view, which should be performed on the main thread
			dispatch_async(dispatch_get_main_queue(), ^ {
				completionHandler(metadataAvailable);
			});
		});
	}];
}

- (BOOL)setUpReaderForAsset:(AVAsset *)asset error:(NSError **)outError
{
	BOOL success = YES;
	NSError *error;
	
	// Create asset reader
	_reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
	success = (_reader != nil);
	
	// Check to see if a metadata track which contains location information is present
	AVAssetTrack *locationTrack;
	if (success)
	{
		// Go through the metadata tracks in the asset to find the track with location metadata
		NSArray *metadataTracks = [asset tracksWithMediaType:AVMediaTypeMetadata];
		for (AVAssetTrack *track in metadataTracks)
		{
			for (id formatDescription in track.formatDescriptions)
			{
				// Check if the format description for the track contains location identifier
				NSArray *identifiers = (__bridge NSArray *)(CMMetadataFormatDescriptionGetIdentifiers((__bridge CMMetadataFormatDescriptionRef)formatDescription));
				
				if ([identifiers containsObject:AVMetadataIdentifierQuickTimeMetadataLocationISO6709])
				{
					locationTrack = track;
					break;
				}
			}
		}
	}
	
	success = (locationTrack != nil);
	
	// Create an asset reader output and metadata adaptor only if we have a track containing location metadata
	if (success)
	{
		_readerMetadataOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:locationTrack outputSettings:nil];
		_metadataAdaptor = [AVAssetReaderOutputMetadataAdaptor assetReaderOutputMetadataAdaptorWithAssetReaderTrackOutput:_readerMetadataOutput];
		[_reader addOutput:_readerMetadataOutput];
	}
	
	if (!success && outError)
		*outError = error;
	
	return success;
}

- (BOOL)startReadingLocationMetadataReturningError:(NSError **)outError
{
	BOOL success = YES;
	NSError *error;
	
	// Instruct the asset reader to get ready to do work
	success = [_reader startReading];
	
	if (success)
	{
		// Read in all the timed metadata groups from the track and save it in an array to use for drawing on the map later
		// The corresponding time stamps for the location data are stored in another array
		AVTimedMetadataGroup *group;
		while ((group = [_metadataAdaptor nextTimedMetadataGroup]))
		{
			CLLocation *location = [self locationFromMetadataGroup:group];
            if (location)
			{
                [_locationPoints addObject:location];
                [_timeStamps addObject:[NSValue valueWithCMTimeRange:group.timeRange]];
            }
		}
	}
	else
	{
		error = [_reader error];
	}
	
	if (!success && outError)
		*outError = error;
	
	return success;
}

#pragma mark - Utilities

- (void)drawPathOnMap
{
	NSUInteger numberOfPoints = _locationPoints.count;
	CLLocationCoordinate2D pointsToUse[numberOfPoints];
	
	// Extract all the coordinates to draw from the locationPoints array
	for (int i = 0; i < numberOfPoints; i++)
	{
		CLLocation *location = _locationPoints[i];
		pointsToUse[i] = location.coordinate;
	}
	
	// Draw the extracted path as an overlay on the map view
	MKPolyline *polyline = [MKPolyline polylineWithCoordinates:pointsToUse count:numberOfPoints];
	[self.mapView addOverlay:polyline level:MKOverlayLevelAboveRoads];
	
	// Set initial coordinate to the starting coordinate of the path
	self.mapView.centerCoordinate = ((CLLocation *)_locationPoints.firstObject).coordinate;
	
	// Set initial region to some region around the starting coordinate
	self.mapView.region = MKCoordinateRegionMakeWithDistance(self.mapView.centerCoordinate, 800, 800);
	_currentPin = [[MKPointAnnotation alloc] init];
	_currentPin.coordinate = self.mapView.centerCoordinate;
	[self.mapView addAnnotation:_currentPin];
}

- (CLLocation *)locationFromMetadataGroup:(AVTimedMetadataGroup *)group
{
	CLLocation *location;
	
	// Go through the timed metadata group to extract location value
	for (AVMetadataItem *item in group.items)
	{
		// Check to see if the item's data type matches quick time metadata location data type
		if ([item.dataType isEqualToString:(NSString *)kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709])
		{
			NSString *locationDescription = item.stringValue;
			
			if (locationDescription)
			{
				// Extract from a string in iso6709 notation
				NSString *latitude = [locationDescription substringToIndex:8];
				NSString *longitude = [locationDescription substringWithRange:NSMakeRange(8, 9)];
				location = [[CLLocation alloc] initWithLatitude:latitude.doubleValue longitude:longitude.doubleValue];
			}
			break;
		}
	}
	
	return location;
}

- (void)updateCurrentLocation:(CLLocation *)location
{
	// Update current pin to the new location
	dispatch_async(dispatch_get_main_queue(), ^{
		[_currentPin setCoordinate:location.coordinate];
		
		if (_shouldCenterMapView)
			[self.mapView setCenterCoordinate:_currentPin.coordinate animated:YES];
		
		[self.mapView addAnnotation:_currentPin];
	});
}

#pragma mark - AVPlayerItemMetadataOutputPushDelegate

- (void)metadataOutput:(AVPlayerItemMetadataOutput *)output didOutputTimedMetadataGroups:(NSArray *)groups fromPlayerItemTrack:(AVPlayerItemTrack *)track
{
	// Go through the list of timed metadata groups and update location
	for (AVTimedMetadataGroup *group in groups)
	{
		CLLocation *newLocation = [self locationFromMetadataGroup:group];
		
		if (newLocation)
			[self updateCurrentLocation:newLocation];
	}
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *pin = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"currentPin"];
	
    if (!pin)
	{
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"currentPin"];
    }
	else
	{
        pin.annotation = annotation;
    }
	
    return pin;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
	MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
	polylineRenderer.strokeColor = [NSColor colorWithCalibratedRed:0.1 green:0.5 blue:0.98 alpha:0.8];
	polylineRenderer.lineWidth = 5.0;
	
	return polylineRenderer;
}

#pragma mark - Notification callbacks

- (void)userDidSeekToNewPosition:(NSNotification *)notification
{
	CLLocation *newLocation = [[notification userInfo] objectForKey:AAPLMapViewSeekPositionKey];
	CLLocation *updatedLocation;
	CLLocationDistance closestDistance = DBL_MAX;
	
	// Find the closest location on the path to which we can seek
	for (CLLocation *location in _locationPoints)
	{
		CLLocationDistance distance = [newLocation distanceFromLocation:location];
		if (distance < closestDistance)
		{
			updatedLocation = location;
			closestDistance = distance;
		}
	}
	
	if (updatedLocation)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			// Seek to timestamp of the updated location.
			CMTimeRange updatedTimeRange = [_timeStamps[[_locationPoints indexOfObject:updatedLocation]] CMTimeRangeValue];
			[self.playerView.player seekToTime:updatedTimeRange.start completionHandler:^(BOOL finished) {
				// Start centering the map at the current location
				_shouldCenterMapView = YES;
				
				// Move the pin to updated location.
				if (finished)
					[self updateCurrentLocation:updatedLocation];
			}];
		});
	}
}

- (void)userDidInteractWithMapView:(NSNotification *)notification
{
	// Stop centering the map since the user started dragging the map around.
	// We do not center the map until the user seeks to some location
	_shouldCenterMapView = NO;
}

@end
