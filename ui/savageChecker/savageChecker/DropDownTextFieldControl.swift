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
    var dropDownID: String? = "" // To distinguish notifications when multiple drowdowns are in the same ViewController
    //var height: NSLayoutConstraint!
    
    func dropDownPressed(string: String) {
        if (self.dropView.dropDownOptions.contains(string) && string != "Other"){
            self.resignFirstResponder()
            self.text = string// for: .normal)
            self.dismissDropDown()
            NotificationCenter.default.post(name: Notification.Name("dropDownPressed:\(self.dropDownID!)"), object: nil)
        }
        // If other was selected, show the keyboard
        else {
            self.text?.removeAll()
            NotificationCenter.default.post(name: Notification.Name("dropDownPressed:\(self.dropDownID!)"), object: nil)
            self.becomeFirstResponder()
            self.dismissDropDown()
        }
        
        // Indicate that the dropdown button has been pressed so the keyboard will appear when "Other" is selected
        dropDownWasPressed = true
    }
    
    var dropView = DropDownView()
    @IBInspectable var height = NSLayoutConstraint()
    
    func setupDropView(){
        dropView = DropDownView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        dropView.delegate = self
        dropView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDropView()
    }
    
    /*override func didMoveToSuperview() {
        self.superview?.addSubview(dropView)
        self.superview?.bringSubview(toFront: dropView)
        dropView.topAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        dropView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        dropView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        height = dropView.heightAnchor.constraint(equalToConstant: 0)
    }*/
    
    /*func configureTextField(menuOptions: [String], templateTextField: Any?, placeholderText: String = ""){
        guard let template = templateTextField as? UITextField else {
            fatalError("Failed to convert templateTextField to UITextField in convenience initializer: \(templateTextField)")
        }
        //let frame = templateTextField.frame
        
        
        //Get the bounds from the storyboard's text field
        let frame = template.frame
        let font = template.font
        let centerX = template.centerXAnchor
        let centerY = template.centerYAnchor
        
        //Configure the text field
        //observerTextField = DropDownTextField.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.translatesAutoresizingMaskIntoConstraints = false
        
        //Add Button to the View Controller
        //self.superview.view.addSubview(self)
        //make delegate
        
        //button Constraints
        //observerTextField.frame = CGRect(x: 0, y: 0, width: textFieldBounds.width, height: textFieldBounds.height)
        self.font = font
        self.centerXAnchor.constraint(equalTo: centerX).isActive = true
        self.centerYAnchor.constraint(equalTo: centerY).isActive = true
        self.widthAnchor.constraint(equalToConstant: frame.width).isActive = true
        self.heightAnchor.constraint(equalToConstant: frame.height).isActive = true//*/
        self.placeholder = placeholderText
        //Set the drop down menu's options
        self.dropView.dropDownOptions = menuOptions
    }
    */*/
    
    
    var isOpen = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isOpen == false {
            
            isOpen = true
            
            NSLayoutConstraint.deactivate([self.height])
            
            if self.dropView.tableView.contentSize.height > 150 {
                self.height.constant = 150
            } else {
                self.height.constant = self.dropView.tableView.contentSize.height
            }
            
            NSLayoutConstraint.activate([self.height])
            
            UIView.animate(withDuration: 0.5, delay: 0, animations: {
                self.dropView.layoutIfNeeded()
                self.dropView.center.y += self.dropView.frame.height / 2
            }, completion: nil)
            
        } else {
            isOpen = false
            
            NSLayoutConstraint.deactivate([self.height])
            self.height.constant = 0
            NSLayoutConstraint.activate([self.height])
            UIView.animate(withDuration: 0.5, delay: 0, animations: {
                self.dropView.center.y -= self.dropView.frame.height / 2
                self.dropView.layoutIfNeeded()
            }, completion: nil)
            
        }
    }
    
    func dismissDropDown() {
        isOpen = false
        NSLayoutConstraint.deactivate([self.height])
        self.height.constant = 0
        NSLayoutConstraint.activate([self.height])
        UIView.animate(withDuration: 0.5, delay: 0, animations: {
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
    var delegate : dropDownProtocol!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(tableView)
        
        tableView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        tableView.layer.borderWidth = 0.5
        tableView.layer.borderColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1).cgColor
        tableView.layer.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.2).cgColor
        
        /*tableView.layer.shadowOffset = CGSize(width:4, height:4)
         tableView.layer.shadowColor = UIColor.black.cgColor
         tableView.layer.shadowRadius = 4
         tableView.layer.shadowOpacity = 0.25
         tableView.layer.masksToBounds = false
         tableView.clipsToBounds = false*/
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dropDownOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        print("Index: \(indexPath.row)")
        cell.textLabel?.text = dropDownOptions[indexPath.row]
        cell.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        cell.layer.borderWidth = 0.25
        cell.layer.borderColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1).cgColor
        cell.textLabel?.textAlignment = .center
        //cell.textLabel?.font = UIFont(name:"Helvetica", size:14)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate.dropDownPressed(string: dropDownOptions[indexPath.row])
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
