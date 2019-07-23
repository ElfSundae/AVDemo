/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Thumbnail image collection view cell.
*/

#import "AVMetadataRecordPlayGridViewCell.h"

@interface AVMetadataRecordPlayGridViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation AVMetadataRecordPlayGridViewCell

- (UIImage *)thumbnailImage
{
	return self.imageView.image;
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage
{
    self.imageView.image = thumbnailImage;
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	
	self.imageView.image = nil;
}

@end
