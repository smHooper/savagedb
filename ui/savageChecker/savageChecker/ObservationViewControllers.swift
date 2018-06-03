//
//  ObservationViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/31/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import SQLite
import os.log

class BaseObservationViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate {//}, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Properties
    var observerNameTextField = DropDownTextField()
    var dateTextField = UITextField()
    var timeTextField = UITextField()
    var driverNameTextField = UITextField()
    var destinationTextField = DropDownTextField()
    var nPassengersTextField = UITextField()
    var commentsTextField = UITextField()
    
    
    var textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                        (label: "Date",          placeholder: "Select the observation date", type: "date"),
                        (label: "Time",          placeholder: "Select the observation time", type: "time"),
                        (label: "Driver's name", placeholder: "Enter the driver's last name", type: "normal"),
                        (label: "Destination",   placeholder: "Select or enter the destination", type: "dropDown"),
                        (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number")]//,
                        /*(label: "Comments",      placeholder: "Enter any additional comments (optional)", type: "normal"),
                        (label: "Observer nam", placeholder: "Select or enter the observer's name", type: "normal"),
                        (label: "Observer na", placeholder: "Select or enter the observer's name", type: "normal"),
                        (label: "Observer n", placeholder: "Select or enter the observer's name", type: "normal"),
                        (label: "Observer ", placeholder: "Select or enter the observer's name", type: "normal"),
                        (label: "Observer", placeholder: "Select or enter the observer's name", type: "normal")
    ]*/
    var textFields = [Int: UITextField]()
    var dropDownTextFields = [Int: DropDownTextField]()
    var labels = [UILabel]()
    let tableView = UITableView(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
    
    var navigationBar: CustomNavigationBar!
    var saveButton: UIBarButtonItem!
    
    var db: Connection!// SQLiteDatabase!
    var observation: Observation?
    var session: Session?
    var isAddingNewObservation: Bool!
    
    // layout properties
    let topSpacing = 40.0
    let sideSpacing: CGFloat = 8.0
    let textFieldSpacing: CGFloat = 30.0
    var deviceOrientation = UIDevice.current.orientation
    
    // observation DB columns
    let idColumn = Expression<Int64>("id")
    let observerNameColumn = Expression<String>("observerName")
    let dateColumn = Expression<String>("date")
    let timeColumn = Expression<String>("time")
    let driverNameColumn = Expression<String>("driverName")
    let destinationColumn = Expression<String>("destination")
    let nPassengersColumn = Expression<String>("nPassengers")
    let commentsColumn = Expression<String>("comments")
    var dbColumns = [Expression<String>("observerName"),
                   Expression<String>("date"),
                   Expression<String>("time"),
                   Expression<String>("driverName"),
                   Expression<String>("destination"),
                   Expression<String>("nPassengers"),
                   Expression<String>("comments")]
    let observationsTable = Table("observations")
    
    // session DB properties
    let sessionsTable = Table("sessions")
    let openTimeColumn = Expression<String>("openTime")
    let closeTimeColumn = Expression<String>("closeTime")
    
    // dropdown menu options
    let destinationOptions = ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]
    let observerOptions = ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"]
    let dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                               "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]
    ]
    
    
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
        //self.session = NSKeyedUnarchiver.unarchiveObject(withFile: Session.ArchiveURL.path) as? Session
        do {
            try loadSession()
        } catch {
            fatalError(error.localizedDescription)
        }
        self.setNavigationBar()
        self.setupLayout()
        self.view.backgroundColor = UIColor.white
        /*let safeArea = self.view.safeAreaInsets
        for i in 0..<textFieldIds.count{
            let textField = UITextField()
            switch(textFieldIds[i].type){
            case "normal":
                textField.placeholder = textFieldIds[i].placeholder
                textField.borderStyle = .roundedRect
                textField.layer.borderColor = UIColor.lightGray.cgColor
                textField.layer.borderWidth = 0.25
                textField.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
                textField.font = UIFont.systemFont(ofSize: 14.0)
                textField.layer.cornerRadius = 5
                textField.frame.size.height = 28.5
                textField.frame = CGRect(x: safeArea.left, y: 0, width: self.view.frame.size.width - safeArea.right, height: 28.5)
                textField.tag = i
            default:
                fatalError("Did not understand text field type: \(textFieldIds[i])")
            }
            textFields.append(textField)
            
        }
        // Lay out all text fields
        self.view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true*/
        

        /*guard let observation = observation else {
            fatalError("No valid observation passed from TableViewController")
        }
        // The observation already exists and is open for viewing/editing
        if isAddingNewObservation {
            observerNameTextField.text = session?.observerName
            dateTextField.text = session?.date
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            timeTextField.text = formatter.string(from: now)
            saveButton.isEnabled = false
        } else {
            observerNameTextField.text = observation.observerName
            dateTextField.text = observation.date
            timeTextField.text = observation.time
            driverNameTextField.text = observation.driverName
            destinationTextField.text = observation.destination
            nPassengersTextField.text = observation.nPassengers
            commentsTextField.text = observation.comments
        }*/
        
    }
    
    // On rotation, recalculate positions of fields
    /*override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // If rotated, clear the views and redo the layout. If I don't check for the orientation change,
        //  this will dismiss the keyboard every time a key is pressed. self.deviceOrientation starts
        //  out with .rawValue == 0 (after loading it changes), so check that this isn't the first load
        if UIDevice.current.orientation != deviceOrientation && self.deviceOrientation.rawValue != 0 {
            // Clear views
            // Get textfield values
            /*var fieldValues = [String]()
            for index in 0..<self.textFieldIds.count {
                if self.textFields.keys.contains(index){
                    fieldValues
                }
            }*/
            
            for subview in self.view.subviews {
                subview.removeFromSuperview()
            }
            // Redo layout
            setupLayout()
        }
        // Reset the orientation
        self.deviceOrientation = UIDevice.current.orientation
     }*/
    
    // Set up the text fields in place
    func setupLayout(){
        // Set up the container
        //let container = UIStackView()
        let safeArea = self.view.safeAreaInsets
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        //scrollView.bounces = false
        
        self.view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor, constant: CGFloat(self.topSpacing)).isActive = true
        scrollView.widthAnchor.constraint(equalToConstant: self.view.frame.width - CGFloat(self.sideSpacing * 2) - safeArea.left - safeArea.right).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        //scrollView.addSubview(container)
        
        let container = UIView()
        scrollView.addSubview(container)
        
        // Set up constrations. Don't set the height constaint until all text fields have been added. This way, the container stackview will always be the extact height of the text fields with spacing.
        container.translatesAutoresizingMaskIntoConstraints = false
        container.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        container.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        container.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        container.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        /*container.axis = .vertical
        container.spacing = CGFloat(self.textFieldSpacing)
        container.alignment = .fill
        container.distribution = .equalCentering*/
        
        var containerHeight = CGFloat(0.0)
        var lastBottomAnchor = container.topAnchor
        for i in 0..<textFieldIds.count {
            // Combine the label and the textField in a vertical stack view
            let label = UILabel()
            let thisLabelText = textFieldIds[i].label
            let font = UIFont.systemFont(ofSize: 17.0)
            let labelWidth = thisLabelText.width(withConstrainedHeight: 28.5, font: font)
            label.text = thisLabelText
            label.font = font
            //label.frame = CGRect(x: safeArea.left, y: 0, width: labelWidth, height: 28.5)
            //container.addSubview(label)
            labels.append(label)
            container.addSubview(labels[i])
            labels[i].translatesAutoresizingMaskIntoConstraints = false
            labels[i].leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
            if lastBottomAnchor == container.topAnchor {
                labels[i].topAnchor.constraint(equalTo: lastBottomAnchor).isActive = true
            } else {
                labels[i].topAnchor.constraint(equalTo: lastBottomAnchor, constant: self.textFieldSpacing).isActive = true
            }
            
            
            
            let textField = UITextField()
            textField.placeholder = textFieldIds[i].placeholder
            textField.borderStyle = .roundedRect
            textField.layer.borderColor = UIColor.lightGray.cgColor
            textField.layer.borderWidth = 0.25
            textField.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
            textField.font = UIFont.systemFont(ofSize: 14.0)
            textField.layer.cornerRadius = 5
            textField.frame.size.height = 28.5
            textField.frame = CGRect(x: safeArea.left, y: 0, width: self.view.frame.size.width - safeArea.right, height: 28.5)
            textField.tag = i
            textField.delegate = self
            //textFields.append(textField)
            
            let stack = UIStackView()
            //let stackHeight = label.frame.height + CGFloat(self.sideSpacing) + textFields[i].frame.height
            let stackHeight = (label.text?.height(withConstrainedWidth: labelWidth, font: label.font))! + CGFloat(self.sideSpacing) + textField.frame.height
            stack.axis = .vertical
            stack.spacing = CGFloat(self.sideSpacing)
            stack.frame = CGRect(x: safeArea.left, y: 0, width: self.view.frame.size.width - safeArea.right, height: stackHeight)

            //stackViews.append(stack)
            containerHeight += stackHeight + CGFloat(self.textFieldSpacing)

            switch(textFieldIds[i].type) {
            case "normal", "date", "time", "number":
                // Don't do anything special
                //textFields.append(textField)
                textFields[i] = textField
                container.addSubview(textFields[i]!)
                textFields[i]?.translatesAutoresizingMaskIntoConstraints = false
                textFields[i]?.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
                textFields[i]?.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
                textFields[i]?.topAnchor.constraint(equalTo: labels[i].bottomAnchor, constant: self.sideSpacing).isActive = true
                lastBottomAnchor = (textFields[i]?.bottomAnchor)!
                //stack.addArrangedSubview(label)
                //stack.addArrangedSubview(textFields[i]!)
                //container.addArrangedSubview(stack)
            case "dropDown":
                //Get the bounds from the storyboard's text field
                //let frame = self.view.frame
                //let centerX = observerNameTextField.centerXAnchor
                //let centerY = observerNameTextField.centerYAnchor
                
                // re-configure the text field
                //textFields.append(DropDownTextField.init(frame: textField.frame))
                dropDownTextFields[i] = DropDownTextField.init(frame: textField.frame)
                dropDownTextFields[i]!.placeholder = textFieldIds[i].placeholder
                dropDownTextFields[i]!.borderStyle = .roundedRect
                dropDownTextFields[i]!.layer.borderColor = UIColor.lightGray.cgColor
                dropDownTextFields[i]!.layer.borderWidth = 0.25
                dropDownTextFields[i]!.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
                dropDownTextFields[i]!.font = UIFont.systemFont(ofSize: 14.0)
                dropDownTextFields[i]!.layer.cornerRadius = 5
                dropDownTextFields[i]!.frame.size.height = 28.5
                dropDownTextFields[i]!.tag = i
                dropDownTextFields[i]!.delegate = self
                
                // Set constraints
                container.addSubview(dropDownTextFields[i]!)
                dropDownTextFields[i]!.translatesAutoresizingMaskIntoConstraints = false
                dropDownTextFields[i]!.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
                dropDownTextFields[i]!.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
                dropDownTextFields[i]!.topAnchor.constraint(equalTo: labels[i].bottomAnchor, constant: self.sideSpacing).isActive = true
                lastBottomAnchor = dropDownTextFields[i]!.bottomAnchor
                
                //stack.addArrangedSubview(label)
                //stack.addArrangedSubview(dropDownTextFields[i]!)
                //container.addArrangedSubview(stack)
                //textField.translatesAutoresizingMaskIntoConstraints = false
                
                //Add Button to the View Controller
                //self.view.addSubview(observerNameTextField)
                
                //button Constraints
                //observerTextField.frame = CGRect(x: 0, y: 0, width: textFieldBounds.width, height: textFieldBounds.height)
                
                /*observerNameTextField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16).isActive = true
                observerNameTextField.centerYAnchor.constraint(equalTo: centerY).isActive = true
                observerNameTextField.widthAnchor.constraint(equalToConstant: frame.size.width - 24).isActive = true
                //observerNameTextField.heightAnchor.constraint(equalToConstant: templateObserverField.frame.size.height).isActive = true*/
                
                //Set the drop down menu's options
                dropDownTextFields[i]!.dropView.dropDownOptions = dropDownMenuOptions[textFieldIds[i].label]!
                
                // Set up dropView constraints. If this is in DropDownTextField, it thows the error 'Unable to activate constraint with anchors <ID of constaint"> and <ID of other constaint> because they have no common ancestor.  Does the constraint or its anchors reference items in different view hierarchies?  That's illegal.'
                self.view.addSubview(dropDownTextFields[i]!.dropView)
                self.view.bringSubview(toFront: dropDownTextFields[i]!.dropView)
                dropDownTextFields[i]!.dropView.leftAnchor.constraint(equalTo: dropDownTextFields[i]!.leftAnchor).isActive = true
                dropDownTextFields[i]!.dropView.rightAnchor.constraint(equalTo: dropDownTextFields[i]!.rightAnchor).isActive = true
                dropDownTextFields[i]!.dropView.topAnchor.constraint(equalTo: dropDownTextFields[i]!.bottomAnchor).isActive = true
                dropDownTextFields[i]!.height = dropDownTextFields[i]!.dropView.heightAnchor.constraint(equalToConstant: 0)

                //observerNameTextField.height = observerNameTextField.dropView.heightAnchor.constraint(equalToConstant: 0)*/
                
                // Add listener for notification from DropDownTextField.dropDownPressed()
                dropDownTextFields[i]?.dropDownID = textFieldIds[i].label
                NotificationCenter.default.addObserver(self, selector: #selector(updateObservation), name: Notification.Name("dropDownPressed:\(textFieldIds[i].label)"), object: nil)//.addObserver has nothing to do with the "Observation" class
            default:
                fatalError("Text field type not understood")
            }
            
            // Set up custom keyboards
            switch(textFieldIds[i].type) {
            case "time", "date":
                createDatetimePicker(textField: textFields[i]!)
            case "number":
                textFields[i]!.keyboardType = .numberPad
            default:
                let _ = 0
            }
        }
        // Now set the height contraint
        print(containerHeight)
        //container.heightAnchor.constraint(equalToConstant: containerHeight).isActive = true
        //container.heightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.heightAnchor).isActive = true
        scrollView.contentSize = self.view.frame.size//CGSize(width: container.frame.size.width, height: containerHeight)
        // ****** If height > area above keyboard, put it in a scroll view *************
        //  Add a flag property to notify the controller that it will or will not need to handle when the keyboard obscures a text field
        //  Then, in editingDidBegin, set the scroll view position so the field is just above the keyboard
        
    }
    
    // MARK: Scrollview Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
    }
    
    
    //MARK: Tableview methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textFields.count
    }
    
    // Configure the cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = TextFieldCell()
        
        let label = UILabel()
        label.text = textFieldIds[indexPath.row].label
        label.font = UIFont.systemFont(ofSize: 17.0)
        label.textAlignment = .left
        cell.label = label
        //print(textFields[0].placeholder)
        //print("Cell label text at \(indexPath.row): \(cell.label?.text)")
        
        cell.textField = textFields[indexPath.row]
        cell.backgroundColor = UIColor.clear
        cell.layer.borderColor = UIColor.clear.cgColor
        
        cell.addSubview(cell.label!)
        cell.addSubview(cell.textField!)

        return cell
    }
    
    
    /*func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(textFieldIds[indexPath.row])
    }*/
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: UITextFieldDelegate
    //######################################################################
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let fieldType = textFieldIds[textField.tag].type
        switch(fieldType){
        case "normal", "number":
            //print("textField is \(fieldType)")
            let _ = 0
        case "dropDown":
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
        case "time", "date":
            setupDatetimePicker(textField)
        default:
            print("didn't understand text field type: \(fieldType)")
        }
        
    }
    
    // Hide the keyboard when the return button is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // When finished editing, check if the observation should be updated
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateObservation()
    }
    
    // MARK: - Navigation
    //#######################################################################
    func setNavigationBar() {
        let screenSize: CGRect = UIScreen.main.bounds
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        self.navigationBar = CustomNavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: screenSize.width, height: 44))
        //self.navigationBar.size
        let navItem = UINavigationItem(title: "New Vehicle")
        self.saveButton = UIBarButtonItem(title: "Save", style: .plain, target: nil, action: #selector(save))//(barButtonSystemItem: self.saveButton, target: nil, action: #selector(save))
        //self.saveButton = "Save"
        navItem.rightBarButtonItem = self.saveButton
        self.navigationBar.setItems([navItem], animated: false)
        self.view.addSubview(self.navigationBar)
    }
    
    @objc func save() {
        print("save")
    }
    
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

    
    // MARK: Add a custom datepicker to each of the datetime fields
    // #####################################################################################################################
    
    // Check that the done button on custom DatePicker was pressed
    @objc func dateDonePressed(sender: UIBarButtonItem) {
        dateTextField.resignFirstResponder()
    }
    
    // Called when text a text field with type == "date" || "time"
    func setupDatetimePicker(_ sender: UITextField) {
        let datetimePickerView: UIDatePicker = UIDatePicker()
        let fieldType = textFieldIds[sender.tag].type
        
        // Use the current time if one has not been set yet
        let now = Date()
        let formatter = DateFormatter()
        
        // Check if this is a time or date field
        switch(fieldType){
        case "time":
            datetimePickerView.datePickerMode = UIDatePickerMode.time
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        case "date":
            datetimePickerView.datePickerMode = UIDatePickerMode.date
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        default:
            fatalError("textfield \(sender.tag) passed to setupDatetimePicker was of type \(fieldType)")
        }
        
        sender.inputView = datetimePickerView
        datetimePickerView.addTarget(self, action: #selector(handleTimePicker), for: UIControlEvents.valueChanged)
        datetimePickerView.tag = sender.tag
        print("Time text field tag in timeTextFieldEditing: \(sender.tag)")
        
        // Set the default time to now
        if (sender.text?.isEmpty)! {
            sender.text = formatter.string(from: now)
        }
    }
    
    @objc func handleTimePicker(sender: UIDatePicker) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: sender.date)
        let dictionary: [Int: String] = [sender.tag: timeString]
        NotificationCenter.default.post(name: Notification.Name("dateTimePicked:\(sender.tag)"), object: dictionary)
        updateObservation()
    }
    
    func createDatetimePicker(textField: UITextField) {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(BaseObservationViewController.datetimeDonePressed))
        doneButton.tag = textField.tag
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        toolBar.setItems([flexSpace, doneButton, flexSpace], animated: true)
        
        // Make sure this is added to the controller when setupDatetimePicker() is called
        textField.inputAccessoryView = toolBar
        
        // Add a notification to retrieve the value from the datepicker
        NotificationCenter.default.addObserver(self, selector: #selector(updateDatetimeField(notification:)), name: Notification.Name("dateTimePicked:\(textField.tag)"), object: nil)
    }
    
    @objc func updateDatetimeField(notification: Notification){
        guard let datetimeDictionary = notification.object as? Dictionary<Int, String> else {
            fatalError("Couldn't downcast dateTimeDict: \(notification.object!)")
        }
        let index = datetimeDictionary.keys.first!
        let datetime = datetimeDictionary.values.first!
        textFields[index]?.text = datetime
    }
    
    // Check that the done button on custom DatePicker was pressed
    @objc func datetimeDonePressed(sender: UIBarButtonItem) {
        textFields[sender.tag]?.resignFirstResponder()
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
        } catch {
            print("insertion failed: \(error)")
        }
    }
    
    private func loadSession() throws { //}-> Session?{
        // ************* check that the table exists first **********************
        let rows = Array(try db.prepare(sessionsTable))
        if rows.count > 1 {
            fatalError("Multiple sessions found")
        }
        for row in rows{
            self.session = Session(id: Int(row[idColumn]), observerName: row[observerNameColumn], openTime:row[openTimeColumn], closeTime: row[closeTimeColumn], givenDate: row[dateColumn])
        }
        print("loaded all session")
    }
}

// Custom Navigation Bar simply to be able to change the height. Apparently in iOS 11, there is no other way to do this.
class CustomNavigationBar: UINavigationBar {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // For each subviews (i.e., components of the nav bar) resize and reposition it
        for subview in self.subviews {
            let stringFromClass = NSStringFromClass(subview.classForCoder)
            if stringFromClass.contains("BarBackground") {
                let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
                subview.frame.origin.y -= statusBarHeight
                subview.frame.size.height += statusBarHeight
            }
        }
    }
}
