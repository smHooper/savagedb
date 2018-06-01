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

class BaseObservationViewController: UIViewController, UITextFieldDelegate {//}, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Properties
    var observerNameTextField = DropDownTextField()
    var dateTextField = UITextField()
    var timeTextField = UITextField()
    var driverNameTextField = UITextField()
    var destinationTextField = DropDownTextField()
    var nPassengersTextField = UITextField()
    var commentsTextField = UITextField()
    
    
    var textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                        (label: "Date",          placeholder: "Select the observation date", type: "normal"),
                        (label: "Time",          placeholder: "Select the observation time", type: "normal"),
                        (label: "Driver's name", placeholder: "Enter the driver's last name", type: "normal"),
                        (label: "Destination",   placeholder: "Select or enter the destination", type: "normal"),
                        (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "normal"),
                        (label: "Comments",      placeholder: "Enter any additional comments (optional)", type: "normal")
    ]
    var textFields = [Int: UITextField]()
    var dropDownTextFields = [Int: DropDownTextField]()
    var labels = [UILabel]()
    let tableView = UITableView(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
    
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
    let observationsTable = Table("observations")
    
    // session DB properties
    let sessionsTable = Table("sessions")
    let openTimeColumn = Expression<String>("openTime")
    let closeTimeColumn = Expression<String>("closeTime")
    
    // dropdown menu options
    let destinationOptions = ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]
    let observerOptions = ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"]
    let dropDownMenuOptions = ["Observer name": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"],
                               "Destination": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"]
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
        
        setupLayout()
        
        /*// Configure custom delegates
        addObserverTextField(menuOptions: self.observerOptions)
        addDestinationTextField(menuOptions: self.destinationOptions)
        createDatePicker()
        createTimePicker()

        guard let observation = observation else {
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
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // If rotated, clear the views and redo the layout. If I don't check for the orientation change,
        //  this will dismiss the keyboard every time a key is pressed
        if UIDevice.current.orientation != deviceOrientation {
            for subview in self.view.subviews {
                subview.removeFromSuperview()
            }
            setupLayout()
        }
        // Reset the orientation
        deviceOrientation = UIDevice.current.orientation
     }
    
    // Set up the text fields in place
    func setupLayout(){
        // Set up the container
        //let container = UIStackView()
        let container = UIView()
        let safeArea = self.view.safeAreaInsets
        self.view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up constrations. Don't set the height constaint until all text fields have been added. This way, the container stackview will always be the extact height of the text fields with spacing.
        container.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        container.topAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.topAnchor, constant: CGFloat(self.topSpacing)).isActive = true
        container.widthAnchor.constraint(equalToConstant: self.view.frame.width - CGFloat(self.sideSpacing * 2) - safeArea.left - safeArea.right).isActive = true
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
            
            
            
            var textField = UITextField()
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
            let stackHeight = label.frame.height + CGFloat(self.sideSpacing) + textField.frame.height
            stack.axis = .vertical
            stack.spacing = CGFloat(self.sideSpacing)
            stack.frame = CGRect(x: safeArea.left, y: 0, width: self.view.frame.size.width - safeArea.right, height: stackHeight)

            //stackViews.append(stack)
            containerHeight += stackHeight + CGFloat(self.textFieldSpacing)
            
            switch(textFieldIds[i].type) {
            case "normal":
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
                print("Dropdown constraints: \(dropDownTextFields[i]!.constraints)")
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
                
                // Set up dropView constraints. If this is in DropDownTextFieldControl.swift, it thows the error 'Unable to activate constraint with anchors <ID of constaint"> and <ID of other constaint> because they have no common ancestor.  Does the constraint or its anchors reference items in different view hierarchies?  That's illegal.'
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
            


        }
        // Now set the height contraint
        container.heightAnchor.constraint(equalToConstant: containerHeight).isActive = true
        
        // ****** If height > area above keyboard, put it in a scroll view *************
        //  Add a flag property to notify the controller that it will or will not need to handle when the keyboard obscures a text field
        //  Then, in editingDidBegin, set the scroll view position so the field is just above the keyboard
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
        print("Cell label text at \(indexPath.row): \(cell.label?.text)")
        
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
    
    
    //MARK: Add dropdown text fields
    //######################################################################################################
    func addObserverTextField(menuOptions: [String]){
        
        //Get the bounds from the storyboard's text field
        let frame = self.view.frame
        let font = UIFont.systemFont(ofSize: 17.0)//observerNameTextField.font
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
        //observerNameTextField.heightAnchor.constraint(equalToConstant: templateObserverField.frame.size.height).isActive = true//*/
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(updateObservation), name: Notification.Name("dropDownPressed:observer"), object: nil)//.addObserver has nothing to do with the "Observation" class
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
        //destinationTextField.heightAnchor.constraint(equalToConstant: templateDestinationField.frame.size.height).isActive = true//*/
        
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


