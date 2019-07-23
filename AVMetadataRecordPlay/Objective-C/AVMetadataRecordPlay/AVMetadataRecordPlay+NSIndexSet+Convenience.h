/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	NSIndexSet convenience extensions.
*/
 
@import Foundation;

@interface NSIndexSet (Convenience)

- (NSArray<NSIndexPath *> *)avMetadataRecordPlay_indexPathsFromIndexesWithSection:(NSUInteger)section;

@end
