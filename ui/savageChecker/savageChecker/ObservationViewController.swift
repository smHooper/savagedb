//
//  ObservationViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
//import SQLite3
import SQLite
import os.log

class ObservationViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    
    @IBOutlet weak var observerNameTextField: DropDownTextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var driverNameTextField: UITextField!
    @IBOutlet weak var destinationTextField: DropDownTextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var templateObserverField: UITextField!
    @IBOutlet weak var templateDestinationField: DropDownTextField!
    @IBOutlet weak var nPassengersTextField: UITextField!
    @IBOutlet weak var commentsTextField: UITextField!
    
    var db: Connection!// SQLiteDatabase!
    var observation: Observation?
    var session: Session?
    var isAddingNewObservation: Bool!
    
    // DB columns
    let idColumn = Expression<Int64>("id")
    let observerNameColumn = Expression<String>("observerName")
    let dateColumn = Expression<String>("date")
    let timeColumn = Expression<String>("time")
    let driverNameColumn = Expression<String>("driverName")
    let destinationColumn = Expression<String>("destination")
    let nPassengersColumn = Expression<String>("nPassengers")
    let commentsColumn = Expression<String>("comments")
    
    let observationsTable = Table("observations")
    let destinationOptions = ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]
    let observerOptions = ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        // Open connection to the DB
        do {
            db = try Connection(dbPath)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        //Load the session
        // This shouldn't fail because the session should have been saved at the Session scene.
        self.session = NSKeyedUnarchiver.unarchiveObject(withFile: Session.ArchiveURL.path) as? Session
        
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
        nPassengersTextField.delegate = self
        commentsTextField.delegate = self
        
        guard let observation = observation else {
            fatalError("No valid observation passed from TableViewController")
        }
        // The observation already exists and is open for viewing/editing
        if !observation.driverName.isEmpty {
            print("loaded observation")
            observerNameTextField.text = observation.observerName
            dateTextField.text = observation.date
            timeTextField.text = observation.time
            driverNameTextField.text = observation.driverName
            destinationTextField.text = observation.destination
            nPassengersTextField.text = observation.nPassengers
            commentsTextField.text = observation.comments
        }
        // This is a new observation. Try to fill in text fields
        else {
            observerNameTextField.text = session?.observerName
            dateTextField.text = session?.date
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            timeTextField.text = formatter.string(from: now)
            saveButton.isEnabled = false
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
        let frame = self.view.frame
        let font = observerNameTextField.font
        //let centerX = observerNameTextField.centerXAnchor
        let centerY = observerNameTextField.centerYAnchor
        
        //Configure the text field
        observerNameTextField = DropDownTextField.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        observerNameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        //Add Button to the View Controller
        self.view.addSubview(observerNameTextField)
        
        //button Constraints
        //observerTextField.frame = CGRect(x: 0, y: 0, width: textFieldBounds.width, height: textFieldBounds.height)
        
        observerNameTextField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16).isActive = true
        observerNameTextField.centerYAnchor.constraint(equalTo: centerY).isActive = true
        observerNameTextField.widthAnchor.constraint(equalToConstant: frame.size.width - 24).isActive = true
        observerNameTextField.heightAnchor.constraint(equalToConstant: templateObserverField.frame.size.height).isActive = true//*/
        
        // Configure text
        observerNameTextField.font = font
        observerNameTextField.placeholder = "Select or enter observer name"
        
        //Set the drop down menu's options
        observerNameTextField.dropView.dropDownOptions = menuOptions//
        
        // Set up dropView constraints. If this is in DropDownTextFieldControl.swift, it thows the error 'Unable to activate constraint with anchors <ID of constaint"> and <ID of other constaint> because they have no common ancestor.  Does the constraint or its anchors reference items in different view hierarchies?  That's illegal.'
        observerNameTextField.superview?.addSubview(observerNameTextField.dropView)
        observerNameTextField.superview?.bringSubview(toFront: observerNameTextField.dropView)
        observerNameTextField.dropView.topAnchor.constraint(equalTo: observerNameTextField.bottomAnchor).isActive = true
        observerNameTextField.dropView.centerXAnchor.constraint(equalTo: observerNameTextField.centerXAnchor).isActive = true
        observerNameTextField.dropView.widthAnchor.constraint(equalTo: observerNameTextField.widthAnchor).isActive = true
        observerNameTextField.height = observerNameTextField.dropView.heightAnchor.constraint(equalToConstant: 0)
        
        // Add listener for notification from DropDownTextField.dropDownPressed()
        observerNameTextField.dropDownID = "observer"
        NotificationCenter.default.addObserver(self, selector: #selector(updateObservation), name: Notification.Name("dropDownPressed:observer"), object: nil)
    }

    func addDestinationTextField(menuOptions: [String]){
        
        //Get the bounds from the storyboard's text field
        let frame = self.view.frame
        let font = destinationTextField.font
        //let centerX = destinationTextField.centerXAnchor
        let centerY = destinationTextField.centerYAnchor
        
        //Configure the text field
        destinationTextField = DropDownTextField.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        destinationTextField.translatesAutoresizingMaskIntoConstraints = false
        
        //Add Button to the View Controller
        self.view.addSubview(destinationTextField)
        
        //button Constraints
        //observerTextField.frame = CGRect(x: 0, y: 0, width: textFieldBounds.width, height: textFieldBounds.height)
        destinationTextField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16).isActive = true
        destinationTextField.centerYAnchor.constraint(equalTo: centerY).isActive = true
        destinationTextField.widthAnchor.constraint(equalToConstant: frame.size.width - 24).isActive = true
        destinationTextField.heightAnchor.constraint(equalToConstant: templateDestinationField.frame.size.height).isActive = true//*/
        
        // Configure text
        destinationTextField.font = font
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
        
        destinationTextField.dropDownID = "destination"
        NotificationCenter.default.addObserver(self, selector: #selector(updateObservation), name: Notification.Name("dropDownPressed:destination"), object: nil)
    }
    
    
    //MARK: UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Check to see if the save button should be enabled
        updateObservation()
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
        
        // Force unwrap all text fields because saveButton in inactive until all are filled
        let observerName = observerNameTextField.text!
        let date = dateTextField.text!
        let time = timeTextField.text!
        let driverName = driverNameTextField.text!
        let destination = destinationTextField.text!
        let nPassengers = nPassengersTextField.text!
        let comments = commentsTextField.text!
        
        // Update the Observation instance
        // Temporarily just say the id = -1. The id column is autoincremented anyway, so it doesn't matter.
        self.observation?.observerName = observerName
        self.observation?.date = date
        self.observation?.time = time
        self.observation?.driverName = driverName
        self.observation?.destination = destination
        self.observation?.nPassengers = nPassengers
        self.observation?.comments = comments
        
        // Update the database
        // Add a new record
        if isAddingNewObservation {
            insertObservation()
        // Update an existing record
        } else {
            
            do {
                // Select the record to update
                print("Record id: \((observation?.id.datatypeValue)!)")
                let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
                print(record)
                // Update all fields
                if try db.run(record.update(observerNameColumn <- observerName,
                                            dateColumn <- date,
                                            timeColumn <- time,
                                            driverNameColumn <- driverName,
                                            destinationColumn <- destination,
                                            nPassengersColumn <- nPassengers)) > 0 {
                    print("updated record")
                } else {
                    print("record not found")
                }
            } catch {
                print("Update failed")
            }
        }
        
        // Get the actual id of the insert row and assign it to the observation that was just inserted. Now when the cell in the obsTableView is selected (e.g., for delete()), the right ID will be returned. This is exclusively so that when if an observation is deleted right after it's created, the right ID is given to retreive a record to delete from the DB.
        var max: Int64!
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
        } catch {
            print(error.localizedDescription)
        }
        observation?.id = Int(max)
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
                textField.resignFirstResponder()
            } else {
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
        updateObservation()
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
        updateObservation()
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
    
    
    //MARK: Private methods
    //###############################################################################################
    // Update save button status
    @objc private func updateObservation(){
        // Check that all text fields are filled in
        let observerName = observerNameTextField.text ?? ""
        let date = dateTextField.text ?? ""
        let time = timeTextField.text ?? ""
        let driverName = driverNameTextField.text ?? ""
        let destination = destinationTextField.text ?? ""
        let nPassengers = nPassengersTextField.text ?? ""
        if !observerName.isEmpty && !date.isEmpty && !date.isEmpty && !time.isEmpty && !driverName.isEmpty && !destination.isEmpty && !nPassengers.isEmpty {
            //self.session = Observation(observerName: observerName, openTime: openTime, closeTime: closeTime, givenDate: date)
            saveButton.isEnabled = true
        }
    }
    
    // Add record to DB
    private func insertObservation() {
        // Can just get text values from the observation because it has to be updated before saveButton is enabled
        let observerName = observation?.observerName
        let date = observation?.date
        let time = observation?.time
        let driverName = observation?.driverName
        let destination = observation?.destination
        let nPassengers = observation?.nPassengers
        let comments = observation?.comments
        print(comments!)
        // Insert into DB
        do {
            let rowid = try db.run(observationsTable.insert(observerNameColumn <- observerName!,
                                                            dateColumn <- date!,
                                                            timeColumn <- time!,
                                                            driverNameColumn <- driverName!,
                                                            destinationColumn <- destination!,
                                                            nPassengersColumn <- nPassengers!,
                                                            commentsColumn <- comments!))
            let recordComments = observationsTable.select(commentsColumn).filter(idColumn == rowid)
            print("inserted record: \(recordComments)")
        } catch {
            print("insertion failed: \(error)")
        }
        
        
    }
}
