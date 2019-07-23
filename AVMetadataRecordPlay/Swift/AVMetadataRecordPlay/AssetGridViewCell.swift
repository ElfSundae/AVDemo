/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Thumbnail image collection view cell.
*/

import UIKit

class AssetGridViewCell: UICollectionViewCell {
	
	@IBOutlet private var imageView: UIImageView!
	
	var representedAssetIdentifier: String?
	
	var thumbnailImage: UIImage? {
		get {
			return imageView.image
		}
		set {
			imageView.image = newValue
		}
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		imageView.image = nil
	}
}
