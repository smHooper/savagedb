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
    var mainTableView: UITableView!
    var dropdownTableView: UITableView!
    var dropdownOptions = [String]()
    var dropdownTableVisible = false
    var dropdownTableWidthConstraint = NSLayoutConstraint()
    
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
                                          SettingsTableViewRow(label: "Approved type",  type: "list", context: "NPS Approved")
                                        ]
                   ]
    
    
    // MARK - Layout
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBackground(showWhiteView: false)
        setNavigationBar()
        
        let displayWidth: CGFloat = self.view.frame.width/2
        let displayHeight: CGFloat = self.view.frame.height
        
        self.mainTableView = UITableView(frame: CGRect(x: 0, y: statusBarHeight + navigationBarSize, width: displayWidth/2, height: displayHeight - (statusBarHeight + navigationBarSize)))//,
                                         //style: .grouped)
        self.mainTableView.register(MainSettingsTableViewCell.self, forCellReuseIdentifier: "checkBox")
        self.mainTableView.register(MainSettingsTableViewCell.self, forCellReuseIdentifier: "list")
        //Auto-set the UITableViewCell's height (requires iOS8+)
        self.mainTableView.rowHeight = 85
        self.mainTableView.dataSource = self
        self.mainTableView.delegate = self
        self.view.addSubview(mainTableView)
        self.mainTableView.backgroundColor = UIColor.clear
        self.mainTableView.sectionHeaderHeight = self.mainTableView.rowHeight// * 0.8
        
        //self.mainTableView.sectionIndexBackgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        
        self.dropdownTableView = UITableView(frame: CGRect(x: 0, y: statusBarHeight + navigationBarSize, width: 0, height: displayHeight - (statusBarHeight + navigationBarSize)))
        self.dropdownTableView.register(DropdownSettingsTableViewCell.self, forCellReuseIdentifier: "dropdown")
        self.dropdownTableView.rowHeight = 60
        self.dropdownTableView.dataSource = self
        self.dropdownTableView.delegate = self
        self.view.addSubview(dropdownTableView)
        self.dropdownTableView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        
        // Set initial main tableview constaints
        self.mainTableView.translatesAutoresizingMaskIntoConstraints = false
        self.mainTableView.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor).isActive = true
        self.mainTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.mainTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.mainTableView.rightAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        self.dropdownTableView.translatesAutoresizingMaskIntoConstraints = false
        self.dropdownTableView.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor).isActive = true
        self.dropdownTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.dropdownTableView.leftAnchor.constraint(equalTo: self.mainTableView.leftAnchor).isActive = true
        //self.dropdownTableView.widthAnchor.constraint(equalToConstant: 0).isActive = true
        self.dropdownTableWidthConstraint = self.dropdownTableView.widthAnchor.constraint(equalToConstant: 0)
        self.dropdownTableWidthConstraint.isActive = true
        
    }
    
    // Handle rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        addBackground(showWhiteView: false)
        setNavigationBar()
        
        let currentScreenFrame = getCurrentScreenFrame()
        if self.dropdownTableVisible {
            self.dropdownTableView.widthAnchor.constraint(equalToConstant: currentScreenFrame.width/2).isActive = true
        }
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
            
            return cell
            
        } else if tableView == self.dropdownTableView{
            let cell = tableView.dequeueReusableCell(withIdentifier: "dropdown", for: indexPath) as! DropdownSettingsTableViewCell
            cell.label.text = dropdownOptions[indexPath.row]
            return cell
        } else {
            return UITableViewCell()
        }
        
    }
    
    
    // Handle selections
    func changeDropdownOptionsTableViewWidth(){
        
        if self.dropdownTableVisible {
            
            NSLayoutConstraint.deactivate([self.dropdownTableWidthConstraint])
            self.dropdownTableWidthConstraint.constant = 0
            NSLayoutConstraint.activate([self.dropdownTableWidthConstraint])
            
            UIView.animate(withDuration: 0.5, delay: 0, animations: {
                self.dropdownTableView.center.x -= self.dropdownTableView.frame.width / 2
                self.dropdownTableView.layoutIfNeeded()
            }, completion: nil)
            
            self.dropdownTableVisible = false
            
        } else {
            
            let currentScreenFrame = getCurrentScreenFrame()
            self.dropdownTableWidthConstraint.constant = currentScreenFrame.width/2
            UIView.animate(withDuration: 0.5, delay: 0, animations: {
                self.dropdownTableView.layoutIfNeeded()
                self.dropdownTableView.center.x += self.dropdownTableView.frame.width / 2
            }, completion: nil)
            
            self.dropdownTableVisible = true
        }
        
        self.dropdownTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.mainTableView {
            // Should only be one type of row that's selectable, so no need to check
            let settingsRow = self.settings["Dropdown options"]?[indexPath.row]
            if let row = settingsRow {
                self.dropdownOptions = parseJSON(controllerLabel: row.context, fieldName: row.label)
            } else {
                os_log("the indexPath.row in tableView(didSelectRowAt) in SettingsViewController couldn't be found in self.settings", log: OSLog.default, type: .debug)
                return
            }

            changeDropdownOptionsTableViewWidth()
        }
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
    }
}


protocol checkBoxCellProtocol {
    func checkBoxTapped(checkBox: CheckBoxControl)
}


// MARK: -
fileprivate let spacing: CGFloat = 16
class MainSettingsTableViewCell: UITableViewCell {
    
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
        
        self.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
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
        self.label.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.label.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        
        self.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

