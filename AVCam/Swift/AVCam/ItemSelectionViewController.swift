/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that presents the SSM selection interface.
*/

import UIKit
import AVFoundation

protocol ItemSelectionViewControllerDelegate: class {
    func itemSelectionViewController(_ itemSelectionViewController: ItemSelectionViewController,
                                     didFinishSelectingItems selectedItems: [AVSemanticSegmentationMatte.MatteType])
}

class ItemSelectionViewController: UITableViewController {
    
    weak var delegate: ItemSelectionViewControllerDelegate?
    
    let identifier: String
    
    let allItems: [AVSemanticSegmentationMatte.MatteType]
    
    var selectedItems: [AVSemanticSegmentationMatte.MatteType]
    
    let allowsMultipleSelection: Bool
    
    private let itemCellIdentifier = "Item"
    
    init(delegate: ItemSelectionViewControllerDelegate,
         identifier: String,
         allItems: [AVSemanticSegmentationMatte.MatteType],
         selectedItems: [AVSemanticSegmentationMatte.MatteType],
         allowsMultipleSelection: Bool) {
        
        self.delegate = delegate
        self.identifier = identifier
        self.allItems = allItems
        self.selectedItems = selectedItems
        self.allowsMultipleSelection = allowsMultipleSelection
        
        super.init(style: .grouped)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: itemCellIdentifier)
        
        view.tintColor = .black
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("`ItemSelectionViewController` cannot be initialized with `init(coder:)`")
    }
    
    @IBAction private func done() {
        // Notify the delegate that selecting items is finished.
        delegate?.itemSelectionViewController(self, didFinishSelectingItems: selectedItems)
        
        // Dismiss the view controller.
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ssmType = allItems[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: itemCellIdentifier, for: indexPath)
        
        // Evaluate the semantic segmentation type to determine the label.
        switch ssmType {
        case .hair:
            cell.textLabel?.text = "Hair"
        case .teeth:
            cell.textLabel?.text = "Teeth"
        case .skin:
            cell.textLabel?.text = "Skin"
        default:
            fatalError("Unknown matte type specified.")
        }
        
        cell.accessoryType = selectedItems.contains(ssmType) ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if allowsMultipleSelection {
            let item = allItems[indexPath.row]
            
            if selectedItems.contains(item) {
                selectedItems = selectedItems.filter { $0 != item }
            } else {
                selectedItems.append(item)
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
}
