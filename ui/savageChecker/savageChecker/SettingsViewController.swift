//
//  SettingsViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 2/26/19.
//  Copyright © 2019 Sam Hooper. All rights reserved.
//

import UIKit
import os.log

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, checkBoxCellProtocol {

    
    // MARK: properties
    var navigationBar: CustomNavigationBar!
    var addButton = UIButton()
    var editButton = UIButton()
    var childViewLabel = UILabel()
    var mainTableView: UITableView!
    var dropdownTableView: UITableView!
    var dropdownOptions = [String]()
    var dropdownTableVisible = false
    var currentMainIndexPath: IndexPath! //if childView is already open, indicates to just reload data
    var childView = UIView()
    var mainView = UIView()
    var childViewWidthConstraint = NSLayoutConstraint()
    var mainViewWidthConstraint = NSLayoutConstraint()
    var childTableHeightConstraint = NSLayoutConstraint()
    let dividingLine = UIView(frame: CGRect(x:0, y: 0, width: 1, height: 1))
    let childViewButtonSpacing: CGFloat = 20
    var backgroundImage: UIImage!
    
    var currentSettings = ["Date alert on": sendDateEntryAlert,
                           "Show quote":    showQuoteAtStartup,
                           "Show help tips": showHelpTips]
    
    // MARK: tableview properties
    var sectionOrder = ["General", "Dropdown options"]
    
    struct SettingsTableViewRow {
        let label: String
        let type: String
        let context: String
    }
    
    var settings = ["General": [SettingsTableViewRow(label: "Date alert on",    type: "checkBox", context: ""),
                                SettingsTableViewRow(label: "Show quote",       type: "checkBox", context: ""),
                                SettingsTableViewRow(label: "Show help tips",   type: "checkBox", context: "")
                               ],
                    "Dropdown options":  [SettingsTableViewRow(label: "Observer name",  type: "list", context: "global"),
                                          SettingsTableViewRow(label: "Destination",    type: "list", context: "global"),
                                          SettingsTableViewRow(label: "Bus type",       type: "list", context: "Bus"),
                                          SettingsTableViewRow(label: "Lodge",          type: "list", context: "Lodge Bus"),
                                          SettingsTableViewRow(label: "Work group",     type: "list", context: "NPS Vehicle"),
                                          SettingsTableViewRow(label: "Approved category",  type: "list", context: "NPS Approved")
                                        ]
                   ]
    //TODO: Add other dropdown menus to main menu
    
    // MARK: - Layout
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBackground(showWhiteView: false)
        setNavigationBar()
        self.backgroundImage = self.view.takeSnapshot()
        
        let currentScreenFrame = getCurrentScreenFrame()
        
        let displayWidth: CGFloat = currentScreenFrame.width/2
        let displayHeight: CGFloat = currentScreenFrame.height
        
        self.mainTableView = UITableView(frame: CGRect(x: 0, y: statusBarHeight + navigationBarSize, width: displayWidth/3, height: displayHeight - (statusBarHeight + navigationBarSize)))//,
                                         //style: .grouped)
        self.mainTableView.register(MainSettingsTableViewCell.self, forCellReuseIdentifier: "checkBox")
        self.mainTableView.register(MainSettingsTableViewCell.self, forCellReuseIdentifier: "list")
        self.mainTableView.rowHeight = 85 //Auto-set the UITableViewCell's height (requires iOS8+)
        self.mainTableView.dataSource = self
        self.mainTableView.delegate = self
        self.mainTableView.backgroundColor = UIColor.clear
        self.mainTableView.sectionHeaderHeight = self.mainTableView.rowHeight// * 0.8
        self.view.addSubview(self.mainView)
        let mainViewBackground = getMainViewBackground()
        self.mainView.addSubview(mainViewBackground)
        self.mainView.addSubview(self.mainTableView)

        // Set initial main tableview constaints
        self.mainView.translatesAutoresizingMaskIntoConstraints = false
        self.mainView.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor).isActive = true
        self.mainView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.mainView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.mainViewWidthConstraint = self.mainView.widthAnchor.constraint(equalToConstant: currentScreenFrame.width/3)
        self.mainViewWidthConstraint.isActive = true
        self.mainTableView.translatesAutoresizingMaskIntoConstraints = false
        self.mainTableView.topAnchor.constraint(equalTo: self.mainView.topAnchor).isActive = true
        self.mainTableView.bottomAnchor.constraint(equalTo: self.mainView.bottomAnchor).isActive = true
        self.mainTableView.leftAnchor.constraint(equalTo: self.mainView.leftAnchor).isActive = true
        self.mainTableView.rightAnchor.constraint(equalTo: self.mainView.rightAnchor).isActive = true
        /*mainViewBackground.translatesAutoresizingMaskIntoConstraints = false
        mainViewBackground.topAnchor.constraint(equalTo: self.mainView.topAnchor).isActive = true
        mainViewBackground.bottomAnchor.constraint(equalTo: self.mainView.bottomAnchor).isActive = true
        mainViewBackground.leftAnchor.constraint(equalTo: self.mainView.leftAnchor).isActive = true
        mainViewBackground.rightAnchor.constraint(equalTo: self.mainView.rightAnchor).isActive = true
        mainViewBackground.contentMode = .scaleAspectFit
        mainViewBackground.clipsToBounds = true*/
        
        // Set background
        
        //let mainViewBackground = getMainViewBackground()
        mainViewBackground.frame = self.view.frame
        /*print(mainViewBackground.bounds)
        let scaleX = self.view.frame.width / mainViewBackground.frame.width
        let scaleY = self.view.frame.height / mainViewBackground.frame.height
        let scale = max(scaleX, scaleY)
        let tableFrame = self.mainTableView.frame
        mainViewBackground.clipsToBounds = true
        let screenFrame = getCurrentScreenFrame()
        mainViewBackground.frame = CGRect(x: 0, y: screenFrame.height - tableFrame.height, width: tableFrame.width, height: tableFrame.height)
        print(mainViewBackground.frame)
        mainViewBackground.contentMode = .scaleAspectFit*/
        self.mainTableView.backgroundView = mainViewBackground
        
        self.view.addSubview(self.dividingLine)
        self.dividingLine.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.4)
        self.dividingLine.translatesAutoresizingMaskIntoConstraints = false
        self.dividingLine.leftAnchor.constraint(equalTo: self.mainTableView.rightAnchor).isActive = true
        self.dividingLine.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor).isActive = true
        self.dividingLine.widthAnchor.constraint(equalToConstant: 2.0).isActive = true
        self.dividingLine.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        self.childView = UIView(frame: CGRect(x: displayWidth/3, y: statusBarHeight + navigationBarSize, width: 0, height: displayHeight - (statusBarHeight + navigationBarSize)))
        self.view.addSubview(childView)
        self.childView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        self.childView.translatesAutoresizingMaskIntoConstraints = false
        self.childView.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor).isActive = true
        self.childView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.childView.leftAnchor.constraint(equalTo: self.dividingLine.rightAnchor).isActive = true
        // Set the width constraint as a property so we can reset it
        self.childViewWidthConstraint = self.childView.widthAnchor.constraint(equalToConstant: 0)
        self.childViewWidthConstraint.isActive = true
        
        self.dropdownTableView = UITableView(frame: CGRect(x: 0, y: 0, width: 0, height: displayHeight - (statusBarHeight + navigationBarSize)))
        self.dropdownTableView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        self.dropdownTableView.register(DropdownSettingsTableViewCell.self, forCellReuseIdentifier: "dropdown")
        self.dropdownTableView.rowHeight = 60
        self.dropdownTableView.dataSource = self
        self.dropdownTableView.delegate = self
        self.childView.addSubview(dropdownTableView)
        //self.dropdownTableView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        
        // Add buttons
        self.addButton = UIButton(type: .custom)
        self.childView.addSubview(self.addButton)
        self.addButton.setImage(UIImage(named: "addIcon"), for: .normal)
        self.addButton.imageEdgeInsets = UIEdgeInsetsMake(2.5, 2.5, 2.5, 2.5)
        self.addButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        self.addButton.translatesAutoresizingMaskIntoConstraints = false
        self.addButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        self.addButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        self.addButton.topAnchor.constraint(equalTo: self.childView.topAnchor, constant: self.childViewButtonSpacing).isActive = true
        self.addButton.rightAnchor.constraint(equalTo: self.childView.rightAnchor, constant: -20).isActive = true
        self.addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
        self.addButton.isHidden = true
        
        self.editButton = UIButton(type: .custom)
        self.editButton.setImage(UIImage(named: "deleteIcon"), for: .normal)
        self.editButton.setImage(UIImage(named: "checkIcon"), for: .selected)
        self.editButton.imageEdgeInsets = self.addButton.imageEdgeInsets
        self.childView.addSubview(self.editButton)
        self.editButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        self.editButton.translatesAutoresizingMaskIntoConstraints = false
        self.editButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        self.editButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        self.editButton.topAnchor.constraint(equalTo: addButton.topAnchor).isActive = true
        self.editButton.leftAnchor.constraint(equalTo: self.childView.leftAnchor, constant: 20).isActive = true
        self.editButton.addTarget(self, action: #selector(editButtonPressed), for: .touchUpInside)
        editButton.isHidden = true
        
        self.childView.addSubview(self.childViewLabel)
        self.childViewLabel.translatesAutoresizingMaskIntoConstraints = false
        self.childViewLabel.centerXAnchor.constraint(equalTo: self.childView.centerXAnchor).isActive = true
        self.childViewLabel.topAnchor.constraint(equalTo: addButton.topAnchor).isActive = true
        self.childViewLabel.font = UIFont.boldSystemFont(ofSize: 20)
        childViewLabel.isHidden = true
        
        self.dropdownTableView.translatesAutoresizingMaskIntoConstraints = false
        self.dropdownTableView.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: self.childViewButtonSpacing).isActive = true
        self.dropdownTableView.leftAnchor.constraint(equalTo: self.editButton.leftAnchor).isActive = true
        self.dropdownTableView.rightAnchor.constraint(equalTo: addButton.rightAnchor).isActive = true
        self.dropdownTableView.layer.cornerRadius = 10
        // Set the height consttraint as a property so we can reset it
        self.childTableHeightConstraint = self.dropdownTableView.heightAnchor.constraint(equalToConstant: 0)
        self.childTableHeightConstraint.isActive = true
        
        // Make edit buttons for childView
        
        
    }
    
    func getMainViewBackground() -> UIView {
        
        let imageView = UIImageView(image: UIImage(named: "viewControllerBackgroundBlurred"))//self.backgroundImage)//
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        
        let view = UIView()
        view.addSubview(imageView)
        view.addSubview(blurView)
        view.addSubview(vibrancyView)
        //view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        return view
        
    }
    
    // Handle rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        //addBackground(showWhiteView: false)
        //setNavigationBar()
        
        let currentScreenFrame = getCurrentScreenFrame()
        self.mainViewWidthConstraint.constant = currentScreenFrame.width/3
        if self.dropdownTableVisible {
            self.childViewWidthConstraint.constant = currentScreenFrame.width - self.mainViewWidthConstraint.constant
        }
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    
    // MARK: - Navigation

    func setNavigationBar() {
        let screenSize: CGRect = UIScreen.main.bounds
        self.navigationBar = CustomNavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: screenSize.width, height: navigationBarSize))
        self.view.addSubview(self.navigationBar)
        
        self.navigationBar.translatesAutoresizingMaskIntoConstraints = false
        self.navigationBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.navigationBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.navigationBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: statusBarHeight).isActive = true
        self.navigationBar.heightAnchor.constraint(equalToConstant: navigationBarSize).isActive = true
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "backButton"), for: .normal)
        backButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        let backBarButton = UIBarButtonItem(customView: backButton)
        
        let navigationItem = UINavigationItem(title: "Settings")
        navigationItem.leftBarButtonItems = [backBarButton]
        self.navigationBar.setItems([navigationItem], animated: false)
    }

    @objc func backButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - TableView delegate methods
    
    // Return the name for this section
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        return tableView == self.mainTableView ? self.sectionOrder[section] : ""
    }
    
    
    // Set color of header
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        //view.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
        let header = view as! UITableViewHeaderFooterView
        header.backgroundView?.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
    }
    
    
    // Return number of rows in the section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.mainTableView {
            let thisSection = self.settings[self.sectionOrder[section]] ?? self.settings["General"]!
            return thisSection.count
        }
        
        else if tableView == self.dropdownTableView {
            return self.dropdownOptions.count
        } else {
            return 0
        }
    }
    
    
    // return the number of sections
    func numberOfSections(in tableView: UITableView) -> Int{
        return tableView == self.mainTableView ? self.settings.count : 1
    }
    
    
    // Compose each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.mainTableView {
            let sectionName = self.sectionOrder[indexPath.section]
            let rowType = self.settings[sectionName]?[indexPath.row].type ?? ""
            let cell = tableView.dequeueReusableCell(withIdentifier: rowType, for: indexPath) as! MainSettingsTableViewCell
            let label = self.settings[sectionName]?[indexPath.row].label ?? ""
            cell.label.text = label
            //cell.rowType =
            cell.checkBoxButton.isSelected = self.currentSettings[label] ?? false
            
            // If this is a checkbox cell, disable cell selection
            if rowType == "checkBox" {
                cell.selectionStyle = .none
            }
            
            // Make this controller the delegate of the cell so the checkBox delegates to the controller to handle touches
            cell.delegate = self
            cell.checkBoxButton.tag = indexPath.row
            
            let selectedBackgroundView = UIView()
            selectedBackgroundView.backgroundColor = UIColor.clear
            cell.selectedBackgroundView = selectedBackgroundView
            
            return cell
            
        } else if tableView == self.dropdownTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dropdown", for: indexPath) as! DropdownSettingsTableViewCell
            cell.label.text = self.dropdownOptions[indexPath.row]
            
            let selectedBackgroundView = UIView()
            selectedBackgroundView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
            cell.selectedBackgroundView = selectedBackgroundView
            
            return cell
        } else {
            return UITableViewCell()
        }
        
    }
    
    
    // If multiple selections are not allowed, make sure the previous cell is deselected when another one is selected
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView == self.mainTableView {
            self.currentMainIndexPath = tableView.indexPathForSelectedRow
            if let previousIndexPath = tableView.indexPathForSelectedRow {
                let previousCell = tableView.cellForRow(at: previousIndexPath) as! MainSettingsTableViewCell
                previousCell.backgroundColor = previousCell.bgColor
                tableView.deselectRow(at: previousIndexPath, animated: true)
            }
        }
        
        return indexPath
    }
    
    
    // Animate showing and hiding the childView
    func changeDropdownOptionsTableViewWidth(){
        
        if self.dropdownTableVisible {
            // Deactivate temporarily so changing constant doesn't change frame size
            NSLayoutConstraint.deactivate([self.childViewWidthConstraint])
            self.childViewWidthConstraint.constant = 0
            NSLayoutConstraint.activate([self.childViewWidthConstraint])
            
            // Animate collapsing table view
            UIView.animate(withDuration: 0.5, delay: 0, animations: {
                self.childView.center.x -= self.childView.frame.width / 2
                self.childView.layoutIfNeeded()
            }, completion: {_ in
                self.addButton.isHidden = true
                self.editButton.isHidden = true
                self.childViewLabel.isHidden = true
            })
            
            self.dropdownTableVisible = false // reset visibility property
            self.addButton.isHidden = true
            self.editButton.isHidden = true
            self.childViewLabel.isHidden = true
            
            self.editButton.isSelected = false
            self.dropdownTableView.isEditing = false
            self.dropdownTableView.setEditing(false, animated: true)
            
        } else if !self.dropdownTableVisible {
            // Set width
            let currentScreenFrame = getCurrentScreenFrame()
            self.childViewWidthConstraint.constant = currentScreenFrame.width * 2/3
            
            // Animate expanding table view
            //  Reload data (when finished) since they were set to a different list of dropdown options
            UIView.animate(withDuration: 0.5, delay: 0, animations: {
                self.childView.layoutIfNeeded()
                self.childView.center.x += self.childView.frame.width / 2
            }, completion: {_ in
                self.reloadChildViewData()
                self.addButton.isHidden = false
                self.editButton.isHidden = false
                self.childViewLabel.isHidden = false
            })
            
            self.dropdownTableVisible = true//reset visiibility property
        }
        
    }
    
    // Handle selections
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.mainTableView {
            
            let cell = tableView.cellForRow(at: indexPath) as! MainSettingsTableViewCell
            cell.backgroundColor = UIColor.clear
            
            // Should only be one type of row that's selectable, so no need to check
            let settingsRow = self.settings["Dropdown options"]?[indexPath.row]
            if let row = settingsRow {
                self.dropdownOptions = parseJSON(controllerLabel: row.context, fieldName: row.label)
            } else {
                os_log("the indexPath.row in tableView(didSelectRowAt) in SettingsViewController couldn't be found in self.settings", log: OSLog.default, type: .debug)
                return
            }
            
            if indexPath != self.currentMainIndexPath && self.dropdownTableVisible {
                //differnt cell was selected and the dropdown menu is already visible
                reloadChildViewData()
                self.childViewLabel.text = "\(cell.label.text ?? "") options"
            } else if indexPath == self.currentMainIndexPath {
                // an already selected cell was selected, so hide the childView and deselect the cell
                changeDropdownOptionsTableViewWidth()
                tableView.deselectRow(at: indexPath, animated: true)
                cell.backgroundColor = cell.bgColor
                self.currentMainIndexPath = nil // reset it so if the user presses the same cell multiple times in a row, the bg color changes
            } else {
                // a completely new selection
                self.childViewLabel.text = "\(cell.label.text ?? "") options"
                changeDropdownOptionsTableViewWidth()
            }
            
        }
    }
    
    
    // Enable editing
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if tableView == self.dropdownTableView {
                self.dropdownOptions.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .bottom)
            }
        }
    }
    
    
    // Disable swipe delete and editing for main table
    //   Swipe deletes are disabled because it's too easy to accidentally do this and the rows are too short to easily disable it
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        // Only return edit mode if editing has been turned on and this is the dropdown options table
        if tableView.isEditing && tableView == self.dropdownTableView {
            return .delete
        }
        
        // Otherwise, cancel editing
        return .none
    }
    
    
    // Reload dropdown options and reset the height of the tableView
    func reloadChildViewData(withInsert: IndexPath? = nil) {
        
        let contentSize = CGFloat(self.dropdownOptions.count) * self.dropdownTableView.rowHeight//can't use tableView.contentSize because it's always to small
        let childViewTableHeight = self.childView.frame.height - childViewButtonSpacing * 2 - navigationButtonSize
        // If adding a new row, animate the insert
        if let indexPath = withInsert {

            self.dropdownTableView.insertRows(at: [indexPath], with: .bottom)
            
            // Scroll to the positin of the row if the row is out of view
            if contentSize > childViewTableHeight { self.dropdownTableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle) }
            
            // flash the cell's background color
            let deadlineTime = DispatchTime.now() + .seconds(1)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                self.dropdownTableView.deselectRow(at: indexPath, animated: true)
            }
        
        // Otherwise just reload
        } else {
            self.dropdownTableView.reloadData()
        }
        
        // Reset the height of the tableView and animate it (if there were changes
        self.childTableHeightConstraint.constant = min(childViewTableHeight, contentSize)
        UIView.animate(withDuration: 0.15, delay: 0, animations: {self.childView.layoutIfNeeded()}, completion: nil)
        
    }
    
    
    func updateJSONData(value: String? = nil, context: String, field: String) {
        
        // Check if values for inserting were passed
        if let value = value {
            self.dropdownOptions.append(value)
            if dropDownJSON[context][field]["sorted"].bool ?? false {
                self.dropdownOptions.sort()
            }
            
            dropDownJSON[context][field]["options"].arrayObject = self.dropdownOptions
            let position = self.dropdownOptions.index(of: value)
            if let rowIndex = position {
                reloadChildViewData(withInsert: IndexPath(row: rowIndex, section: 0))
            } else {
                // Alert user, although this should never fail
                let alertController = UIAlertController(title: "Insertion failed",
                                                        message: """
                                                                 The insertion failed for an unknown reason. Maybe try again later or edit
                                                                 the configuration JSON file manually from a desktop computer.
                                                                 """,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            dropDownJSON[context][field]["options"].arrayObject = self.dropdownOptions
        }
        
        // Set global vars
        switch field {
        case "Observer name":
            observers = self.dropdownOptions
        case "Destination":
            destinations = self.dropdownOptions
        case "Bus type":
            busTypes = self.dropdownOptions
        case "Lodge":
            lodges = self.dropdownOptions
        case "Work division":
            npsVehicleWorkDivisions = self.dropdownOptions
        case "Approved category":
            npsApprovedCategories = self.dropdownOptions
        default:
            print("settingsRowLabel not understood")
        }
        
        // Write the JSON file
        var fullJSON = JSON()
        fullJSON["fields"] = dropDownJSON
        let success = writeJSONConfigFile(json: fullJSON)
        if !success {
            // Alert user
            let alertController = UIAlertController(title: "Failed to save config file",
                                                    message: """
                                                             The app could not save changes to the configuration file. Your changes to settings will only remain
                                                             while the app is open, but if you turn the iPad off or restart the app all settings will revert to
                                                             how they were before. Try editing the configuration file from a desktop computer when you can.
                                                             """,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }

    }
    
    
    func writeJSONConfigFile(json: JSON) -> Bool {
        
        guard let jsonURL = getConfigURL(requireExistingFile: false) else {
            os_log("Could not get json URL in Settings Controller", log: .default, type: .debug)
            return false
        }
        
        guard let jsonString = json.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            os_log("Could not get json string in Settings Controller", log: .default, type: .debug)
            return false
        }
        
        print(jsonURL)
        // write the file
        do {
            try jsonString.write(to: jsonURL, atomically: false, encoding: .utf8)
        }
        catch {
            os_log("Failed to write JSON string in settings controller", log: .default, type: .debug)
            return false
        }
        
        // If we got here, the write was successful
        return true
    }
    
    
    // Insert a new row
    @objc func addButtonPressed() {
        
        var settingsRowLabel = ""
        var settingsRowContext = ""
        if let indexPath = self.mainTableView.indexPathForSelectedRow, let settingsRow = self.settings["Dropdown options"]?[indexPath.row] {
            //let currentCell = self.mainTableView.cellForRow(at:indexPath) as! MainSettingsTableViewCell
            settingsRowLabel = settingsRow.label
            settingsRowContext = settingsRow.context
        } else {
            print("no selection in mainTableView")
        }
        //Show an alert controller with a text field to add the new value
        let alertController = UIAlertController(title: "New \(settingsRowLabel) option", message: "Add a new option for the \(settingsRowLabel) dropdown menu: ", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
            let textField = alertController.textFields![0] as UITextField
            if let newValue = textField.text, newValue != "" {
                if self.dropdownOptions.contains(newValue) {
                    // Alert user
                    let existsAlertController = UIAlertController(title: "Value already exists",
                                                                  message: "The value you entered already exists in the options for \(settingsRowLabel).",
                                                                  preferredStyle: .alert)
                    existsAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in self.present(alertController, animated: true)}))
                    self.present(existsAlertController, animated: true, completion: nil)
                } else {self.updateJSONData(value: newValue, context: settingsRowContext, field: settingsRowLabel)
                }
            } else {
                // Alert user
                let invalidAlertController = UIAlertController(title: "Invalid entry",
                                                              message: "You must enter a value or press 'Cancel' to dismiss this menu.",
                    preferredStyle: .alert)
                invalidAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in self.present(alertController, animated: true)}))
                self.present(invalidAlertController, animated: true, completion: nil)
            }

        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addTextField(configurationHandler: {(textField : UITextField!) -> Void in
            textField.placeholder = ""
            print(settingsRowLabel)
            textField.autocapitalizationType = settingsRowLabel == "Observer name" ? .words : .sentences
        })
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    
    // Enable/disable editing mode
    @objc func editButtonPressed() {
        // The editButton.isSelected property should correspond to enabling editing mode
        //   The selected/deselected image for the button should automatically change on touch
        
        // Only save the changes and reload the data (change table height) when turning editing mode off
        if self.editButton.isSelected {
            // editing mode is already on, so turn it off
            self.editButton.isSelected = false
            reloadChildViewData()
            
            if let indexPath = self.mainTableView.indexPathForSelectedRow, let settingsRow = self.settings["Dropdown options"]?[indexPath.row] {
                updateJSONData(context: settingsRow.context, field: settingsRow.label)
            }
        } else {
            self.editButton.isSelected = true
        }
        self.dropdownTableView.isEditing = self.editButton.isSelected
        self.dropdownTableView.setEditing(self.editButton.isSelected, animated: true)
    }
    
    
    // MARK: - checkbox Cell delegate
    func checkBoxTapped(checkBox: CheckBoxControl) {
        self.checkBoxTapped(sender: checkBox)
        let checkBoxLabel = self.settings["General"]?[checkBox.tag].label // tag is assigned in cellForRowAt tableView delegate method
        switch checkBoxLabel {
        case "Date alert on":
            sendDateEntryAlert = !checkBox.isSelected // Set to inverse because it's already reset in checkBoxTapped
        case "Show quote":
            showQuoteAtStartup = !checkBox.isSelected
        case "Show help tips":
            showHelpTips = !checkBox.isSelected
        default:
            print("check box label/tag not understood. Label:\(checkBoxLabel), tag:\(checkBox.tag) ")
        }
        
        // Hide the childView if it's visible and deselect the dropdown row
        if self.dropdownTableVisible {
            changeDropdownOptionsTableViewWidth()
            if let selectedPath = self.mainTableView.indexPathForSelectedRow {// self.currentMainIndexPath {
                self.mainTableView.deselectRow(at: selectedPath, animated: true)
                let selectedCell = self.mainTableView.cellForRow(at: selectedPath) as! MainSettingsTableViewCell
                selectedCell.backgroundColor = selectedCell.bgColor
            } else {
                print("could not get selected path")
            }
        }
    }
}

// MARK: -

protocol checkBoxCellProtocol {
    func checkBoxTapped(checkBox: CheckBoxControl)
}


// MARK: -

class MainSettingsTableViewCell: UITableViewCell {
    
    let bgColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
    let spacing: CGFloat = 16
    let label = UILabel()
    let checkBoxButton = CheckBoxControl()
    let moreContentIndicator = UIImageView(image: UIImage(named: "moreSettingsIcon"))
    var delegate: checkBoxCellProtocol!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.label)
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: spacing).isActive = true
        self.label.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.label.textAlignment = .left
        self.label.font = UIFont.systemFont(ofSize: 17)
        
        //if let type = self.rowType, type == "checkBox" {
        if reuseIdentifier == "checkBox"{
            self.contentView.addSubview(self.checkBoxButton)
            self.checkBoxButton.translatesAutoresizingMaskIntoConstraints = false
            self.checkBoxButton.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -spacing * 2).isActive = true
            self.checkBoxButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
            self.checkBoxButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
            self.checkBoxButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            self.checkBoxButton.addTarget(self, action: #selector(checkBoxTapped(sender:)), for: .touchUpInside)
        } else if reuseIdentifier == "list"{
            self.moreContentIndicator.contentMode = .scaleAspectFit
            self.contentView.addSubview(self.moreContentIndicator)
            self.moreContentIndicator.translatesAutoresizingMaskIntoConstraints = false
            self.moreContentIndicator.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -spacing).isActive = true
            self.moreContentIndicator.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
            self.moreContentIndicator.widthAnchor.constraint(equalToConstant: 15).isActive = true
            self.moreContentIndicator.heightAnchor.constraint(equalToConstant: 15).isActive = true
        }
        
        self.backgroundColor = bgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc func checkBoxTapped(sender: UIButton) {
        self.delegate.checkBoxTapped(checkBox: sender as! CheckBoxControl)
    }
    
}


// MARK: -
class DropdownSettingsTableViewCell: UITableViewCell {
    
    let label = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.label)
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.label.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        
        self.backgroundColor = UIColor.clear//UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

