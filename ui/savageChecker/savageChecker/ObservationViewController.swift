//
//  ObservationViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import os.log

class ObservationViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    
    @IBOutlet weak var observerNameTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var driverNameTextField: UITextField!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var observation: Observation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observerNameTextField.delegate = self
        dateTextField.delegate = self
        timeTextField.delegate = self
        driverNameTextField.delegate = self
        destinationTextField.delegate = self
        
        // The observation already exists and is open for viewing/editing
        if let observation = observation {
            observerNameTextField.text = observation.observerName
            dateTextField.text = observation.date
            timeTextField.text = observation.time
            driverNameTextField.text = observation.driverName
            destinationTextField.text = observation.destination
            
        }
        createDatePicker()
        createTimePicker()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation
    // Configure view controller before it's presented
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        guard let destinationController = segue.destination as? ObservationTableViewController else {
            os_log("The destination controller isn't an ObservationTableViewController", log: OSLog.default, type: .debug)
            return
        }
        let session = destinationController.session
        print("session observer: \(session?.observerName ?? "")")
        //observerNameTextField.text = session?.observerName
        //dateTextField.text = session?.date
        let time = timeTextField.text
        let driverName = driverNameTextField.text
        let destination = destinationTextField.text
        print("Printing destination for saved obs: \(destination!)" )
        //let session = Session(observerName: observerName, givenDate: date)
        
        observation = Observation(session: session!, time: time!, driverName: driverName!, destination: destination!)
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
    @IBAction func dateTextFieldEditing(_ sender: UITextField) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.date
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(handleDatePicker), for: UIControlEvents.valueChanged)
    }
    
    @objc func handleDatePicker(sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateTextField.text = dateFormatter.string(from: sender.date)
    }
    // Make a tool bar for the date picker with an ok button and a done button
    func createDatePicker(){//textField: UITextField) {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(ObservationViewController.dateDonePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        toolBar.setItems([flexSpace, doneButton, flexSpace], animated: true)
        
        // Make sure this is added to the controller when textFieldEditing is called
        dateTextField.inputAccessoryView = toolBar
    }
    
    // Check that the done button on custom DatePicker was pressed
    @objc func dateDonePressed(sender: UIBarButtonItem) {
        dateTextField.resignFirstResponder()
    }
    
    @IBAction func timeTextFieldEditing(_ sender: UITextField) {
        let timePickerView: UIDatePicker = UIDatePicker()
        timePickerView.datePickerMode = UIDatePickerMode.time
        sender.inputView = timePickerView
        timePickerView.addTarget(self, action: #selector(handleTimePicker), for: UIControlEvents.valueChanged)
    }
    
    @objc func handleTimePicker(sender: UIDatePicker) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        timeTextField.text = timeFormatter.string(from: sender.date)
    }
    
    func createTimePicker(){//textField: UITextField) {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(ObservationViewController.timeDonePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        toolBar.setItems([flexSpace, doneButton, flexSpace], animated: true)
        
        // Make sure this is added to the controller when openTimeTextFieldEditing is called
        timeTextField.inputAccessoryView = toolBar
    }
    
    // Check that the done button on custom DatePicker was pressed
    @objc func timeDonePressed(sender: UIBarButtonItem) {
        timeTextField.resignFirstResponder()
    }
}
