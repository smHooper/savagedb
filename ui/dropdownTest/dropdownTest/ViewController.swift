//
//  ViewController.swift
//  sdafjkbslib
//
//  Created by Davidson Family on 11/1/17.
//  Copyright © 2017 Archetapp. All rights reserved.
//

import UIKit


class ViewController: UIViewController, UITextFieldDelegate {
    
    //var button = dropDownBtn()
    @IBOutlet weak var button: dropDownBtn!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Get the bounds from the storyboard
        let textFieldBounds = button.frame
        let centerX = button.centerXAnchor
        let centerY = button.centerYAnchor
        
        //Configure the button
        button = dropDownBtn.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        button.placeholder = "Select employee"
        button.translatesAutoresizingMaskIntoConstraints = false
        
        //Add Button to the View Controller
        self.view.addSubview(button)
        
        //button Constraints
        
        button.centerXAnchor.constraint(equalTo: centerX).isActive = true
        button.centerYAnchor.constraint(equalTo: centerY).isActive = true
        button.widthAnchor.constraint(equalToConstant: textFieldBounds.width).isActive = true
        button.heightAnchor.constraint(equalToConstant: textFieldBounds.height).isActive = true//*/
        
        //Set the drop down menu's options
        button.dropView.dropDownOptions = ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"]
        button.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    //####################################################################################################################
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let field = textField as! dropDownBtn
        guard let text = textField.text else {
            print("Guard failed")
            return
            }
        // Hide keyboard if "Other" wasn't selected and the dropdown has not yet been pressed
        if field.dropView.dropDownOptions.contains(text) || !field.dropDownWasPressed{
            print("resigning")
            textField.resignFirstResponder()
        } else {
            print("not resigning")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard
        textField.resignFirstResponder()
        return true
    }
    
}



protocol dropDownProtocol {
    func dropDownPressed(string : String)
}

@IBDesignable class dropDownBtn: UITextField, dropDownProtocol {
    
    // Keep track of whether the dropDownMenu was pressed. This helps suppress the keyboard the first time the text field is pressed
    var dropDownWasPressed = false
    
    func dropDownPressed(string: String) {
        if (self.dropView.dropDownOptions.contains(string) && string != "Other"){
            print("Selection not 'other'")
            self.resignFirstResponder()
            self.text = string// for: .normal)
            self.dismissDropDown()
        }
        else {
            //self.delegate?.textFieldDidBeginEditing!(self)
            //self.delegate?.
            print("text == 'Other'")
            self.text?.removeAll()
            self.becomeFirstResponder()
            self.dismissDropDown()
        }
        
        // Indicate that the dropdown button has been pressed so the keyboard will appear when "Other" is selected
        dropDownWasPressed = true
    }
    
    var dropView = dropDownView()
    @IBInspectable var height = NSLayoutConstraint()
    
    func setupDropView(){
        dropView = dropDownView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        dropView.delegate = self
        dropView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        /*dropView = dropDownView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        dropView.delegate = self
        dropView.translatesAutoresizingMaskIntoConstraints = false*/
        setupDropView()
    }
    
    override func didMoveToSuperview() {
        self.superview?.addSubview(dropView)
        self.superview?.bringSubview(toFront: dropView)
        dropView.topAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        dropView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        dropView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        height = dropView.heightAnchor.constraint(equalToConstant: 0)
    }
    
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
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.dropView.layoutIfNeeded()
                self.dropView.center.y += self.dropView.frame.height / 2
            }, completion: nil)
            
        } else {
            isOpen = false
            
            NSLayoutConstraint.deactivate([self.height])
            self.height.constant = 0
            NSLayoutConstraint.activate([self.height])
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
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
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
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

class dropDownView: UIView, UITableViewDelegate, UITableViewDataSource  {
    
    var dropDownOptions = [String]()
    
    var tableView = UITableView()
    
    var delegate : dropDownProtocol!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //tableView.backgroundColor = UIColor.darkGray
        //self.backgroundColor = UIColor.darkGray
        
        
        
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
        
        cell.textLabel?.text = dropDownOptions[indexPath.row]
        cell.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        cell.layer.borderWidth = 0.25
        cell.layer.borderColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1).cgColor
        cell.textLabel?.textAlignment = .center
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate.dropDownPressed(string: dropDownOptions[indexPath.row])
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
}




















