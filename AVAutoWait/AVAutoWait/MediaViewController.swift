/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View controller that displays a single selected media item.
*/

import UIKit
import AVFoundation

/// View controller that combines both a `PlaybackViewController` and a `PlaybackDetailsViewController`.
class MediaViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet var stackView: UIStackView!
    
    private var playbackViewController: PlaybackViewController!
    private var playbackDetailsViewController: PlaybackDetailsViewController!
    private let player = AVPlayer()
    
    var mediaURL: URL? {
        didSet {
            // Create a new item for our AVPlayer
            updatePlayerItem()
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sure our AVPlayer has an AVPlayerItem if we already got a URL
        updatePlayerItem()
        
        // Setup sub-view controllers.
        // 1) A PlaybackViewController for the video and playback controls.
        playbackViewController = storyboard?.instantiateViewController(withIdentifier: "Playback") as! PlaybackViewController
        playbackViewController.player = player
        
        // 2) A PlaybackDetailsViewController for property values.
        playbackDetailsViewController = storyboard?.instantiateViewController(withIdentifier: "PlaybackDetails") as! PlaybackDetailsViewController
        playbackDetailsViewController.player = player
        
        // Add both new views to our stackView.
        stackView.addArrangedSubview(playbackViewController.view)
        stackView.addArrangedSubview(playbackDetailsViewController.view)
    }
    
    // MARK: Convenience
    
    private func updatePlayerItem() {
        if let mediaURL = mediaURL {
            player.replaceCurrentItem(with: AVPlayerItem(url: mediaURL))
        }
        else {
            player.replaceCurrentItem(with: nil)
        }
    }
    
}

