/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Grid of assets view controller.
*/

import UIKit
import Photos

class AssetGridViewController: UICollectionViewController, PHPhotoLibraryChangeObserver {
	
	// MARK: View Controller Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if PHPhotoLibrary.authorizationStatus() == .authorized {
			setUpPhotoLibrary()
			updateTitle()
		}
		else {
			PHPhotoLibrary.requestAuthorization { status in
				if status == .authorized {
					DispatchQueue.main.async {
						self.setUpPhotoLibrary()
						self.updateTitle()
						self.collectionView!.reloadData()
					}
				}
				else {
					DispatchQueue.main.async {
						let message = NSLocalizedString("AVMetadataRecordPlay doesn't have permission to the photo library, please change privacy settings", comment: "Alert message when the user has denied access to the photo library")
						let alertController = UIAlertController(title: "AVMetadataRecordPlay", message: message, preferredStyle: .alert)
						alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
						alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .`default`, handler: { _ in
							UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
						}))
						self.present(alertController, animated: true, completion: nil)
					}
				}
			}
		}
	}
	
	deinit {
		if PHPhotoLibrary.authorizationStatus() == .authorized {
			PHPhotoLibrary.shared().unregisterChangeObserver(self)
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		/*
			Update the collection view's layout to change the item size to have a 1 pt border above and below
			the section and between each item.
		*/
		let screenScale = UIScreen.main.scale
		let spacing = 2.0 / screenScale
		let cellWidth = (min(view.frame.width, view.frame.height) - spacing * 3.0) / 4.0
		
		let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
		flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
		flowLayout.sectionInset = UIEdgeInsetsMake(spacing, 0.0, spacing, 0.0)
		flowLayout.minimumInteritemSpacing = spacing
		flowLayout.minimumLineSpacing = spacing
		
		// Save the thumbnail size in pixels.
		assetGridThumbnailSize = CGSize(width: cellWidth * screenScale, height: cellWidth * screenScale)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		updateCachedAssets()
	}
	
	private var isScrolledToBottom = false
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if !isScrolledToBottom {
			let numberOfAssets = assetsFetchResult.count
			if numberOfAssets > 0 {
				let lastIndexPath = IndexPath(item: numberOfAssets - 1, section: 0)
				collectionView?.scrollToItem(at: lastIndexPath, at: .bottom, animated: false)
				isScrolledToBottom = true
			}
		}
	}
	
	// MARK: Photo Library
	
	private var imageManager: PHCachingImageManager!
	
	private func setUpPhotoLibrary() {
		imageManager = PHCachingImageManager()
		resetCachedAssets()
		
		let videoSmartAlbumsFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: nil)
		let videoSmartAlbum = videoSmartAlbumsFetchResult[0]
		assetsFetchResult = PHAsset.fetchAssets(in: videoSmartAlbum, options: nil)
		
		PHPhotoLibrary.shared().register(self)
	}
	
	func photoLibraryDidChange(_ changeInstance: PHChange) {
		/*
			Change notifications may be made on a background queue. Re-dispatch to the
			main queue before acting on the change as we'll be updating the UI.
		*/
		DispatchQueue.main.async {
			
			guard let collectionChanges = changeInstance.changeDetails(for: self.assetsFetchResult) else { return }
			
			// Get the new fetch result.
			self.assetsFetchResult = collectionChanges.fetchResultAfterChanges
			
			// Update the view controller's title with the number of videos.
			self.updateTitle()
			
			if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
				// Reload the collection view if incremental diffs are not available.
				self.collectionView!.reloadData()
			}
			else {
				// If we have incremental diffs, animate the deletions, in the collection view.
				guard let collectionView = self.collectionView else { fatalError() }
				collectionView.performBatchUpdates({
					if let removed = collectionChanges.removedIndexes, removed.count > 0 {
						let indexPathsToDelete = removed.map { IndexPath(item: $0, section:0) }
						collectionView.deleteItems(at: indexPathsToDelete)
					}
					
					if let inserted = collectionChanges.insertedIndexes, inserted.count > 0 {
						let indexPathsToInsert = inserted.map { IndexPath(item: $0, section:0) }
						collectionView.insertItems(at: indexPathsToInsert)
					}
					
					if let changed = collectionChanges.changedIndexes, changed.count > 0 {
						let indexPathsToReload = changed.map { IndexPath(item: $0, section:0) }
						collectionView.reloadItems(at: indexPathsToReload)
					}
				})
			}

			self.resetCachedAssets()
		}
	}

	private func updateTitle() {
		title = "Videos (\(assetsFetchResult.count))"
	}
	
	// MARK: Asset Management
	
	var assetsFetchResult = PHFetchResult<PHAsset>()
	
	private var assetGridThumbnailSize = CGSize.zero
	
	var selectedAsset: AVAsset?
	
	private var assetRequestID = PHInvalidImageRequestID
	
	private var loadingAssetAlertController: UIAlertController? = nil
	
	private var previousPreheatRect: CGRect = CGRect.zero
	
	private func resetCachedAssets() {
		imageManager.stopCachingImagesForAllAssets()
		previousPreheatRect = .zero
	}
	
	private func updateCachedAssets() {
		// Update only if the view is visible.
		guard isViewLoaded && view.window != nil else { return }
		
		guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
		
		// The preheat window is twice the height of the visible rect.
		let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
		let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
		
		// Update only if the visible area is significantly different from the last preheated area.
		let delta = abs(preheatRect.midY - previousPreheatRect.midY)
		guard delta > view.bounds.height / 3.0 else { return }
		
		// Compute the assets to start caching and to stop caching.
		let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
		let addedAssets = addedRects
			.flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
			.map { indexPath in assetsFetchResult.object(at: indexPath.item) }
		let removedAssets = removedRects
			.flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
			.map { indexPath in assetsFetchResult.object(at: indexPath.item) }
		
		// Update the assets the PHCachingImageManager is caching.
		imageManager.startCachingImages(for: addedAssets, targetSize: assetGridThumbnailSize, contentMode: .aspectFill, options: nil)
		imageManager.stopCachingImages(for: removedAssets, targetSize: assetGridThumbnailSize, contentMode: .aspectFill, options: nil)
		
		// Store the preheat rect to compare against in the future.
		previousPreheatRect = preheatRect
	}
	
	private func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
		if old.intersects(new) {
			var added = [CGRect]()
			var removed = [CGRect]()
			
			if new.maxY > old.maxY {
				added += [CGRect(x: new.origin.x, y: old.maxY, width: new.width, height: new.maxY - old.maxY)]
			}
			if old.minY > new.minY {
				added += [CGRect(x: new.origin.x, y: new.minY, width: new.width, height: old.minY - new.minY)]
			}
			
			if new.maxY < old.maxY {
				removed += [CGRect(x: new.origin.x, y: new.maxY, width: new.width, height: old.maxY - new.maxY)]
			}
			if old.minY < new.minY {
				removed += [CGRect(x: new.origin.x, y: old.minY, width: new.width, height: new.minY - old.minY)]
			}
			return (added, removed)
		}
		else {
			return ([new], [old])
		}
	}
	
	// MARK: Collection View
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return assetsFetchResult.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(AssetGridViewCell.self)", for: indexPath) as? AssetGridViewCell
			else { fatalError("unexpected cell in collection view") }
		
		let asset = assetsFetchResult[indexPath.item]
		
		cell.representedAssetIdentifier = asset.localIdentifier
		
		imageManager.requestImage(for: asset, targetSize: assetGridThumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { result, _ in
			DispatchQueue.main.async {
				/*
					The cell may have been recycled by the time this handler gets called so we should only
					set the cell's thumbnail image only if it's still showing the same asset.
				*/
				if let image = result, cell.representedAssetIdentifier == asset.localIdentifier {
					cell.thumbnailImage = image
				}
			}
		})
		
		return cell
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let asset = assetsFetchResult[indexPath.item]
		
		let requestOptions = PHVideoRequestOptions()
		requestOptions.isNetworkAccessAllowed = true
		requestOptions.progressHandler = { progress, error, _, info in
			if let error = error {
				DispatchQueue.main.async {
					func presentError() {
						let errorAlertController = UIAlertController(title: "Error Loading Video", message: "\(error)", preferredStyle: .alert)
						errorAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
						self.present(errorAlertController, animated: true, completion: nil)
					}
					
					if let loadingAssetAlertController = self.loadingAssetAlertController {
						loadingAssetAlertController.dismiss(animated: true, completion: {
							self.loadingAssetAlertController = nil
							presentError()
						})
					}
					else {
						presentError()
					}
				}
				
				return
			}
			
			guard let requestID = info?[PHImageResultRequestIDKey] as? PHImageRequestID else { return }
				
			DispatchQueue.main.async {
				if self.assetRequestID == requestID {
					if let loadingAssetAlertController = self.loadingAssetAlertController {
						loadingAssetAlertController.message = String(format: "Progress: %.0f%%", progress * 100)
					}
					else {
						let loadingAssetAlertController = UIAlertController(title: "Loading Video", message: "Progress: 0%", preferredStyle: .alert)
						self.loadingAssetAlertController = loadingAssetAlertController
						loadingAssetAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
							self.imageManager.cancelImageRequest(requestID)
							self.assetRequestID = PHInvalidImageRequestID
							self.loadingAssetAlertController = nil
						}))
						
						self.present(loadingAssetAlertController, animated: true, completion: nil)
					}
				}
			}
		}
		
		self.assetRequestID = imageManager.requestAVAsset(forVideo: asset, options: requestOptions, resultHandler: { asset, _, info in
			DispatchQueue.main.async {
				if let asset = asset {
					self.selectedAsset = asset
					self.performSegue(withIdentifier: "backToPlayer", sender: self)
				}
			}
		})
	}
	
	// MARK: Scroll View
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		updateCachedAssets()
	}
}

private extension UICollectionView {
	func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
		let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
		return allLayoutAttributes.map { $0.indexPath }
	}
}

