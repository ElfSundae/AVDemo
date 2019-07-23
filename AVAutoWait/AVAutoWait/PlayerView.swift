/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Simple UIView subclass containing an AVPlayerLayer
*/

import UIKit
import AVFoundation

/// A very simple view only containing an AVPlayerLayer.
class PlayerView: UIView {
    
    static override var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var player : AVPlayer? {
        set {
            let playerLayer = layer as! AVPlayerLayer
            playerLayer.player = newValue
        }
        
        get {
            let playerLayer = layer as! AVPlayerLayer
            return playerLayer.player
        }
    }
}
