/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	NSIndexSet convenience extensions.
*/

#import "AVMetadataRecordPlay+NSIndexSet+Convenience.h"

@import UIKit;

@implementation NSIndexSet (Convenience)

- (NSArray<NSIndexPath *> *)avMetadataRecordPlay_indexPathsFromIndexesWithSection:(NSUInteger)section
{
	NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
	[self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
	}];
	return indexPaths;
}

@end

