/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Grid of assets view controller.
*/

@import Photos;

#import "AVMetadataRecordPlayAssetGridViewController.h"

#import "AVMetadataRecordPlayGridViewCell.h"
#import "AVMetadataRecordPlay+NSIndexSet+Convenience.h"
#import "AVMetadataRecordPlay+UICollectionView+Convenience.h"

@interface AVMetadataRecordPlayAssetGridViewController () <PHPhotoLibraryChangeObserver>

@property (nonatomic) BOOL scrolledToBottom;

@property (nonatomic) PHCachingImageManager *imageManager;
@property (nonatomic) CGRect previousPreheatRect;
@property (nonatomic) PHFetchResult<PHAsset *> *assetsFetchResult;
@property (nonatomic) PHImageRequestID assetRequestID;

@property (nonatomic) UIAlertController *loadingAssetAlertController;

@end

@implementation AVMetadataRecordPlayAssetGridViewController

static NSString * const CellReuseIdentifier = @"Cell";
static CGSize AssetGridThumbnailSize;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if ( [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized ) {
		[self setUpPhotoLibrary];
		self.title = [NSString stringWithFormat:@"Videos (%zd)", self.assetsFetchResult.count];
	}
	else {
		[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
			if ( status == PHAuthorizationStatusAuthorized ) {
				dispatch_async( dispatch_get_main_queue(), ^{
					[self setUpPhotoLibrary];
					self.title = [NSString stringWithFormat:@"Videos (%zd)", self.assetsFetchResult.count];
					[self.collectionView reloadData];
				} );
			}
			else {
				dispatch_async( dispatch_get_main_queue(), ^{
					NSString *message = NSLocalizedString( @"AVMetadataRecordPlay doesn't have permission to the photo library, please change privacy settings", @"Alert message when the user has denied access to the photo library" );
					UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVMetadataRecordPlay" message:message preferredStyle:UIAlertControllerStyleAlert];
					[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert OK button") style:UIAlertActionStyleCancel handler:nil]];
					[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", @"Alert button to open Settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
					}]];
					[self presentViewController:alertController animated:YES completion:nil];
				} );
			}
		}];
	}
}

- (void)dealloc
{
	if ( [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized ) {
		[[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	/*
		Update the collection view's layout to change the item size to have a 1 pt border above and below
		the section and between each item.
	*/
	CGFloat screenScale = [UIScreen mainScreen].scale;
	CGFloat spacing = 2.0 / screenScale;
	CGFloat cellWidth = ( MIN( self.view.frame.size.width, self.view.frame.size.height ) - spacing * 3.0 ) / 4.0;
	
	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
	flowLayout.itemSize = CGSizeMake( cellWidth, cellWidth );
	flowLayout.sectionInset = UIEdgeInsetsMake( spacing, 0.0, spacing, 0.0 );
	flowLayout.minimumInteritemSpacing = spacing;
	flowLayout.minimumLineSpacing = spacing;
	
	// Save the thumbnail size in pixels.
	AssetGridThumbnailSize = CGSizeMake( cellWidth * screenScale, cellWidth * screenScale );
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
    [self updateCachedAssets];
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	if ( ! self.scrolledToBottom ) {
		NSUInteger numberOfAssets = self.assetsFetchResult.count;
		if ( numberOfAssets > 0 ) {
			NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:numberOfAssets - 1 inSection:0];
			[self.collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
			self.scrolledToBottom = YES;
		}
	}
}

#pragma mark Photo Library

- (void)setUpPhotoLibrary
{
	self.imageManager = [[PHCachingImageManager alloc] init];
	[self resetCachedAssets];
	
	PHFetchResult<PHAssetCollection *> *videoSmartAlbumsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumVideos options:nil];
	PHAssetCollection *videoSmartAlbum = videoSmartAlbumsFetchResult.firstObject;
	if ( videoSmartAlbum ) {
		self.assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:videoSmartAlbum options:nil];
	}
	
	self.assetRequestID = PHInvalidImageRequestID;
	
	[[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
	/*
		Change notifications may be made on a background queue. Re-dispatch to the
		main queue before acting on the change as we'll be updating the UI.
	*/
    dispatch_async( dispatch_get_main_queue(), ^{
        
        // Check if there are changes to the assets (insertions, deletions, updates)
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assetsFetchResult];
        if ( collectionChanges ) {
            
            // Get the new fetch result.
            self.assetsFetchResult = collectionChanges.fetchResultAfterChanges;
			
			// Update the view controller's title with the number of videos.
			self.title = [NSString stringWithFormat:@"Videos (%zd)", self.assetsFetchResult.count];
			
			if ( ! collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves ) {
				// We need to reload all if the incremental diffs are not available
				[self.collectionView reloadData];
			}
			else {
                // If we have incremental diffs, tell the collection view to animate insertions and deletions
                [self.collectionView performBatchUpdates:^{
                    NSIndexSet *removedIndexes = collectionChanges.removedIndexes;
                    if ( removedIndexes.count > 0 ) {
						NSArray<NSIndexPath *> *indexPathsToDelete = [removedIndexes avMetadataRecordPlay_indexPathsFromIndexesWithSection:0];
                        [self.collectionView deleteItemsAtIndexPaths:indexPathsToDelete];
                    }
					
                    NSIndexSet *insertedIndexes = collectionChanges.insertedIndexes;
                    if ( insertedIndexes.count > 0 ) {
						NSArray<NSIndexPath *> *indexPathsToInsert = [insertedIndexes avMetadataRecordPlay_indexPathsFromIndexesWithSection:0];
                        [self.collectionView insertItemsAtIndexPaths:indexPathsToInsert];
                    }
					
                    NSIndexSet *changedIndexes = collectionChanges.changedIndexes;
                    if ( changedIndexes.count > 0 ) {
						NSArray<NSIndexPath *> *indexPathsToReload = [changedIndexes avMetadataRecordPlay_indexPathsFromIndexesWithSection:0];
                        [self.collectionView reloadItemsAtIndexPaths:indexPathsToReload];
                    }
                } completion:nil];
            }
            
            [self resetCachedAssets];
        }
    } );
}

#pragma mark Asset Management

- (void)resetCachedAssets
{
	[self.imageManager stopCachingImagesForAllAssets];
	self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets
{
	BOOL isViewVisible = self.isViewLoaded && self.view.window != nil;
	if ( ! isViewVisible ) {
		return;
	}
	
	if ( [PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized ) {
		return;
	}
	
	// The preheat window is twice the height of the visible rect
	CGRect visibleRect = CGRectMake( self.collectionView.contentOffset.x, self.collectionView.contentOffset.y, CGRectGetWidth( self.collectionView.bounds ), CGRectGetHeight( self.collectionView.bounds ) );
	CGRect preheatRect = CGRectInset( visibleRect, 0.0f, -0.5f * CGRectGetHeight( visibleRect ) );
	
	// Update only if the visible area is significantly different from the last preheated area.
	CGFloat delta = ABS( CGRectGetMidY( preheatRect ) - CGRectGetMidY( self.previousPreheatRect ) );
	if ( delta > CGRectGetHeight( self.collectionView.bounds ) / 3.0f ) {
		
		// Compute the assets to start caching and to stop caching.
		NSMutableArray<NSIndexPath *> *addedIndexPaths = [NSMutableArray array];
		NSMutableArray<NSIndexPath *> *removedIndexPaths = [NSMutableArray array];
		
		[self differenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
			NSArray<NSIndexPath *> *indexPaths = [self.collectionView avMetadataRecordPlay_indexPathsForElementsInRect:removedRect];
			[removedIndexPaths addObjectsFromArray:indexPaths];
		} addedHandler:^(CGRect addedRect) {
			NSArray<NSIndexPath *> *indexPaths = [self.collectionView avMetadataRecordPlay_indexPathsForElementsInRect:addedRect];
			[addedIndexPaths addObjectsFromArray:indexPaths];
		}];
		
		NSArray<PHAsset *> *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
		NSArray<PHAsset *> *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
		
		// Update the assets the PHCachingImageManager is caching.
		[self.imageManager startCachingImagesForAssets:assetsToStartCaching
											targetSize:AssetGridThumbnailSize
										   contentMode:PHImageContentModeAspectFill
											   options:nil];
		[self.imageManager stopCachingImagesForAssets:assetsToStopCaching
										   targetSize:AssetGridThumbnailSize
										  contentMode:PHImageContentModeAspectFill
											  options:nil];
		
		// Store the preheat rect to compare against in the future.
		self.previousPreheatRect = preheatRect;
	}
}


- (void)differenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler
{
	if ( CGRectIntersectsRect( newRect, oldRect ) ) {
		CGFloat oldMaxY = CGRectGetMaxY( oldRect );
		CGFloat oldMinY = CGRectGetMinY( oldRect );
		CGFloat newMaxY = CGRectGetMaxY( newRect );
		CGFloat newMinY = CGRectGetMinY( newRect );
		
		if ( newMaxY > oldMaxY ) {
			CGRect rectToAdd = CGRectMake( newRect.origin.x, oldMaxY, newRect.size.width, ( newMaxY - oldMaxY ) );
			addedHandler( rectToAdd) ;
		}
		if ( oldMinY > newMinY ) {
			CGRect rectToAdd = CGRectMake( newRect.origin.x, newMinY, newRect.size.width, ( oldMinY - newMinY ) );
			addedHandler( rectToAdd );
		}
		if ( newMaxY < oldMaxY ) {
			CGRect rectToRemove = CGRectMake( newRect.origin.x, newMaxY, newRect.size.width, ( oldMaxY - newMaxY ) );
			removedHandler( rectToRemove );
		}
		if ( oldMinY < newMinY ) {
			CGRect rectToRemove = CGRectMake( newRect.origin.x, oldMinY, newRect.size.width, ( newMinY - oldMinY ) );
			removedHandler( rectToRemove );
		}
	}
	else {
		addedHandler( newRect );
		removedHandler( oldRect );
	}
}

- (NSArray<PHAsset *> *)assetsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
	NSMutableArray<PHAsset *> *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
	for ( NSIndexPath *indexPath in indexPaths ) {
		PHAsset *asset = self.assetsFetchResult[indexPath.item];
		[assets addObject:asset];
	}
	return assets;
}

#pragma mark Collection View

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assetsFetchResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AVMetadataRecordPlayGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    
    PHAsset *asset = self.assetsFetchResult[indexPath.item];
	
	cell.representedAssetIdentifier = asset.localIdentifier;
	
    [self.imageManager requestImageForAsset:asset targetSize:AssetGridThumbnailSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
		dispatch_async( dispatch_get_main_queue(), ^{
			/*
				The cell may have been recycled by the time this handler gets called so we should only
				set the cell's thumbnail image only if it's still showing the same asset.
			*/
			if ( result != nil ) {
				if ( [cell.representedAssetIdentifier isEqualToString:asset.localIdentifier] ) {
					cell.thumbnailImage = result;
				}
			}
		} );
    }];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	PHAsset *asset = self.assetsFetchResult[indexPath.item];
	
	PHVideoRequestOptions *requestOptions = [[PHVideoRequestOptions alloc] init];
	requestOptions.networkAccessAllowed = YES;
	requestOptions.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info) {
		if ( error ) {
			dispatch_async( dispatch_get_main_queue(), ^{
				dispatch_block_t presentError = ^{
					UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"Error Loading Video" message:[NSString stringWithFormat:@"%@", error] preferredStyle:UIAlertControllerStyleAlert];
					[errorAlertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
					[self presentViewController:errorAlertController animated:YES completion:nil];
				};
				
				if ( self.loadingAssetAlertController ) {
					[self.loadingAssetAlertController dismissViewControllerAnimated:YES completion:^{
						self.loadingAssetAlertController = nil;
						presentError();
					}];
				}
				else {
					presentError();
				}
			} );
			
			return;
		}
		
		PHImageRequestID requestID = ( (NSNumber *)info[PHImageResultRequestIDKey] ).intValue;
		
		dispatch_async( dispatch_get_main_queue(), ^{
			if ( self.assetRequestID == requestID ) {
				if ( self.loadingAssetAlertController ) {
					self.loadingAssetAlertController.message = [NSString stringWithFormat:@"Progress: %.0f%%", progress * 100];
				}
				else {
					UIAlertController *loadingAssetAlertController = [UIAlertController alertControllerWithTitle:@"Loading Video" message:@"Progress: 0%" preferredStyle:UIAlertControllerStyleAlert];
					self.loadingAssetAlertController = loadingAssetAlertController;
					[loadingAssetAlertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
						[self.imageManager cancelImageRequest:requestID];
						self.assetRequestID = PHInvalidImageRequestID;
						self.loadingAssetAlertController = nil;
					}]];
					
					[self presentViewController:self.loadingAssetAlertController animated:YES completion:nil];
				}
			}
		} );
	};
	
	self.assetRequestID = [self.imageManager requestAVAssetForVideo:asset options:requestOptions resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
		if ( asset ) {
			dispatch_async( dispatch_get_main_queue(), ^{
				self.selectedAsset = asset;
				[self performSegueWithIdentifier:@"backToPlayer" sender:self];
			} );
		}
	}];
}

#pragma mark Scroll View

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self updateCachedAssets];
}

@end
