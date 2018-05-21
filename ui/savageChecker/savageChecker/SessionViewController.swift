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
    @IBOutlet weak var observerTextField: DropDownTextField!
    @IBOutlet weak var templateObserverField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var openTimeTextField: UITextField!
    @IBOutlet weak var closeTimeTextField: UITextField!
    @IBOutlet weak var viewVehiclesButton: UIBarButtonItem!

    var session: Session?// This value is either passed by `ObservationTableViewController` in `prepare(for:sender:)` or constructed when a new session begins.
    var observerOptions = ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up delegates for text fields
        //observerTextField = DropDownTextField(frame: templateObserverField.frame)//give it no height or width at first
        //observerTextField.configureTextField(menuOptions: employees, templateTextField: templateObserverField, placeholderText: "Select observer name")
        //self.view.addSubview(observerTextField)
        addObserverTextField(menuOptions: observerOptions)
        observerTextField.delegate = self
        dateTextField.delegate = self
        openTimeTextField.delegate = self
        closeTimeTextField.delegate = self
        
        // The user is opening the app again after closing it
        if let session = loadSession() {
            observerTextField.text = session.observerName
            dateTextField.text = session.date
            openTimeTextField.text = session.openTime
            closeTimeTextField.text = session.closeTime
            viewVehiclesButton.isEnabled = true // Returning to view so make sure it's enabled
        }
        // The user is returning to the session scene from another scene
        else if let session = session {
            observerTextField.text = session.observerName
            dateTextField.text = session.date
            openTimeTextField.text = session.openTime
            closeTimeTextField.text = session.closeTime
            viewVehiclesButton.isEnabled = true // Returning to view so make sure it's enabled
        }
        // The user has opened the app for the first time since data were cleared
        else {
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
    
    //MARK: CustomDropDownTextField
    func addObserverTextField(menuOptions: [String]){
        //Get the bounds from the storyboard's text field
        let frame = self.view.frame
        let font = observerTextField.font
        let centerX = observerTextField.centerXAnchor
        let centerY = templateObserverField.centerYAnchor
        
        //Configure the text field
        observerTextField = DropDownTextField.init(frame: frame)
        observerTextField.translatesAutoresizingMaskIntoConstraints = false
        
        //Add Button to the View Controller
        self.view.addSubview(observerTextField)
        
        //button Constraints
        //observerTextField.frame = CGRect(x: 0, y: 0, width: textFieldBounds.width, height: textFieldBounds.height)
        observerTextField.font = font
        observerTextField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16).isActive = true
        observerTextField.centerYAnchor.constraint(equalTo: centerY).isActive = true
        observerTextField.widthAnchor.constraint(equalToConstant: frame.size.width - 24).isActive = true
        observerTextField.heightAnchor.constraint(equalToConstant: templateObserverField.frame.size.height).isActive = true//*/
        observerTextField.placeholder = "Select observer name"
        
        //Set the drop down menu's options
        observerTextField.dropView.dropDownOptions = menuOptions//
        //observerTextField.delegate = self
        
        // Set up drop view constraints
        observerTextField.superview?.addSubview(observerTextField.dropView)
        observerTextField.superview?.bringSubview(toFront: observerTextField.dropView)
        observerTextField.dropView.topAnchor.constraint(equalTo: observerTextField.bottomAnchor).isActive = true
        observerTextField.dropView.centerXAnchor.constraint(equalTo: observerTextField.centerXAnchor).isActive = true
        observerTextField.dropView.widthAnchor.constraint(equalTo: observerTextField.widthAnchor).isActive = true
        observerTextField.height = observerTextField.dropView.heightAnchor.constraint(equalToConstant: 0)
        
        // Set a listener to see if the text field changed
        observerTextField.dropDownID = "observer"
        NotificationCenter.default.addObserver(self, selector: #selector(updateSession), name: Notification.Name("dropDownPressed:observer"), object: nil)
        //observerTextField.dropView.addTarget(self, action: #selector(SessionViewController.observerTextFieldDidChange), for: UIControlEvents.editingChanged)
    }
    
    
    //MARK: UITextFieldDelegate
    //####################################################################################################################
    // Indicate what to do when the text field is tapped
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField is DropDownTextField {
            let field = textField as! DropDownTextField
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
        //Otherwise, do stuff as usual
    }
    
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
        updateSession()
        destinationController.session = self.session
        //save the session before leaving
        //saveSession()
    }
    
    
    //MARK: Private methods
    @objc private func updateSession(){
        // Check that all text fields are filled in
        let observerName = observerTextField.text ?? ""
        let date = dateTextField.text ?? ""
        let openTime = openTimeTextField.text ?? ""
        let closeTime = closeTimeTextField.text ?? ""
        if !observerName.isEmpty && !openTime.isEmpty && !closeTime.isEmpty{
            self.session = Session(observerName: observerName, openTime: openTime, closeTime: closeTime, givenDate: date)
            print("Session updated")
            viewVehiclesButton.isEnabled = true
            saveSession()
        }
    }
    
    private func saveSession() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(session, toFile: Session.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Session successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save session...", log: OSLog.default, type: .error)
        }
    }

    private func loadSession() -> Session? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Session.ArchiveURL.path) as? Session
    }

}

