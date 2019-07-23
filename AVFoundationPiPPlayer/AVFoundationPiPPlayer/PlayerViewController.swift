/*
	Copyright (C) 2018 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	PlayerViewController is a subclass of UIViewController which manages the UIView used for playback and also
	            sets up AVPictureInPictureController for video playback in picture in picture.
*/

import AVFoundation
import UIKit
import AVKit

/*
	KVO context used to differentiate KVO callbacks for this class versus other
	classes in its class hierarchy.
*/
private var playerViewControllerKVOContext = 0

/*
    Manages the view used for playback and sets up the `AVPictureInPictureController`
    for video playback in picture in picture.
*/
class PlayerViewController: UIViewController, AVPictureInPictureControllerDelegate {
	// MARK: - Properties

    /// The `NSKeyValueObservation` for the KVO on \AVPlayerItem.status.
    private var playerItemStatusObserver: NSKeyValueObservation?

    /// The `NSKeyValueObservation` for the KVO on \AVPlayerItem.duration.
    private var playerItemDurationObserver: NSKeyValueObservation?

    /// The `NSKeyValueObservation` for the KVO on \AVPlayer.rate.
    private var playerRateObserver: NSKeyValueObservation?

    /*
        The `NSKeyValueObservation` for the KVO on
        \PlayerViewController.pictureInPictureController.pictureInPicturePossible.
    */
    private var pictureInPicturePossibleObserver: NSKeyValueObservation?

    @objc lazy var player = AVPlayer()
	
    @objc var pictureInPictureController: AVPictureInPictureController!
	
	var playerView: PlayerView {
		return self.view as! PlayerView
	}
	
	var playerLayer: AVPlayerLayer? {
		return playerView.playerLayer
	}

    /// The AVPlayerItem associated with AssetPlaybackManager.asset.urlAsset
    private var playerItem: AVPlayerItem? = nil {
        willSet {
            /// Remove any previous KVO observer.
            guard let playerItemStatusObserver = playerItemStatusObserver else { return }

            playerItemStatusObserver.invalidate()
        }

        didSet {
            /*
                If needed, configure player item here before associating it with a player
                (example: adding outputs, setting text style rules, selecting media options)
            */
            player.replaceCurrentItem(with: playerItem)

            if playerItem == nil {
                cleanUpPlayerPeriodicTimeObserver()
            } else {
                setupPlayerPeriodicTimeObserver()
            }

            // Use KVO to get notified of changes in the AVPlayerItem duration property.
            playerItemDurationObserver =
                playerItem?.observe(\AVPlayerItem.duration, options: [.new, .initial]) { [weak self] (item, _) in
                guard let strongSelf = self else { return }

                // Update `timeSlider` and enable/disable controls when `duration` > 0.0

                let newDuration = item.duration
                let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
                let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0

                strongSelf.timeSlider.maximumValue = Float(newDurationSeconds)

                let currentTime = CMTimeGetSeconds(strongSelf.player.currentTime())
                strongSelf.timeSlider.value = hasValidDuration ? Float(currentTime) : 0.0

                strongSelf.playPauseButton.isEnabled = hasValidDuration
                strongSelf.timeSlider.isEnabled = hasValidDuration
                }

            // Use KVO to get notified of changes in the AVPlayerItem status property.
            playerItemStatusObserver = playerItem?.observe(\AVPlayerItem.status, options: [.new, .initial]) { [weak self] (item, _) in
                guard let strongSelf = self else { return }

                // Display an error if status becomes Failed

                if item.status == .failed {
                    strongSelf.handle(error: strongSelf.player.currentItem?.error as NSError?)
                } else if item.status == .readyToPlay {

                    if let asset = strongSelf.player.currentItem?.asset {

                        /*
                         First test whether the values of `assetKeysRequiredToPlay` we need
                         have been successfully loaded.
                         */
                        for key in PlayerViewController.assetKeysRequiredToPlay {
                            var error: NSError?
                            if asset.statusOfValue(forKey: key, error: &error) == .failed {
                                strongSelf.handle(error: error)
                                return
                            }
                        }

                        if !asset.isPlayable || asset.hasProtectedContent {
                            // We can't play this asset.
                            strongSelf.handle(error: nil)
                            return
                        }

                        /*
                         The player item is ready to play,
                         setup picture in picture.
                         */
                        if strongSelf.pictureInPictureController == nil {
                            strongSelf.setupPictureInPicturePlayback()
                        }
                    }
                }
            }
        }
    }

	var timeObserverToken: AnyObject?
	
	// Attempt to load and test these asset keys before playing
	static let assetKeysRequiredToPlay = [
		"playable",
		"hasProtectedContent"
	]
	
	var currentTime: Double {
		get {
			return CMTimeGetSeconds(player.currentTime())
		}
		
		set {
			let newTime = CMTimeMakeWithSeconds(newValue, 1)
			player.seek(to: newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
		}
	}
	
	var duration: Double {
		guard let currentItem = player.currentItem else { return 0.0 }
		return CMTimeGetSeconds(currentItem.duration)
	}

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        playerRateObserver = player.observe(\AVPlayer.rate, options: [.new]) { [weak self] (player, _) in
            guard let strongSelf = self else { return }
            // Update playPauseButton type.
            let newRate = player.rate

            let style: UIBarButtonSystemItem = newRate == 0.0 ? .play : .pause
            let newPlayPauseButton = UIBarButtonItem(barButtonSystemItem: style, target: self,
                                                     action: #selector(PlayerViewController.playPauseButtonWasPressed(_:)))

            // Replace the current button with the updated button in the toolbar.
            var items = strongSelf.toolbar.items!

            if let playPauseItemIndex = items.index(of: strongSelf.playPauseButton) {
                items[playPauseItemIndex] = newPlayPauseButton

                strongSelf.playPauseButton = newPlayPauseButton

                strongSelf.toolbar.setItems(items, animated: false)
            }
        }
    }

    deinit {
        /// Remove any KVO observer.
        playerRateObserver?.invalidate()
    }

	// MARK: - IBOutlets
	
	@IBOutlet weak var timeSlider: UISlider!
	@IBOutlet weak var playPauseButton: UIBarButtonItem!
	@IBOutlet weak var pictureInPictureButton: UIBarButtonItem!
	@IBOutlet weak var toolbar: UIToolbar!
	
	// MARK: - IBActions
	
	@IBAction func playPauseButtonWasPressed(_ sender: UIButton) {
		if player.rate != 1.0 {
			// Not playing foward, so play.
			if currentTime == duration {
				// At end, so got back to beginning.
				currentTime = 0.0
			}
			
			player.play()
		} else {
			// Playing, so pause.
			player.pause()
		}
	}
	
	@IBAction func togglePictureInPictureMode(_ sender: UIButton) {
		/*
			Toggle picture in picture mode.
		
			If active, stop picture in picture and return to inline playback.
		
			If not active, initiate picture in picture.
		
			Both these calls will trigger delegate callbacks which should be used
			to set up UI appropriate to the state of the application.
		*/
		if pictureInPictureController.isPictureInPictureActive {
			pictureInPictureController.stopPictureInPicture()
		} else {
			pictureInPictureController.startPictureInPicture()
		}
	}
	
	@IBAction func timeSliderDidChange(_ sender: UISlider) {
		currentTime = Double(sender.value)
	}
	
	// MARK: - View Handling
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		playerView.playerLayer.player = player
		
		setupPlayback()
		
		timeSlider.translatesAutoresizingMaskIntoConstraints = true
		timeSlider.autoresizingMask = .flexibleWidth
		
		// Set the UIImage provided by AVPictureInPictureController as the image of the pictureInPictureButton
        guard let backingButton = pictureInPictureButton.customView as? UIButton else {
            return
        }
        backingButton.setImage(AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil), for: UIControlState.normal)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		player.pause()
		
		cleanUpPlayerPeriodicTimeObserver()
		
		removeObserver(self, forKeyPath: #keyPath(PlayerViewController.player.currentItem.duration), context: &playerViewControllerKVOContext)
		removeObserver(self, forKeyPath: #keyPath(PlayerViewController.player.rate), context: &playerViewControllerKVOContext)
		removeObserver(self, forKeyPath: #keyPath(PlayerViewController.player.currentItem.status), context: &playerViewControllerKVOContext)
	}
	
	private func setupPlayback() {
		
		let movieURL = Bundle.main.url(forResource: "samplemovie", withExtension: "mov")!
		let asset = AVURLAsset(url: movieURL, options: nil)
		/*
			Create a new `AVPlayerItem` and make it our player's current item.
		
			Using `AVAsset` now runs the risk of blocking the current thread (the
			main UI thread) whilst I/O happens to populate the properties. It's prudent
			to defer our work until the properties we need have been loaded.
		
			These properties can be passed in at initialization to `AVPlayerItem`,
			which are then loaded automatically by `AVPlayer`.
		*/
		self.playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: PlayerViewController.assetKeysRequiredToPlay)
	}
	
	private func setupPlayerPeriodicTimeObserver() {
		// Only add the time observer if one hasn't been created yet.
		guard timeObserverToken == nil else { return }
		
		let time = CMTimeMake(1, 30)
		
		// Use a weak self variable to avoid a retain cycle in the block.
		timeObserverToken =
            player.addPeriodicTimeObserver(forInterval: time, queue:DispatchQueue.main) { [weak self] time in
			self?.timeSlider.value = Float(CMTimeGetSeconds(time))
            } as AnyObject?
	}
	
	private func cleanUpPlayerPeriodicTimeObserver() {
		if let timeObserverToken = timeObserverToken {
			player.removeTimeObserver(timeObserverToken)
			self.timeObserverToken = nil
		}
	}
	
	private func setupPictureInPicturePlayback() {
		/*
			Check to make sure Picture in Picture is supported for the current
			setup (application configuration, hardware, etc.).
		*/
		if AVPictureInPictureController.isPictureInPictureSupported() {
			/*
				Create `AVPictureInPictureController` with our `playerLayer`.
				Set self as delegate to receive callbacks for picture in picture events.
				Add observer to be notified when pictureInPicturePossible changes value,
				so that we can enable `pictureInPictureButton`.
			*/
			pictureInPictureController = AVPictureInPictureController(playerLayer: playerView.playerLayer)
			pictureInPictureController.delegate = self

            // Use KVO to get notified of changes in the pictureInPicturePossible value.
            pictureInPicturePossibleObserver = self.observe(\PlayerViewController.pictureInPictureController.pictureInPicturePossible,
                                                        options: [.new]) { [weak self] (playerViewController, _) in

            guard let strongSelf = self else { return }

            /*
             Enable the `pictureInPictureButton` only if `pictureInPicturePossible`
             is true. If this returns false, it might mean that the application
             was not configured as shown in the AppDelegate.
             */
            strongSelf.pictureInPictureButton.isEnabled =
                playerViewController.pictureInPictureController.isPictureInPicturePossible
            }

		} else {
			pictureInPictureButton.isEnabled = false
		}
	}
	
	// MARK: - AVPictureInPictureControllerDelegate
	
	func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		/*
			If your application contains a video library or other interesting views,
			this delegate callback can be used to dismiss player view controller
			and to present the user with a selection of videos to play next.
		*/
		toolbar.isHidden = true
	}
	
	func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		/*
			Picture in picture mode will stop soon, show the toolbar.
		*/
		toolbar.isHidden = false
	}
	
	func pictureInPictureControllerFailedToStartPictureInPicture(pictureInPictureController: AVPictureInPictureController, withError error: NSError) {
		/*
			Picture in picture failed to start with an error, restore UI to continue
			inline playback. Show the toolbar.
		*/
		toolbar.isHidden = false
		handle(error: error)
	}
	
	// MARK: - KVO

	// Trigger KVO for anyone observing our properties affected by player and player.currentItem
	override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
		let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration": [#keyPath(PlayerViewController.player.currentItem.duration)],
			"rate": [#keyPath(PlayerViewController.player.rate)]
        ]
		
		return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
	}
	
	// MARK: - Error Handling
	
	func handle(error: NSError?) {
		let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
		
		let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
		
		alertController.addAction(alertAction)
		
		present(alertController, animated: true, completion: nil)
	}
}

