//
//  SessionViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/10/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import os.log

class SessionViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var observerTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var openTimeTextField: UITextField!
    @IBOutlet weak var closeTimeTextField: UITextField!
    @IBOutlet weak var viewVehiclesButton: UIBarButtonItem!
    // This value is either passed by `ObservationTableViewController` in `prepare(for:sender:)` or constructed when a new session begins.
    var session: Session?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        observerTextField.delegate = self
        dateTextField.delegate = self
        openTimeTextField.delegate = self
        closeTimeTextField.delegate = self
        
        // The session has already started
        if let session = session {
            observerTextField.text = session.observerName
            dateTextField.text = session.date
            openTimeTextField.text = session.openTime
            closeTimeTextField.text = session.closeTime
            viewVehiclesButton.isEnabled = true // Returning to view so make sure it's enabled
            
        }  else {
            // date defaults to today
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            dateTextField.text = formatter.string(from: now)
            
            // Disable navigation to vehicle list until all fields are filled
            viewVehiclesButton.isEnabled = false
        }
        
        createOpenDatePicker()//textField: openTimeTextField)
        createCloseDatePicker()//textField: closeTimeTextField)
        createDatePicker()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    //####################################################################################################################
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard
        // Try to create a session instance after the keyboard is dismissed
        updateSession()
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Fill datetime fields
    // #####################################################################################################################
    // Set the target for the date picker
    @IBAction func dateFieldEditing(_ sender: UITextField) {
    let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.date
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(handleDatePicker), for: UIControlEvents.valueChanged)
    }
    // Set the text for the field from user input
    @objc func handleDatePicker(sender: UIDatePicker) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .short
        timeFormatter.timeStyle = .none
        dateTextField.text = timeFormatter.string(from: sender.date)
    }
    
    // Make a tool bar for the date picker with an ok button and a done button
    func createDatePicker(){//textField: UITextField) {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(SessionViewController.dateDonePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        toolBar.setItems([flexSpace, doneButton, flexSpace], animated: true)
        
        // Make sure this is added to the controller when openTimeTextFieldEditing is called
        //openTimeTextField.inputAccessoryView = toolBar
        dateTextField.inputAccessoryView = toolBar
    }
    
    // Check that the done button on custom DatePicker was pressed
    @objc func dateDonePressed(sender: UIBarButtonItem) {
        // Try to create a session instance after the datePicker is dismissed
        updateSession()
        dateTextField.resignFirstResponder()
    }
    
    @IBAction func openTimeTextFieldEditing(_ sender: UITextField) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.time
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(handleOpenDatePicker), for: UIControlEvents.valueChanged)
        // Set the default time to now
        if (openTimeTextField.text?.isEmpty)! {
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            openTimeTextField.text = formatter.string(from: now)
        }
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
        // Try to create a session instance after the datePicker is dismissed
        updateSession()
        openTimeTextField.resignFirstResponder()
    }
    
    @IBAction func closeTimeTextFieldEditing(_ sender: UITextField){
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.time
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(handleCloseDatePicker), for: UIControlEvents.valueChanged)
        if (closeTimeTextField.text?.isEmpty)! {
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            closeTimeTextField.text = formatter.string(from: now)
        }
    }
    
    @objc func handleCloseDatePicker(sender: UIDatePicker) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        closeTimeTextField.text = timeFormatter.string(from: sender.date)
    }
    
    // Make a tool bar for the date picker with an ok button and a done button
    func createCloseDatePicker(){//textField: UITextField) {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(SessionViewController.closeDonePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        toolBar.setItems([flexSpace, doneButton, flexSpace], animated: true)
        
        // Make sure this is added to the controller when textFieldEditing is called
        closeTimeTextField.inputAccessoryView = toolBar
    }
    
    // Check that the done button on custom DatePicker was pressed
    @objc func closeDonePressed(sender: UIBarButtonItem) {
        // Try to create a session instance after the datePicker is dismissed
        updateSession()
        closeTimeTextField.resignFirstResponder()
    }
    
    
    //MARK: Navigation
    // Send session to ObservationTableViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === viewVehiclesButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        guard let destinationController = segue.destination as? ObservationTableViewController else {
            os_log("The destination controller isn't an ObservationTableViewController", log: OSLog.default, type: .debug)
            return
        }
        destinationController.session = self.session
    }
    
    
    
    //MARK: Private methods
    private func updateSession(){
        // Check that all text fields are filled in
        let observerName = observerTextField.text ?? ""
        let date = dateTextField.text ?? ""
        let openTime = openTimeTextField.text ?? ""
        let closeTime = closeTimeTextField.text ?? ""
        if !observerName.isEmpty && !openTime.isEmpty && !closeTime.isEmpty{
            self.session = Session(observerName: observerName, openTime: openTime, closeTime: closeTime, givenDate: date)
            print("Session updated")
            viewVehiclesButton.isEnabled = true
        }
        
    }
    
    //

}

