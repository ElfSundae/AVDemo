/*
Copyright (C) 2016 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Abstract: A UIView subclass that contains an AVPlayerLayer.
*/

@import UIKit;

@class AVPlayerLayer;

@interface MyPlayerLayerView : UIView {

}

@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

- (void)setVideoFillMode:(NSString *)fillMode;

@end
