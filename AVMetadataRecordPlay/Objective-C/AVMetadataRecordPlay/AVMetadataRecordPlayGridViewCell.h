/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Thumbnail image collection view cell.
*/

@import UIKit;

@interface AVMetadataRecordPlayGridViewCell : UICollectionViewCell

@property (nonatomic, copy) NSString *representedAssetIdentifier;
@property (nonatomic) UIImage *thumbnailImage;

@end
