/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Main view controller where user interaction begins. Allows the user to select a media item from a table view.
*/
import UIKit

/// Table view controller that manages our available media items. All user action starts here.
class MediaSelectionTableViewController: UITableViewController {
    // MARK: Types
    
    private struct MediaItem {
        let name: String
        let url: URL
    }
    
    // MARK: Properties
    private let mediaItems = [
        MediaItem(name: "In the Woods",
                  url: URL(string: "http://devimages.apple.com.edgekey.net/samplecode/avfoundationMedia/AVFoundationQueuePlayer_Progressive.mov")!),
        
        // Add your own media items here.
    ]
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Media", for: indexPath)
        cell.textLabel?.text = mediaItems[indexPath.row].name
        
        return cell
    }
    
    // MARK: UIViewController
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowMedia", let mediaVC = segue.destination as? MediaViewController, let itemIndex = tableView.indexPathForSelectedRow?.row {
            
            // Set the selected URL on the destionation view controller.
            mediaVC.mediaURL = self.mediaItems[itemIndex].url
        }
    }
}
