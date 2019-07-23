/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View controller class that manages display of properties related to automatic waiting
*/

import UIKit
import AVFoundation

/// View controller to display the current property values of a given AVPlayer and its current AVPlayerItem
class PlaybackDetailsViewController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak var rateLabel : UILabel!
    @IBOutlet weak var timeControlStatusLabel : UILabel!
    @IBOutlet weak var reasonForWaitingLabel : UILabel!
    @IBOutlet weak var likelyToKeepUpLabel : UILabel!
    @IBOutlet weak var loadedTimeRangesLabel : UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var playbackBufferFullLabel: UILabel!
    @IBOutlet weak var playbackBufferEmptyLabel: UILabel!
    @IBOutlet weak var timebaseRateLabel: UILabel!
    
    var player : AVPlayer?
    
    // AVPlayerItem.currentTime() and the AVPlayerItem.timebase's rate are not KVO observable. We check their values regularly using this timer.
    private let nonObservablePropertiesUpdateTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
    
    // An array of key paths for the properties we want to observe.
    private let observedKeyPaths = [
        #keyPath(PlaybackDetailsViewController.player.rate),
        #keyPath(PlaybackDetailsViewController.player.timeControlStatus),
        #keyPath(PlaybackDetailsViewController.player.reasonForWaitingToPlay),
        #keyPath(PlaybackDetailsViewController.player.currentItem.playbackLikelyToKeepUp),
        #keyPath(PlaybackDetailsViewController.player.currentItem.loadedTimeRanges),
        #keyPath(PlaybackDetailsViewController.player.currentItem.playbackBufferFull),
        #keyPath(PlaybackDetailsViewController.player.currentItem.playbackBufferEmpty)
    ]
    
    private var observerContext = 0
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nonObservablePropertiesUpdateTimer.setEventHandler { [weak self] in
            self?.updateNonObservableProperties()
        }
        nonObservablePropertiesUpdateTimer.scheduleRepeating(deadline: DispatchTime.now(), interval: DispatchTimeInterval.milliseconds(100))
        nonObservablePropertiesUpdateTimer.resume()
        
        // Register observers for the properties we want to display.
        for keyPath in observedKeyPaths {
            addObserver(self, forKeyPath: keyPath, options: [.new, .initial], context: &observerContext)
        }
    }
    
    deinit {
        // Un-register observers
        for keyPath in observedKeyPaths {
            removeObserver(self, forKeyPath: keyPath, context: &observerContext)
        }
    }
    
    // MARK: Helpers
    
    /// Helper function to get a background color for the timeControlStatus label.
    private func labelBackgroundColor(forTimeControlStatus status: AVPlayerTimeControlStatus) -> UIColor {
        switch status {
        case .paused:
            return #colorLiteral(red: 0.8196078538894653, green: 0.2627451121807098, blue: 0.2823528945446014, alpha: 1)
            
        case .playing:
            return #colorLiteral(red: 0.2881325483322144, green: 0.6088829636573792, blue: 0.261575847864151, alpha: 1)
            
        case .waitingToPlayAtSpecifiedRate:
            return #colorLiteral(red: 0.8679746985435486, green: 0.4876297116279602, blue: 0.2578189671039581, alpha: 1)
        }
    }
    
    
    /// Helper function to get an abbreviated description for the waiting reason.
    private func abbreviatedDescription(forReasonForWaitingToPlay reason: String) -> String {
        switch reason {
        case AVPlayerWaitingToMinimizeStallsReason:
            return "Minimizing Stalls"
            
        case AVPlayerWaitingWhileEvaluatingBufferingRateReason:
            return "Evaluating Buffering Rate"
            
        case AVPlayerWaitingWithNoItemToPlayReason:
            return "No Item"
            
        default:
            return "UNKOWN"
        }
    }
    
    // MARK: Property Change Handlers
    
    //Update the UI as AVPlayer properties change.
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(PlaybackDetailsViewController.player.rate) {
            rateLabel.text = player?.rate.description ?? "-"
        }
        else if keyPath == #keyPath(PlaybackDetailsViewController.player.timeControlStatus) {
            timeControlStatusLabel.text = player?.timeControlStatus.description ?? "-"
            timeControlStatusLabel.backgroundColor = (player?.timeControlStatus).map(labelBackgroundColor(forTimeControlStatus:)) ?? #colorLiteral(red: 1, green: 0.9999743700027466, blue: 0.9999912977218628, alpha: 1)
        }
        else if keyPath == #keyPath(PlaybackDetailsViewController.player.reasonForWaitingToPlay) {
            reasonForWaitingLabel.text = player?.reasonForWaitingToPlay.map(abbreviatedDescription(forReasonForWaitingToPlay:)) ?? "-"
        }
        else if keyPath == #keyPath(PlaybackDetailsViewController.player.currentItem.playbackLikelyToKeepUp) {
            likelyToKeepUpLabel.text = player?.currentItem?.isPlaybackLikelyToKeepUp.description ?? "-"
        }
        else if keyPath == #keyPath(PlaybackDetailsViewController.player.currentItem.loadedTimeRanges) {
            loadedTimeRangesLabel.text = player?.currentItem?.loadedTimeRanges.asTimeRanges.description ?? "-"
        }
        else if keyPath == #keyPath(PlaybackDetailsViewController.player.currentItem.playbackBufferFull) {
            playbackBufferFullLabel.text = player?.currentItem?.isPlaybackBufferFull.description ?? "-"
        }
        else if keyPath == #keyPath(PlaybackDetailsViewController.player.currentItem.playbackBufferEmpty) {
            playbackBufferEmptyLabel.text = player?.currentItem?.isPlaybackBufferEmpty.description ?? "-"
        }
    }
    
    private func updateNonObservableProperties() {
        currentTimeLabel.text = player?.currentItem?.currentTime().description ?? "-"
        timebaseRateLabel.text = player?.currentItem?.timebase != nil ? CMTimebaseGetRate(player!.currentItem!.timebase!).description : "-"
    }
    
}

// MARK: - Extensions to improve readability of printed properties

// Add description for AVPlayerTimeControlStatus.
extension AVPlayerTimeControlStatus : CustomStringConvertible{
    public var description: String {
        switch self {
        case .paused:
            return " Paused "
            
        case .playing:
            return " Playing "
            
        case .waitingToPlayAtSpecifiedRate:
            return " Waiting "
        }
    }
}

// Simple description of CMTime, e.g., 2.4s.
extension CMTime : CustomStringConvertible {
    public var description : String {
        return String(format: "%.1fs", self.seconds)
    }
}

// Simple description of CMTimeRange, e.g., [2.4s, 2.8s].
extension CMTimeRange : CustomStringConvertible {
    public var description: String {
        return "[\(self.start), \(self.end)]"
    }
}

// Convert a collection of NSValues into an array of CMTimeRanges.
private extension Collection where Iterator.Element == NSValue {
    var asTimeRanges : [CMTimeRange] {
        return self.map({ value -> CMTimeRange in
            return value.timeRangeValue
        })
    }
}
