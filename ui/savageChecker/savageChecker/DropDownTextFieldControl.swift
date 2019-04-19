//
//  CustomDropDownView.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/15/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//
import UIKit
import os.log

protocol dropDownProtocol {
    func dropDownPressed(string : String)
}

@IBDesignable class DropDownTextField: UITextField, dropDownProtocol {
    
    // Keep track of whether the dropDownMenu was pressed. This helps suppress the keyboard the first time the text field is pressed
    var dropDownWasPressed = false
    var dropDownMenuPressed = false
    var dropDownID: Int? = 0//: String? = "" // To distinguish notifications when multiple drowdowns are in the same ViewController
    var dropView = DropDownView()
    var heightConstraint = NSLayoutConstraint()
    var animationDuration = 0.35
    
    func dropDownPressed(string: String) {
        /*if (self.dropView.dropDownOptions.contains(string)){// && string != "Other"){
            self.resignFirstResponder()
            self.text = string// for: .normal)
            self.dismissDropDown()
            let dictionary: [Int: String] = [self.dropDownID!: string]
            NotificationCenter.default.post(name: Notification.Name("dropDownPressed:\(self.dropDownID!)"), object: dictionary)
        }
        // If other was selected, show the keyboard
        else {
            self.text?.removeAll()
            let dictionary: [Int: String] = [self.dropDownID!: string]
            NotificationCenter.default.post(name: Notification.Name("dropDownPressed:\(self.dropDownID!)"), object: dictionary)
            self.becomeFirstResponder()
            self.dismissDropDown()
        }*/
        self.resignFirstResponder()
        self.text = string// for: .normal)
        self.dismissDropDown()
        let dictionary: [Int: String] = [self.dropDownID!: string]
        NotificationCenter.default.post(name: Notification.Name("dropDownPressed:\(self.dropDownID!)"), object: dictionary)
        
        // Indicate that the dropdown button has been pressed so the keyboard will appear when "Other" is selected
        //  Also, when the dropdownTextField is initially pressed, didEndEditing() is called.
        //  Use this property to distinguish between didEndEditing calls when an option was
        //  actually chosen and when the keyboard is dismissed.
        if self.dropView.wasPressed {
            self.dropDownWasPressed = true
            // reset dropView.wasPressed so that if a user selects the same text field, it behaves appropiately
            self.dropView.wasPressed = false
        } else {
            self.dropDownWasPressed = false
        }
        
    }
    

    
    func setupDropView(){
        self.dropView = DropDownView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        self.dropView.delegate = self
        self.dropView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDropView()
    }
    
    
    var isOpen = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isOpen == false {
            
            self.isOpen = true
            
            NSLayoutConstraint.deactivate([self.heightConstraint])
            
            if self.dropView.tableView.contentSize.height > self.dropView.height {
                self.heightConstraint.constant = self.dropView.height
            } else {
                self.heightConstraint.constant = self.dropView.tableView.contentSize.height
            }
            
            NSLayoutConstraint.activate([self.heightConstraint])
            
            UIView.animate(withDuration: self.animationDuration, delay: 0, animations: {
                self.dropView.layoutIfNeeded()
                self.dropView.center.y += self.dropView.frame.height / 2
            }, completion: nil)
            
        } else {
            self.isOpen = false
            
            NSLayoutConstraint.deactivate([self.heightConstraint])
            self.heightConstraint.constant = 0
            NSLayoutConstraint.activate([self.heightConstraint])
            UIView.animate(withDuration: self.animationDuration, delay: 0, animations: {
                self.dropView.center.y -= self.dropView.frame.height / 2
                self.dropView.layoutIfNeeded()
            }, completion: nil)
            
        }
    }
    
    func dismissDropDown() {
        self.isOpen = false
        NSLayoutConstraint.deactivate([self.heightConstraint])
        self.heightConstraint.constant = 0
        NSLayoutConstraint.activate([self.heightConstraint])
        UIView.animate(withDuration: self.animationDuration, delay: 0, animations: {
            self.dropView.center.y -= self.dropView.frame.height / 2
            self.dropView.layoutIfNeeded()
        }, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDropView()
        //fatalError("init(coder:) has not been implemented")
    }
}

class DropDownView: UIControl, UITableViewDelegate, UITableViewDataSource  {
    
    //MARK: Properties
    var dropDownOptions = [String]()
    var tableView = UITableView()
    var delegate: dropDownProtocol!
    var wasPressed = false
    var height: CGFloat = 180
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(tableView)
        
        self.tableView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.tableView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.tableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        self.tableView.layer.borderWidth = 0.5
        //self.tableView.layer.borderColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1).cgColor
        //self.tableView.layer.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.2).cgColor
        self.tableView.layer.borderColor = UIColor.clear.cgColor
        self.tableView.rowHeight = self.height/3.3
        
        self.tableView.delaysContentTouches = false
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dropDownOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = dropDownOptions[indexPath.row]
        //cell.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        cell.backgroundColor = UIColor.clear
        cell.layer.borderWidth = 0.25
        cell.layer.borderColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1).cgColor
        cell.textLabel?.textAlignment = .center
        //cell.textLabel?.font = UIFont(name:"Helvetica", size:14)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.wasPressed = true
        self.delegate.dropDownPressed(string: dropDownOptions[indexPath.row])
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
