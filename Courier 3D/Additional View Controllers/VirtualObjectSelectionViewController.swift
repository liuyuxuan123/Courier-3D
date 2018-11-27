/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Popover view controller for choosing virtual objects to place in the AR scene.
*/

import UIKit

// MARK: - ObjectCell
// Table view cell -> Load info from JSON file
class ObjectCell: UITableViewCell {
    
    // UITableViewCell's identifier
    static let reuseIdentifier = "ObjectCell"
    // objectTitleLable.text = displayName
    @IBOutlet weak var objectTitleLabel: UILabel!
    // objectImageView.image = UIImage(named: modelName)
    @IBOutlet weak var objectImageView: UIImageView!
        
    var object: VirtualObjectDefinition? {
        // When object seted -> set its objectTitileLabel and objectImageView automatically
        didSet {
            objectTitleLabel.text = object?.displayName
            objectImageView.image = object?.thumbnailImage
        }
    }
}

// MARK: - VirtualObjectSelectionViewControllerDelegate

protocol VirtualObjectSelectionViewControllerDelegate: class {
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObjectAt index: Int)
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didDeselectObjectAt index: Int)
}

class VirtualObjectSelectionViewController: UITableViewController {
    // A collection of unique integer values that represent the indexes of selected elements
    private var selectedVirtualObjectRows = IndexSet()
    weak var delegate: VirtualObjectSelectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .light))
    }
    
    override func viewWillLayoutSubviews() {
        preferredContentSize = CGSize(width: 250, height: tableView.contentSize.height)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Check if the current row is already selected, then deselect it.
        // Because this is just a popover view so make a delegate and let the main view controller handle the selected situation
        if selectedVirtualObjectRows.contains(indexPath.row) {
            delegate?.virtualObjectSelectionViewController(self, didDeselectObjectAt: indexPath.row)
        } else {
            delegate?.virtualObjectSelectionViewController(self, didSelectObjectAt: indexPath.row)
        }
        // dismiss the popover table view
        self.dismiss(animated: true, completion: nil)
    }
        
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of row in section
        return VirtualObjectManager.availableObjects.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // number of section
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ObjectCell.reuseIdentifier, for: indexPath) as? ObjectCell else {
            fatalError("Expected `ObjectCell` type for reuseIdentifier \(ObjectCell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        
        cell.object = VirtualObjectManager.availableObjects[indexPath.row]

        if selectedVirtualObjectRows.contains(indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    // When Press TableViewCell
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
    }
    
    // When Unpress TableViewCell
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.clear
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            VirtualObjectManager.removeAvailableObject(at: indexPath.row)
        default:
            print("Nothing")
        }
    }

}
