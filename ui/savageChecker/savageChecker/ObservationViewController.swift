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
        /*do {
            db = try SQLiteDatabase.open(path: SQLiteDatabase.path)
            print("Successfully opened connection to database.")
        } catch SQLiteError.OpenDatabase(let message) {
            fatalError("Unable to establish database connection")
        } catch let error {
            fatalError(error.localizedDescription)
        }*/
        
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
        }
        // This is a new observation. Try to load the session from disk and fill in text fields
        else {
            // This shouldn't fail because the session should have been saved at the Session scene.
            self.session = NSKeyedUnarchiver.unarchiveObject(withFile: Session.ArchiveURL.path) as? Session
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
        let centerX = observerNameTextField.centerXAnchor
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
        let centerX = destinationTextField.centerXAnchor
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

        let time = timeTextField.text
        let driverName = driverNameTextField.text
        let destination = destinationTextField.text
        let nPassengers = nPassengersTextField.text
        // Can force unwrap all text fields because saveButton in inactive until all are filled
        let thisSession = Session(observerName: observerNameTextField.text!, openTime: "12:00 AM", closeTime: "11:59 PM", givenDate: dateTextField.text!)
        observation = Observation(session: thisSession!, id: -1, time: time!, driverName: driverName!, destination: destination!, nPassengers: nPassengers!)
        
        //Update the database
        if isAddingNewObservation {
            insertObservation()
        } else {
              // some update logic
            }
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
    @objc private func updateObservation(){
        // Check that all text fields are filled in
        let observerName = observerNameTextField.text ?? ""
        let date = dateTextField.text ?? ""
        let time = timeTextField.text ?? ""
        let driverName = driverNameTextField.text ?? ""
        let destination = destinationTextField.text ?? ""
        let nPassengers = nPassengersTextField.text ?? ""
        print(nPassengers.isEmpty)
        if !observerName.isEmpty && !date.isEmpty && !date.isEmpty && !time.isEmpty && !driverName.isEmpty && !destination.isEmpty && !nPassengers.isEmpty {
            //self.session = Observation(observerName: observerName, openTime: openTime, closeTime: closeTime, givenDate: date)
            saveButton.isEnabled = true
        }
    }
    
    private func insertObservation() {
        print("adding record to DB")
        // Can just get text values from the observation because it has to be updated before saveButton is enabled
        let observerName = observation?.observerName
        let date = observation?.date
        let time = observation?.time
        let driverName = observation?.driverName
        let destination = observation?.destination
        let nPassengers = observation?.nPassengers
        
        do {
            let rowid = try db.run(observationsTable.insert(observerNameColumn <- observerName!,
                                                            dateColumn <- date!,
                                                            timeColumn <- time!,
                                                            driverNameColumn <- driverName!,
                                                            destinationColumn <- destination!,
                                                            nPassengersColumn <- nPassengers!))
            print("inserted id: \(rowid)")
        } catch {
            print("insertion failed: \(error)")
        }
        /*//the insert query
        //"INSERT INTO Contact (Id, Name) VALUES (?, ?);"
        let sql = "INSERT INTO observations (observerName, date, time, driverName, destination, nPassengers) VALUES (?, ?, ?, ?, ?, ?);"
        
        //preparing the query
        let statement = try db.prepareStatement(sql: sql)
        
        //binding the parameters
        //print("should be index of observer: \(sqlite3_bind_parameter_name(statement, 1))")
        guard sqlite3_bind_text(statement, 1, observerName, -1, nil) == SQLITE_OK else {
            let errmsg = String(cString: sqlite3_errmsg(db.dbPointer)!)
            print("error binding observerName: \(errmsg)")
            throw SQLiteError.Bind(message: db.errorMessage)
        }
        //print("index of observer: \(sqlite3_bind_parameter_index(statement, "date"))")
        guard sqlite3_bind_text(statement, 2, date, -1, nil) == SQLITE_OK else{
            let errmsg = String(cString: sqlite3_errmsg(db.dbPointer)!)
            print("error binding date: \(errmsg)")
            throw SQLiteError.Bind(message: db.errorMessage)
        }
        //print("index of observer: \(sqlite3_bind_parameter_index(statement, "time"))")
        guard sqlite3_bind_text(statement, 3, time, -1, nil) == SQLITE_OK else{
            let errmsg = String(cString: sqlite3_errmsg(db.dbPointer)!)
            print("error binding time: \(errmsg)")
            throw SQLiteError.Bind(message: db.errorMessage)
        }
        //print("index of observer: \(sqlite3_bind_parameter_index(statement, "driverName"))")
        guard sqlite3_bind_text(statement, 4, driverName, -1, nil) == SQLITE_OK else{
            let errmsg = String(cString: sqlite3_errmsg(db.dbPointer)!)
            print("error binding driverName: \(errmsg)")
            throw SQLiteError.Bind(message: db.errorMessage)
        }
        //print("index of observer: \(sqlite3_bind_parameter_index(statement, "destination"))")
        guard sqlite3_bind_text(statement, 5, destination, -1, nil) == SQLITE_OK else{
            let errmsg = String(cString: sqlite3_errmsg(db.dbPointer)!)
            print("error binding destination: \(errmsg)")
            throw SQLiteError.Bind(message: db.errorMessage)
        }
        //print("index of observer: \(sqlite3_bind_parameter_index(statement, "nPassengers"))")
        guard sqlite3_bind_text(statement, 6, nPassengers, -1, nil) == SQLITE_OK else{
            let errmsg = String(cString: sqlite3_errmsg(db.dbPointer)!)
            print("error binding nPass: \(errmsg)")
            throw SQLiteError.Bind(message: db.errorMessage)
        }
        
        //executing the query to insert values
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errmsg = String(cString: sqlite3_errmsg(db.dbPointer)!)
            print("error creating table: \(errmsg)")
            throw SQLiteError.Step(message: db.errorMessage)
        }
        print(SQLiteDatabase.path)*/
        
        
    }
}
