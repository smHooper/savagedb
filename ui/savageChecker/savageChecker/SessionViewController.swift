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
    
    // This value is either passed by `ObservationTableViewController` in `prepare(for:sender:)` or constructed when a new session begins.
    var session: Session?

    
    // Either a session has already started and user is returning to edit or this is a new session
    //var session = Session?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        observerTextField.delegate = self
        openTimeTextField.delegate = self
        closeTimeTextField.delegate = self

        // The session has already started
        if let session = session {
            observerTextField.text = session.observerName
            openTimeTextField.text = session.openTime
            closeTimeTextField.text = session.closeTime
            
        }
        
        createOpenDatePicker()//textField: openTimeTextField)
        createCloseDatePicker()//textField: closeTimeTextField)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    //####################################################################################################################
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Fill datetime fields
    // #####################################################################################################################
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
    
    // Make a tool bar for the date picker with an ok button and a done button
    func createOpenDatePicker(){//textField: UITextField) {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(SessionViewController.openDonePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        toolBar.setItems([flexSpace, doneButton, flexSpace], animated: true)
        
        // Make sure this is added to the controller when openTimeTextFieldEditing is called
        //openTimeTextField.inputAccessoryView = toolBar
        openTimeTextField.inputAccessoryView = toolBar
    }
    
    // Check that the done button on custom DatePicker was pressed
    @objc func openDonePressed(sender: UIBarButtonItem) {
        openTimeTextField.resignFirstResponder()
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
        print("")
    }
    // Make a tool bar for the date picker with an ok button and a done button
    func createCloseDatePicker(){//textField: UITextField) {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(SessionViewController.closeDonePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        toolBar.setItems([flexSpace, doneButton, flexSpace], animated: true)
        
        // Make sure this is added to the controller when openTimeTextFieldEditing is called
        //openTimeTextField.inputAccessoryView = toolBar
        closeTimeTextField.inputAccessoryView = toolBar
    }
    
    // Check that the done button on custom DatePicker was pressed
    @objc func closeDonePressed(sender: UIBarButtonItem) {
        closeTimeTextField.resignFirstResponder()
    }
    
    //

}

