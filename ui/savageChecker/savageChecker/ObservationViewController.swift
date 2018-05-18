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
    
    @IBOutlet weak var observerNameTextField: DropDownTextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var driverNameTextField: UITextField!
    @IBOutlet weak var destinationTextField: DropDownTextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var observation: Observation?
    let destinationOptions = ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]
    let observerOptions = ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure custom delegates
        addObserverTextField(menuOptions: self.observerOptions)
        addDestinationTextField(menuOptions: self.destinationOptions)
        createDatePicker()
        createTimePicker()
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Add dropdown text fields
    //######################################################################################################
    func addObserverTextField(menuOptions: [String]){
        
        //Get the bounds from the storyboard's text field
        let frame = observerNameTextField.frame
        let font = observerNameTextField.font
        let centerX = observerNameTextField.centerXAnchor
        let centerY = observerNameTextField.centerYAnchor
        
        //Configure the text field
        observerNameTextField = DropDownTextField.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        observerNameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        //Add Button to the View Controller
        self.view.addSubview(observerNameTextField)
        
        //button Constraints
        //observerTextField.frame = CGRect(x: 0, y: 0, width: textFieldBounds.width, height: textFieldBounds.height)
        observerNameTextField.font = font
        observerNameTextField.centerXAnchor.constraint(equalTo: centerX).isActive = true
        observerNameTextField.centerYAnchor.constraint(equalTo: centerY).isActive = true
        observerNameTextField.widthAnchor.constraint(equalToConstant: frame.width).isActive = true
        observerNameTextField.heightAnchor.constraint(equalToConstant: frame.height).isActive = true//*/
        observerNameTextField.placeholder = "Select or enter observer name"
        
        //Set the drop down menu's options
        observerNameTextField.dropView.dropDownOptions = menuOptions//
        
        //observerNameTextField.delegate = self
        
        // Set up dropView constraints. If this is in DropDownTextFieldControl.swift, it thows the error 'Unable to activate constraint with anchors <ID of constaint"> and <ID of other constaint> because they have no common ancestor.  Does the constraint or its anchors reference items in different view hierarchies?  That's illegal.'
        observerNameTextField.superview?.addSubview(observerNameTextField.dropView)
        observerNameTextField.superview?.bringSubview(toFront: observerNameTextField.dropView)
        observerNameTextField.dropView.topAnchor.constraint(equalTo: observerNameTextField.bottomAnchor).isActive = true
        observerNameTextField.dropView.centerXAnchor.constraint(equalTo: observerNameTextField.centerXAnchor).isActive = true
        observerNameTextField.dropView.widthAnchor.constraint(equalTo: observerNameTextField.widthAnchor).isActive = true
        observerNameTextField.height = observerNameTextField.dropView.heightAnchor.constraint(equalToConstant: 0)
    }

    func addDestinationTextField(menuOptions: [String]){
        
        //Get the bounds from the storyboard's text field
        let frame = destinationTextField.frame
        let font = destinationTextField.font
        let centerX = destinationTextField.centerXAnchor
        let centerY = destinationTextField.centerYAnchor
        
        //Configure the text field
        destinationTextField = DropDownTextField.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        destinationTextField.translatesAutoresizingMaskIntoConstraints = false
        
        //Add Button to the View Controller
        self.view.addSubview(destinationTextField)
        
        //button Constraints
        //observerTextField.frame = CGRect(x: 0, y: 0, width: textFieldBounds.width, height: textFieldBounds.height)
        destinationTextField.font = font
        destinationTextField.centerXAnchor.constraint(equalTo: centerX).isActive = true
        destinationTextField.centerYAnchor.constraint(equalTo: centerY).isActive = true
        destinationTextField.widthAnchor.constraint(equalToConstant: frame.width).isActive = true
        destinationTextField.heightAnchor.constraint(equalToConstant: frame.height).isActive = true//*/
        destinationTextField.placeholder = "Select or enter destination"
        
        //Set the drop down menu's options
        destinationTextField.dropView.dropDownOptions = menuOptions//
        
        //destinationTextField.delegate = self
        
        // Set up dropView constraints. If this is in DropDownTextFieldControl.swift, it thows the error 'Unable to activate constraint with anchors <ID of constaint"> and <ID of other constaint> because they have no common ancestor.  Does the constraint or its anchors reference items in different view hierarchies?  That's illegal.'
        destinationTextField.superview?.addSubview(destinationTextField.dropView)
        destinationTextField.superview?.bringSubview(toFront: destinationTextField.dropView)
        destinationTextField.dropView.topAnchor.constraint(equalTo: destinationTextField.bottomAnchor).isActive = true
        destinationTextField.dropView.centerXAnchor.constraint(equalTo: destinationTextField.centerXAnchor).isActive = true
        destinationTextField.dropView.widthAnchor.constraint(equalTo: destinationTextField.widthAnchor).isActive = true
        destinationTextField.height = destinationTextField.dropView.heightAnchor.constraint(equalToConstant: 0)
    }
    
    
    // MARK: - Navigation
    //#######################################################################
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways
        let isAddingObservation = presentingViewController is UINavigationController
        
        if isAddingObservation {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController {
            owningNavigationController.popViewController(animated: true)
            
        }
        else {
            fatalError("The ObservationViewController is not inside a navigation controller")
        }
    }
    
    
    // Configure tableview controller before it's presented
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
        
        // Figure out why app fails at this point sometimes
        observation = Observation(session: session!, time: time!, driverName: driverName!, destination: destination!)
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
        // Set the default date to today
        if (timeTextField.text?.isEmpty)! {
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            dateTextField.text = formatter.string(from: now)
        }
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
        // Set the default time to now
        if (timeTextField.text?.isEmpty)! {
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            timeTextField.text = formatter.string(from: now)
        }
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
