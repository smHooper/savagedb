//
//  SessionViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/10/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit

class SessionViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var observerTextField: UITextField!
    @IBOutlet weak var openTimeTextField: UITextField!
    @IBOutlet weak var closeTimeTextField: UITextField!
    
    // make a new struct that stores the stores a field name and has a method that dismisses the keyboard controller for that field

    
    // Either a session has already started and user is returning to edit or this is a new session
    var session = Session?.self

    override func viewDidLoad() {
        super.viewDidLoad()
        
        customDatePicker(textField: openTimeTextField)
        customDatePicker(textField: closeTimeTextField)
        //customDatePickers(textFields: [openTimeTextField, closeTimeTextField])
        
        observerTextField.delegate = self
        openTimeTextField.delegate = self
        
        // The session has already started
        //if let session = session {
        //    observerTextField.text = session.observer
        //    openTimeTextField.text = session.openTime
        //}*/
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Fill datetime fields
    @IBAction func openTimeTextFieldEditing(_ sender: UITextField) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.time
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(handleOpenDatePicker), for: UIControlEvents.valueChanged)
    }
    
    @objc func handleOpenDatePicker(sender: UIDatePicker) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        openTimeTextField.text = timeFormatter.string(from: sender.date)
    }
    
    @IBAction func closeTimeTextFieldEditing(_ sender: UITextField) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.time
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(handleCloseDatePicker), for: UIControlEvents.valueChanged)
    }
    
    @objc func handleCloseDatePicker(sender: UIDatePicker) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        closeTimeTextField.text = timeFormatter.string(from: sender.date)
    }
    
    // Make a tool bar for the date picker with an ok button and a done button
    func customDatePicker(textField: UITextField) {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(SessionViewController.donePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        toolBar.setItems([flexSpace, doneButton, flexSpace], animated: true)
        
        // Make sure this is added to the controller when openTimeTextFieldEditing is called
        //openTimeTextField.inputAccessoryView = toolBar
        textField.inputAccessoryView = toolBar
    }
    
    // Check that the done button on custom DatePicker was pressed
    @objc func donePressed(sender: UIBarButtonItem) {
        openTimeTextField.resignFirstResponder()
    }
    
    /*override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    */

}

