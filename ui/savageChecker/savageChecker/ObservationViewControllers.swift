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


class BaseFormViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate {//}, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Properties
    //MARK: Textfield layout properties
    var textFieldIds: [(label: String, placeholder: String, type: String)] = []
    var dropDownMenuOptions = Dictionary<String, [String]>()
    var textFields = [Int: UITextField]()
    var dropDownTextFields = [Int: DropDownTextField]()
    var boolSwitches = [Int: UISwitch]()
    var labels = [UILabel]()
    let tableView = UITableView(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
    
    // track when the text field in focus changes with a property observer
    private var currentTextField = 0 {
        willSet {
            // Check to make sure the current text field is not a dropDown. When a dropDownTextField is first pressed, it resigns as first responder (and didEndEditing is called) because the dropDownView takes over (and shouldBeginEditing is called again). This means  currentTextField is changed each time the dropDownTextField is pressed. If we don't exclude dropdowns from the dismissInputView() call, it immediately dismisses the dropdown.
            let currentType = self.textFieldIds[self.currentTextField].type
            if currentType != "dropDown" {
                dismissInputView()
            }
        }
    }
    
    
    var navigationBar: CustomNavigationBar!
    
    var db: Connection!// SQLiteDatabase!
    var session: Session?
    
    
    //MARK: - Layout
    // layout properties
    let topSpacing = 40.0
    let sideSpacing: CGFloat = 8.0
    let textFieldSpacing: CGFloat = 30.0
    var deviceOrientation = UIDevice.current.orientation
    
    var presentTransition: UIViewControllerAnimatedTransitioning?
    var dismissTransition: UIViewControllerAnimatedTransitioning?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        
        // Open connection to the DB
        do {
            db = try Connection(dbPath)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        self.setNavigationBar()
        self.setupLayout()
        self.view.backgroundColor = UIColor.white
        
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
        //scrollView.contentInsetAdjustmentBehavior = .automatic
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
                
                //Set the drop down menu's options
                guard let dropDownOptions = dropDownMenuOptions[textFieldIds[i].label] else {
                    fatalError("Either self.dropDownMenuOptions not set or \(textFieldIds[i].label) is not a key: \(self.dropDownMenuOptions)")
                }
                dropDownTextFields[i]!.dropView.dropDownOptions = dropDownOptions
                
                // Set up dropView constraints. If this is in DropDownTextField, it thows the error 'Unable to activate constraint with anchors <ID of constaint"> and <ID of other constaint> because they have no common ancestor.  Does the constraint or its anchors reference items in different view hierarchies?  That's illegal.'
                self.view.addSubview(dropDownTextFields[i]!.dropView)
                self.view.bringSubview(toFront: dropDownTextFields[i]!.dropView)
                dropDownTextFields[i]!.dropView.leftAnchor.constraint(equalTo: dropDownTextFields[i]!.leftAnchor).isActive = true
                dropDownTextFields[i]!.dropView.rightAnchor.constraint(equalTo: dropDownTextFields[i]!.rightAnchor).isActive = true
                dropDownTextFields[i]!.dropView.topAnchor.constraint(equalTo: dropDownTextFields[i]!.bottomAnchor).isActive = true
                dropDownTextFields[i]!.height = dropDownTextFields[i]!.dropView.heightAnchor.constraint(equalToConstant: 0)
                
                // Add listener for notification from DropDownTextField.dropDownPressed()
                dropDownTextFields[i]?.dropDownID = i//textFieldIds[i].label
                NotificationCenter.default.addObserver(self, selector: #selector(dropDownDidChange(notification:)), name: Notification.Name("dropDownPressed:\(i)"), object: nil)//textFieldIds[i].label)"), object: nil)//.addObserver has nothing to do with the "Observation" class
            
            case "boolSwitch":
                textFields[i] = textField
                textFields[i]?.isEnabled = false
                textFields[i]?.layer.borderColor = UIColor.clear.cgColor
                textFields[i]?.borderStyle = .none
                textFields[i]?.contentVerticalAlignment = .center
                
                boolSwitches[i] = UISwitch()
                boolSwitches[i]?.tag = i
                boolSwitches[i]?.isOn = false
                
                // Arrange the switch and the text field in the stack view
                container.addSubview(boolSwitches[i]!)
                container.addSubview(textFields[i]!)
                boolSwitches[i]?.translatesAutoresizingMaskIntoConstraints = false
                boolSwitches[i]?.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
                boolSwitches[i]?.topAnchor.constraint(equalTo: labels[i].bottomAnchor, constant: self.sideSpacing).isActive = true
                boolSwitches[i]?.heightAnchor.constraint(equalToConstant: textField.frame.height).isActive = true
                boolSwitches[i]?.addTarget(self, action: #selector(handleTextFieldSwitch(sender:)), for: .touchUpInside)
                
                textFields[i]?.translatesAutoresizingMaskIntoConstraints = false
                textFields[i]?.leftAnchor.constraint(equalTo: (boolSwitches[i]?.rightAnchor)!, constant: self.sideSpacing * 2).isActive = true
                textFields[i]?.topAnchor.constraint(equalTo: (boolSwitches[i]?.topAnchor)!).isActive = true
                textFields[i]?.widthAnchor.constraint(equalToConstant: 60).isActive = true
                textFields[i]?.heightAnchor.constraint(equalToConstant: textField.frame.height).isActive = true
                
                lastBottomAnchor = (textFields[i]?.bottomAnchor)!
            
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

        scrollView.contentSize = self.view.frame.size//CGSize(width: container.frame.size.width, height: containerHeight)
        // ****** If height > area above keyboard, put it in a scroll view *************
        //  Add a flag property to notify the controller that it will or will not need to handle when the keyboard obscures a text field
        //  Then, in editingDidBegin, set the scroll view position so the field is just above the keyboard
        
    }
    
    // MARK:  - Scrollview Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
    }
    
    
    //MARK: - Tableview methods
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
    
    
    //MARK: - UITextFieldDelegate
    //######################################################################
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        // Dismiss all dropdowns except this one if it is a dropDown
        for dropDownID in dropDownTextFields.keys {
            if dropDownID != textField.tag {
                dropDownTextFields[dropDownID]?.dismissDropDown()
            }
        }
        
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
    
    // detect when editing begins and post the index of the text field
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.currentTextField = textField.tag
        return true
    }
    
    // Hide the keyboard when the return button is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // When finished editing, check if the data model instance should be updated
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateData()
        if self.textFieldIds[self.currentTextField].type != "dropDown" {
            dismissInputView()
        }
    }
    
    
    // When dropdown is pressed
    @objc func dropDownDidChange(notification: NSNotification) {
        guard let textDictionary = notification.object as? Dictionary<Int, String> else {
            fatalError("Couldn't downcast textDictionary: \(notification.object!)")
        }
        let index = textDictionary.keys.first!
        let text = textDictionary.values.first!
        textFields[index]?.text = text
        
        updateData()
    }
    
    // Dismiss keyboard when tapped outside of a text field
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissInputView))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func dismissInputView() {
        
        // Check what kind of textField is currently being edited
        switch(self.textFieldIds[self.currentTextField].type){
        case "date", "time":
            self.textFields[self.currentTextField]?.resignFirstResponder()
        case "dropDown":
            self.dropDownTextFields[self.currentTextField]?.dismissDropDown()
        default:
            self.view.endEditing(true)
        }
        
        //self.view.endEditing(true)
        updateData()
    }
    
    // Sets text for UISwitch (text field type is "boolSwitch")
    @objc func handleTextFieldSwitch(sender: UISwitch){
        let index = sender.tag
        if sender.isOn {
            textFields[index]?.text = "Yes"
        } else {
            textFields[index]?.text = "No"
        }
    }
    
    // MARK: Add a custom datepicker to each of the datetime fields
    
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
        datetimePickerView.addTarget(self, action: #selector(handleDatetimePicker), for: UIControlEvents.valueChanged)
        datetimePickerView.tag = sender.tag
        
        // Set the default time to now
        if (sender.text?.isEmpty)! {
            sender.text = formatter.string(from: now)
        }
    }
    
    @objc func handleDatetimePicker(sender: UIDatePicker) {
        let formatter = DateFormatter()
        
        // Set the formatter style for either a date or time
        let fieldType = textFieldIds[sender.tag].type
        switch(fieldType){
        case "time":
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        case "date":
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        default:
            fatalError("textfield \(sender.tag) passed to setupDatetimePicker was of type \(fieldType)")
        }
        
        // Send the string with a notification. Use the tag of the datepicker as the key to a dictionary so the receiver knows which text field this value belongs to
        let datetimeString = formatter.string(from: sender.date)
        let dictionary: [Int: String] = [sender.tag: datetimeString]
        NotificationCenter.default.post(name: Notification.Name("dateTimePicked:\(sender.tag)"), object: dictionary)
        
        // ********* override this method in observation view controllers: call super.handleDatetimePicker; updateObservation()
        //updateObservation()
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
    
    @objc func updateData(){
        // Dummy function. Needs to be overridden in sublcasses
        print("updateData() method not overriden")
    }
    
    // MARK: Navigation
    //#######################################################################
    // MARK: Override in all subclasses
    func setNavigationBar() {
        let screenSize: CGRect = UIScreen.main.bounds
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        self.navigationBar = CustomNavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: screenSize.width, height: 44))
        self.view.addSubview(self.navigationBar)
        
        // Customize buttons and title in all subclasses
    }
    
}

//MARK: -
//MARK: -
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


//MARK: -
//MARK: -
class BaseObservationViewController: BaseFormViewController {//}, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Properties
    var saveButton: UIBarButtonItem!
    
    //Used to pass observation from tableViewController when updating an observation. It should be type Any so that all subclasses can inherit it and modelObject can be downcast to the appropriate data model subclass of Observation. This way, self.observation can remain private so that all subclasses of the BaseObservationViewController can have self.observation be of the appropriate class.
    var modelObject: Any?
    
    // Must be private so that subclasses can "override" the value with their appropriate data model type. This way, fewer functions need to be overwritten because they can still reference the property "observation"
    private var observation: Observation?
    var isAddingNewObservation: Bool!
    var lastTextFieldIndex = 0
    var observationId: Int?
    
    // MARK: observation DB columns
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
    var observationsTable = Table("observations")
    
    // MARK: session DB properties
    let sessionsTable = Table("sessions")
    let openTimeColumn = Expression<String>("openTime")
    let closeTimeColumn = Expression<String>("closeTime")
    
    
    // MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date", type: "date"),
                             (label: "Time",          placeholder: "Select the observation time", type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name", type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination", type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date", type: "date"),
                             (label: "Time",          placeholder: "Select the observation time", type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name", type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination", type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]]
    }

    

    
    //MARK: - Layout
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
        self.lastTextFieldIndex = self.textFields.count + self.dropDownTextFields.count - 1
        
        /*// Lay out all text fields
        self.view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true*/
        
        autoFillTextFields()
        
        for (i, _) in boolSwitches {
            if textFields[i]?.text == "Yes" {
                print("Bool switch is on")
                boolSwitches[i]?.isOn = true
            } else {
                print("Bool switch is off")
                boolSwitches[i]?.isOn = false
            }
        }
    }
    
    // This portion of viewDidLoad() needs to be easily overridable to customize the order of texr fields
    func autoFillTextFields(){

        /*guard let observation = self.modelObject as? Observation else {
            fatalError("No valid observation passed from TableViewController")
        }*/
        // This is a completely new observation
        if self.isAddingNewObservation {
            /*self.observation = observation
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            self.textFields[2]?.text = formatter.string(from: now)*/
            saveButton.isEnabled = false
        // The observation already exists and is open for viewing/editing
        } else {

            
            /*self.dropDownTextFields[0]?.text = observation.observerName
            self.textFields[1]?.text = observation.date
            self.textFields[2]?.text = observation.time
            self.textFields[3]?.text = observation.driverName
            self.dropDownTextFields[4]?.text = observation.destination
            self.textFields[5]?.text = observation.nPassengers
            self.textFields[self.lastTextFieldIndex]?.text = observation.comments // Comments will always be the last one*/
        }
    }
    
    @objc func getObservationFromNotification(notification: NSNotification) {
        guard let observation = notification.object as? Observation else {
            fatalError("Couldn't downcast observation: \(notification.object!)")
        }
        self.observation = observation
        print("observation id: \(observation.id)")
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
    
    // MARK: - Navigation
    override func setNavigationBar() {
        let screenSize: CGRect = UIScreen.main.bounds
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        self.navigationBar = CustomNavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: screenSize.width, height: 44))
        
        let navItem = UINavigationItem(title: "New Vehicle")
        self.saveButton = UIBarButtonItem(title: "Save", style: .plain, target: nil, action: #selector(saveButtonPressed))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: #selector(cancelButtonPressed))
        navItem.rightBarButtonItem = self.saveButton
        navItem.leftBarButtonItem = cancelButton
        self.navigationBar.setItems([navItem], animated: false)
        
        self.view.addSubview(self.navigationBar)
    }
    
    // Dismiss with left to right transiton
    @objc func cancelButtonPressed() {
        if self.isAddingNewObservation {
            let presentingController = self.presentingViewController?.presentingViewController as! BaseTableViewController
            
            presentingController.dismissTransition = LeftToRightTransition()
            // Reset dismissTransition to nil when done
            presentingController.dismiss(animated: true, completion: {
                presentingController.dismissTransition = nil
            })
        } else {
            
            self.dismissTransition = LeftToRightTransition()
            dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
        }
    }
    
    // Configure tableview controller before it's presented
    @objc func saveButtonPressed() {
        // update the observation
        updateData()
        
        // Update the database
        // Add a new record
        if self.isAddingNewObservation {
            insertRecord()
        // Update an existing record
        } else {
            updateRecord()
        }
        
        // Get the actual id of the insert row and assign it to the observation that was just inserted. Now when the cell in the obsTableView is selected (e.g., for delete()), the right ID will be returned. This is exclusively so that when if an observation is deleted right after it's created, the right ID is given to retreive a record to delete from the DB.
        print("Observation ID before: \(observation?.id)")
        var max: Int64!
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
        } catch {
            print(error.localizedDescription)
        }
        observation?.id = Int(max)
        print("Observation ID after: \(observation?.id)")
        
        dismissController()
        
    }
    
    func dismissController() {
        if self.isAddingNewObservation {
            // Dismiss the last 2 controllers (the current one + AddObs menu) from the stack to get back to the tableView
            let presentingController = self.presentingViewController?.presentingViewController as! BaseTableViewController
            /*presentingController.modalPresentationStyle = .custom
             presentingController.transitioningDelegate = self
             presentingController.modalTransitionStyle = .flipHorizontal*/
            presentingController.dismiss(animated: true, completion: nil)
            presentingController.loadData()//observations.append(self.observation!)
            //presentingController.tableView.reloadData()
            //presentingController.dismissTransition = LeftToRightTransition()
            //presentingController.dismiss(animated: true, completion: {presentingController.dismissTransition = nil})
        } else {
            // Just dismiss this controller to get back to the tableView
            let presentingController = self.presentingViewController as! BaseTableViewController
            self.dismissTransition = LeftToRightTransition()
            dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
            presentingController.tableView.reloadData()
        }
    }

    
    //MARK: - Private methods
    
    // Update save button status
    @objc override func updateData(){
        
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let driverName = self.textFields[3]?.text ?? ""
        let destination = self.dropDownTextFields[4]?.text ?? ""
        let nPassengers = self.textFields[5]?.text ?? ""
        let comments = self.textFields[self.lastTextFieldIndex]?.text ?? ""
        print(observerName)
        
        if !observerName.isEmpty && !date.isEmpty && !time.isEmpty && !driverName.isEmpty && !destination.isEmpty && !nPassengers.isEmpty {
            //self.session = Observation(observerName: observerName, openTime: openTime, closeTime: closeTime, givenDate: date)
            self.saveButton.isEnabled = true

            // Update the Observation instance
            // Temporarily just say the id = -1. The id column is autoincremented anyway, so it doesn't matter.
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            self.observation?.nPassengers = nPassengers
            self.observation?.comments = comments
        }
        
        print(observation?.observerName)
    }
    
    // Add record to DB
    func insertRecord() {
        // Can just get text values from the observation because it has to be updated before saveButton is enabled
        let observerName = observation?.observerName
        let date = observation?.date
        let time = observation?.time
        let driverName = observation?.driverName
        let destination = observation?.destination
        let nPassengers = observation?.nPassengers
        let comments = observation?.comments
        
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
    
    func updateRecord() {
        do {
            // Select the record to update
            print("Record id: \((observation?.id.datatypeValue)!)")
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            print(record)
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
                print("updated record")
            } else {
                print("record not found")
            }
        } catch {
            print("Update failed")
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
    }
}

//MARK: -
//MARK: -
class BusObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: BusObservation?
    let busTypeColumn = Expression<String>("busType")
    let busNumberColumn = Expression<String>("busNumber")
    let isTrainingColumn = Expression<Bool>("isTraining")
    let nOvernightPassengersColumn = Expression<String>("nOvernightPassengers")
    //let observationsTable = Table("buses")
    
    let lodgeBusTypes = ["Denali Backcountry Lodge", "Kantishna Roadhouse", "Camp Denali/North Face"]
    
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Bus type",      placeholder: "Select the type of bus",              type: "dropDown"),
                             (label: "Bus number",    placeholder: "Enter the bus number (printed on the bus)", type: "normal"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Training bus?", placeholder: "",                                    type: "boolSwitch"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Number of overnight lodge guests", placeholder: "Enter the number of overnight logde guests", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"],
                                    "Bus type": ["Denali Natural History Tour", "Tundra Wilderness Tour", "Kantishna Experience", "Eielson Excursion", "Shuttle", "Camper", "Denali Backcountry Lodge", "Kantishna Roadhouse", "Camp Denali/North Face", "Other"]]
        self.observationsTable = Table("buses")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Bus type",      placeholder: "Select the type of bus",              type: "dropDown"),
                             (label: "Bus number",    placeholder: "Enter the bus number (printed on the bus)", type: "normal"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Training bus?", placeholder: "",                                    type: "boolSwitch"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Number of overnight lodge guests", placeholder: "Enter the number of overnight logde guests", type: "normal"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"],
                                    "Bus type": ["Denali Natural History Tour", "Tundra Wilderness Tour", "Kantishna Experience", "Eielson Excursion", "Shuttle", "Camper", "Denali Backcountry Lodge", "Kantishna Roadhouse", "Camp Denali/North Face", "Other"]]
        self.observationsTable = Table("buses")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
        updateNOvernightFieldStatus()
    }

    override func autoFillTextFields() {

        // This is a completely new observation
        if self.isAddingNewObservation {
            
            // Get the current time as a string
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let currentTime = formatter.string(from: now)
            
            self.observation = BusObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, driverName: "", destination: "", nPassengers: "", busType: "", busNumber: "", isTraining: false, nOvernightPassengers: "")
            
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = currentTime
            self.textFields[7]?.text = "No"
            self.saveButton.isEnabled = false
        // The observation already exists and is open for viewing/editing
        } else {
            // Query the db to get the observation
            guard let id = self.observationId else {
                fatalError("No ID passed from the tableViewController")
            }
            
            let record: Row
            do {
                record = (try db.pluck(observationsTable.where(idColumn == id.datatypeValue)))!
            } catch {
                fatalError("Query was unsuccessful because \(error.localizedDescription)")
            }
            self.observation = BusObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], busType: record[busTypeColumn], busNumber: record[busNumberColumn], isTraining: record[isTrainingColumn], nOvernightPassengers: record[nOvernightPassengersColumn], comments: record[commentsColumn])

            self.dropDownTextFields[0]?.text = self.observation?.observerName
            self.textFields[1]?.text = self.observation?.date
            self.textFields[2]?.text = self.observation?.time
            self.dropDownTextFields[3]?.text = self.observation?.busType
            self.textFields[4]?.text = self.observation?.busNumber
            self.textFields[5]?.text = self.observation?.driverName
            self.dropDownTextFields[6]?.text = self.observation?.destination
            if (self.observation?.isTraining)! {
                self.textFields[7]?.text = "Yes"
            } else {
                self.textFields[7]?.text = "No"
            }
            self.textFields[8]?.text = self.observation?.nPassengers
            self.textFields[9]?.text  = self.observation?.nOvernightPassengers
            self.textFields[10]?.text = self.observation?.comments
            self.saveButton.isEnabled = true
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        // update the observation
        updateData()
        
        // Update the database
        // Add a new record
        if self.isAddingNewObservation {
            insertRecord()
            
            // Update an existing record
        } else {
            updateRecord()
        }
        // Assign the right ID to the observation
        var max: Int64!
        do {
                        max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            print(error.localizedDescription)
        }
        observation?.id = Int(max)
        
        dismissController()
    }
    
    override func dismissController() {
        print("dismissing controller")
        if self.isAddingNewObservation {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .short
            guard let timeStamp = formatter.date(from: "\((self.observation?.date)!), \((self.observation?.time)!)") else {
                fatalError("Couldn't format timestamp from \((self.observation?.date)!), \((self.observation?.time)!)")
            }
            // Dismiss the last 2 controllers (the current one + AddObs menu) from the stack to get back to the tableView
            let presentingController = self.presentingViewController?.presentingViewController as! BaseTableViewController
            /*presentingController.modalPresentationStyle = .custom
             presentingController.transitioningDelegate = self
             presentingController.modalTransitionStyle = .flipHorizontal*/
            presentingController.dismiss(animated: true, completion: nil)
            //presentingController.observations.append(self.observation!)
            
            //presentingController.observationCells[timeStamp] = 
            presentingController.tableView.reloadData()
            //presentingController.dismissTransition = LeftToRightTransition()
            //presentingController.dismiss(animated: true, completion: {presentingController.dismissTransition = nil})
        } else {
            // Just dismiss this controller to get back to the tableView
            let presentingController = self.presentingViewController as! BaseTableViewController
            self.dismissTransition = LeftToRightTransition()
            dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
            presentingController.tableView.reloadData()
        }
    }
    
    //MARK: - Private methods
    @objc override func updateData(){
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let busType = self.dropDownTextFields[3]?.text ?? ""
        let busNumber = self.textFields[4]?.text ?? ""
        let driverName = self.textFields[5]?.text ?? ""
        let destination = self.dropDownTextFields[6]?.text ?? ""
        let isTraining = self.textFields[7]?.text ?? ""
        let nPassengers = self.textFields[8]?.text ?? ""
        let nOvernightPassengers = self.textFields[9]?.text ?? ""
        let comments = self.textFields[10]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
            !date.isEmpty &&
            !time.isEmpty &&
            !busType.isEmpty &&
            !busNumber.isEmpty &&
            !driverName.isEmpty &&
            !destination.isEmpty &&
            !nPassengers.isEmpty

        if fieldsFull {
            
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.busType = busType
            self.observation?.busNumber = busNumber
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            if isTraining == "Yes" {
                self.observation?.isTraining = true
            } else {
                self.observation?.isTraining = false
            }
            self.observation?.nPassengers = nPassengers
            self.observation?.nOvernightPassengers = nOvernightPassengers
            self.observation?.comments = comments
            
            // Check if this field should be filled in
            if lodgeBusTypes.contains(busType) {
                if !nOvernightPassengers.isEmpty {
                    self.saveButton.isEnabled = true
                }
            } else {
                self.saveButton.isEnabled = true
            }
            
        }
        // Check if the overnight passengers field should be enabled
        updateNOvernightFieldStatus()
    }
    
    // Add record to DB
    override func insertRecord() {
        // Insert into DB
        
        do {
            let rowid = try db.run(observationsTable.insert(observerNameColumn <- (self.observation?.observerName)!,
                                                            dateColumn <- (self.observation?.date)!,
                                                            timeColumn <- (self.observation?.time)!,
                                                            busTypeColumn <- (self.observation?.busType)!,
                                                            busNumberColumn <- (self.observation?.busNumber)!,
                                                            driverNameColumn <- (self.observation?.driverName)!,
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            isTrainingColumn <- (self.observation?.isTraining)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            nOvernightPassengersColumn <- (self.observation?.nOvernightPassengers)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            print("insertion failed: \(error)")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            print("Updating record with id \(observation?.id)")
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        busTypeColumn <- (self.observation?.busType)!,
                                        busNumberColumn <- (self.observation?.busNumber)!,
                                        isTrainingColumn <- (self.observation?.isTraining)!,
                                        nOvernightPassengersColumn <- (self.observation?.nOvernightPassengers)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
                print("updated record")
            } else {
                print("record not found")
            }
        } catch {
            print("Update failed")
        }
    }
    
    // Either disable or enable the nOvernightPassengers field, depending on whether the bustype is a lodge bus
    private func updateNOvernightFieldStatus() {
        let busType = self.dropDownTextFields[3]?.text ?? ""
        if self.lodgeBusTypes.contains(busType) {
            self.labels[9].textColor = UIColor.black
            self.labels[9].text = self.textFieldIds[9].label
            self.textFields[9]?.placeholder = self.textFieldIds[9].placeholder
            self.textFields[9]?.isEnabled = true
        } else {
            self.labels[9].textColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
            self.labels[9].text = "\(self.textFieldIds[9].label) (must be a lodge bus to enable this field)"
            self.textFields[9]?.placeholder = ""
            self.textFields[9]?.isEnabled = false
        }
    }
    
}


//MARK: -
//MARK: -
class NPSVehicleObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: NPSVehicleObservation?
    let tripPurposeColumn = Expression<String>("tripPurpose")
    let workDivisionColumn = Expression<String>("workDivision")
    let workGroupColumn = Expression<String>("workGroup")
    let nExpectedNightsColumn = Expression<String>("nExpectedDays")
    //private let observationsTable = Table("npsVehicles")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name",     type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",             type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",             type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",            type: "normal"),
                             (label: "Work division",      placeholder: "Select or enter the driver's division",   type: "dropDown"),
                             (label: "Work group",    placeholder: "Select or enter the work group",          type: "dropDown"),
                             (label: "Trip purpose",  placeholder: "Select or enter the purpose of the trip", type: "dropDown"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Destination",   placeholder: "Select or enter the destination",         type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)",    type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"],
                                    "Work division": ["Administration", "Buildings and Utilities", "External Affairs", "Resources", "Visitor and Resource Protection", "Other"],
                                    "Work group": ["Maintenance", "Roads", "Trails", "Other"],
                                    "Trip purpose": ["Other"]]
        self.observationsTable = Table("npsVehicles")

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name",     type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",             type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",             type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",            type: "normal"),
                             (label: "Division",      placeholder: "Select or enter the driver's division",   type: "dropDown"),
                             (label: "Work group",    placeholder: "Select or enter the work group",          type: "dropDown"),
                             (label: "Trip purpose",  placeholder: "Select or enter the purpose of the trip", type: "dropDown"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Destination",   placeholder: "Select or enter the destination",         type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)",    type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"],
                                    "Work division": ["Administration", "Buildings and Utilities", "External Affairs", "Resources", "Visitor and Resource Protection", "Other"],
                                    "Work group": ["Maintenance", "Roads", "Trails", "Other"],
                                    "Trip purpose": ["Other"]]
        self.observationsTable = Table("npsVehicles")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
        
        // Add notification
        dropDownTextFields[5]?.isEnabled = false
        labels[5].text = "\(textFieldIds[5].label) (select a division first)"
        labels[5].textColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        NotificationCenter.default.addObserver(self, selector: #selector(setWorkGroupOptions), name: Notification.Name("dropDownPressed:4"), object: nil)
    }
    
    override func autoFillTextFields() {
        /*guard let observation = self.observation else {
            fatalError("No valid observation passed from TableViewController")
        }*/
        // The observation already exists and is open for viewing/editing
        if self.isAddingNewObservation {
            // Get the current time as a string
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let currentTime = formatter.string(from: now)
            
            // Initialize the observation
            self.observation = NPSVehicleObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, driverName: "", destination: "", nPassengers: "", tripPurpose: "", workDivision: "", workGroup: "")
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            
            // Fill text fields with defaults
            self.textFields[2]?.text = currentTime
            self.textFields[7]?.text = "0"
            self.saveButton.isEnabled = false
            
        } else {
            // Query the db to get the observation
            guard let id = self.observationId else {
                fatalError("No ID passed from the tableViewController")
            }
            
            let record: Row
            do {
                record = (try db.pluck(observationsTable.where(idColumn == id.datatypeValue)))!
            } catch {
                fatalError("Query was unsuccessful because \(error.localizedDescription)")
            }
            self.observation = NPSVehicleObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], tripPurpose: record[tripPurposeColumn], workDivision: record[workDivisionColumn], workGroup: record[workGroupColumn], comments: record[commentsColumn])
            
            self.dropDownTextFields[0]?.text = self.observation?.observerName
            self.textFields[1]?.text = self.observation?.date
            self.textFields[2]?.text = self.observation?.time
            self.textFields[3]?.text = self.observation?.driverName
            self.dropDownTextFields[4]?.text = self.observation?.workDivision
            self.dropDownTextFields[5]?.text = self.observation?.workGroup
            self.dropDownTextFields[6]?.text = self.observation?.tripPurpose
            self.textFields[7]?.text = self.observation?.nExpectedNights
            self.dropDownTextFields[8]?.text  = self.observation?.destination
            self.textFields[9]?.text = self.observation?.nPassengers
            self.textFields[10]?.text = self.observation?.comments
            self.saveButton.isEnabled = true
        }
    }
    
    @objc private func setWorkGroupOptions(){
        var workGroups = ["Administration": ["Human Resources", "IT", "Other"],
                          "Buildings and Utilities": ["Maintenance", "Roads", "Support", "Trails", "Other"],
                          "External Affairs": ["Concessions", "Planning", "Superintendent's Office"],
                          "Resources": ["Cultural Resources", "Water, Air, Geology, Soil", "Wildlife", "Other"],
                          "Visitor and Resource Protection": ["Backcountry", "Law Enforcement", "Other"],
                          "Other": []]
        let division = (dropDownTextFields[4]?.text)!
        if workGroups.keys.contains(division) && division != "Other" {
            dropDownTextFields[5]?.dropView.dropDownOptions = workGroups[division]!
        } else { //"Other" was selected and the field was filled manually with keyboard
            dropDownTextFields[5]?.dropView.dropDownOptions = []
            dropDownTextFields[5]?.text = ""
        }
        
        dropDownTextFields[5]?.dropView.tableView.reloadData()
        dropDownTextFields[5]?.isEnabled = true
        labels[5].text = textFieldIds[5].label
        labels[5].textColor = UIColor.black
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        // update the observation
        updateData()
        
        // Update the database
        // Add a new record
        if self.isAddingNewObservation {
            insertRecord()
            
            // Update an existing record
        } else {
            updateRecord()
        }
        
        // Assign the right ID to the observation
        var max: Int64!
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            print(error.localizedDescription)
        }
        observation?.id = Int(max)
        
        dismissController()
    }
    
    override func dismissController() {
        
        if self.isAddingNewObservation {
            // Dismiss the last 2 controllers (the current one + AddObs menu) from the stack to get back to the tableView
            let presentingController = self.presentingViewController?.presentingViewController as! BaseTableViewController
            presentingController.dismiss(animated: true, completion: nil)
            //presentingController.observations.append(self.observation!)
            presentingController.loadData()//tableView.reloadData()
            //presentingController.dismissTransition = LeftToRightTransition()
            //presentingController.dismiss(animated: true, completion: {presentingController.dismissTransition = nil})
        } else {
            // Just dismiss this controller to get back to the tableView
            let presentingController = self.presentingViewController as! BaseTableViewController
            self.dismissTransition = LeftToRightTransition()
            dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
            presentingController.tableView.reloadData()
        }
    }
    
    //MARK: - Private methods
    
    @objc override func updateData(){
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let driverName = self.textFields[3]?.text ?? ""
        let workDivision = self.dropDownTextFields[4]?.text ?? ""
        let workGroup = self.dropDownTextFields[5]?.text ?? ""
        let tripPurpose = self.dropDownTextFields[6]?.text ?? ""
        let nExpectedNights = self.textFields[7]?.text ?? ""
        let destination = self.dropDownTextFields[8]?.text ?? ""
        let nPassengers = self.textFields[9]?.text ?? ""
        let comments = self.textFields[10]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !driverName.isEmpty &&
                !workDivision.isEmpty &&
                !workGroup.isEmpty &&
                !tripPurpose.isEmpty &&
                !nExpectedNights.isEmpty &&
                !destination.isEmpty &&
                !nPassengers.isEmpty
        
        if fieldsFull {
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.driverName = driverName
            self.observation?.workDivision = workDivision
            self.observation?.workGroup = workGroup
            self.observation?.tripPurpose = tripPurpose
            self.observation?.nExpectedNights = nExpectedNights
            self.observation?.destination = destination
            self.observation?.comments = comments
        
            self.saveButton.isEnabled = true
        }
    }
    
    // Add record to DB
    override func insertRecord() {
        // Insert into DB
        do {
            let rowid = try db.run(observationsTable.insert(observerNameColumn <- (self.observation?.observerName)!,
                                                            dateColumn <- (self.observation?.date)!,
                                                            timeColumn <- (self.observation?.time)!,
                                                            driverNameColumn <- (self.observation?.driverName)!,
                                                            workDivisionColumn <- (self.observation?.workDivision)!,
                                                            workGroupColumn <- (self.observation?.workGroup)!,
                                                            tripPurposeColumn <- (self.observation?.tripPurpose)!,
                                                            nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            print("insertion failed: \(error)")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            print("Record id: \((observation?.id.datatypeValue)!)")
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            print(record)
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        tripPurposeColumn <- (self.observation?.tripPurpose)!,
                                        workDivisionColumn <- (self.observation?.workDivision)!,
                                        workGroupColumn <- (self.observation?.workGroup)!,
                                        nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
                print("updated record")
            } else {
                print("record not found")
            }
        } catch {
            print("Update failed")
        }
    }
}


//MARK: -
//MARK: -
class NPSApprovedObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: NPSApprovedObservation?
    let tripPurposeColumn = Expression<String>("tripPurpose")
    let nExpectedNightsColumn = Expression<String>("nExpectedDays")
    let vehicleTypeColumn = Expression<String>("vehicleType")
    //private let observationsTable = Table("npsApproved")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Vehicle type",  placeholder: "Select the type of vehicle",          type: "dropDown"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"],
                                    "Vehicle type": ["Education", "Researcher", "V.I.P.", "Other"]]
        
        self.observationsTable = Table("npsApproved")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Vehicle type",  placeholder: "Select the type of vehicle",          type: "dropDown"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"],
                                    "Vehicle type": ["Education", "Researcher", "Other"]]
        
        self.observationsTable = Table("npsApproved")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    override func autoFillTextFields() {
        
        // This is a completely new observation
        if self.isAddingNewObservation {
            
            // Get the current time as a string
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let currentTime = formatter.string(from: now)
            
            // Initialize the observation
            self.observation = NPSApprovedObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, driverName: "", destination: "", nPassengers: "", vehicleType: "", tripPurpose: "", nExpectedNights: "")
            
            // Fill in text fields with defaults
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = currentTime
            self.textFields[7]?.text = "0"
            self.saveButton.isEnabled = false
            
        // The observation already exists and is open for viewing/editing
        } else {
            // Query the db to get the observation
            guard let id = self.observationId else {
                fatalError("No ID passed from the tableViewController")
            }
            
            let record: Row
            do {
                record = (try db.pluck(observationsTable.where(idColumn == id.datatypeValue)))!
            } catch {
                fatalError("Query was unsuccessful because \(error.localizedDescription)")
            }
            self.observation = NPSApprovedObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], vehicleType: record[vehicleTypeColumn], tripPurpose: record[tripPurposeColumn], nExpectedNights: record[nExpectedNightsColumn], comments: record[commentsColumn])
            
            self.dropDownTextFields[0]?.text = self.observation?.observerName
            self.textFields[1]?.text = self.observation?.date
            self.textFields[2]?.text = self.observation?.time
            self.dropDownTextFields[3]?.text = self.observation?.vehicleType
            self.textFields[4]?.text = self.observation?.driverName
            self.dropDownTextFields[5]?.text = self.observation?.destination
            self.textFields[6]?.text = self.observation?.nPassengers
            self.textFields[7]?.text  = self.observation?.nExpectedNights
            self.textFields[8]?.text = self.observation?.comments
            self.saveButton.isEnabled = true
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        // update the observation
        updateData()
        
        // Update the database
        // Add a new record
        if self.isAddingNewObservation {
            insertRecord()
        
        } else {
            updateRecord()
        }
        
        // Assign the right ID to the observation
        var max: Int64!
        do {
                        max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            print(error.localizedDescription)
        }
        observation?.id = Int(max)
        
        dismissController()
    }
    
    override func dismissController() {
        if self.isAddingNewObservation {
            // Dismiss the last 2 controllers (the current one + AddObs menu) from the stack to get back to the tableView
            let presentingController = self.presentingViewController?.presentingViewController as! BaseTableViewController
            /*presentingController.modalPresentationStyle = .custom
             presentingController.transitioningDelegate = self
             presentingController.modalTransitionStyle = .flipHorizontal*/
            presentingController.dismiss(animated: true, completion: nil)
            presentingController.tableView.reloadData()
            //presentingController.dismissTransition = LeftToRightTransition()
            //presentingController.dismiss(animated: true, completion: {presentingController.dismissTransition = nil})
        } else {
            // Just dismiss this controller to get back to the tableView
            let presentingController = self.presentingViewController as! BaseTableViewController
            self.dismissTransition = LeftToRightTransition()
            dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
            presentingController.tableView.reloadData()
        }
    }
    
    //MARK: - Private methods
    @objc override func updateData(){
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let vehicleType = self.dropDownTextFields[3]?.text ?? ""
        let driverName = self.textFields[4]?.text ?? ""
        let destination = self.dropDownTextFields[5]?.text ?? ""
        let nPassengers = self.textFields[6]?.text ?? ""
        let nExpectedNights = self.textFields[7]?.text ?? ""
        let comments = self.textFields[8]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !vehicleType.isEmpty &&
                !driverName.isEmpty &&
                !destination.isEmpty &&
                !nPassengers.isEmpty &&
                !nExpectedNights.isEmpty
        
        if fieldsFull {
            
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.vehicleType = vehicleType
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            self.observation?.nPassengers = nPassengers
            self.observation?.nExpectedNights = nExpectedNights
            self.observation?.tripPurpose = ""
            self.observation?.comments = comments
            
            self.saveButton.isEnabled = true
        }

    }
    
    // Add record to DB
    override func insertRecord() {
        // Insert into DB
        do {
            let rowid = try db.run(observationsTable.insert(observerNameColumn <- (self.observation?.observerName)!,
                                                            dateColumn <- (self.observation?.date)!,
                                                            timeColumn <- (self.observation?.time)!,
                                                            vehicleTypeColumn <- (self.observation?.vehicleType)!,
                                                            driverNameColumn <- (self.observation?.driverName)!,
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                                            tripPurposeColumn <- (self.observation?.tripPurpose)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            print("insertion failed: \(error)")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            print(record)
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        vehicleTypeColumn <- (self.observation?.vehicleType)!,
                                        nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
                print("updated record")
            } else {
                print("record not found")
            }
        } catch {
            print("Update failed")
        }
    }
}


//MARK: -
//MARK: -
class NPSContractorObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: NPSContractorObservation?
    let tripPurposeColumn = Expression<String>("tripPurpose")
    let nExpectedNightsColumn = Expression<String>("nExpectedDays")
    //private let observationsTable = Table("npsContractors")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Trip purpose",   placeholder: "Select or enter the trip purpose",   type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"],
                                    "Trip purpose": ["Delivery", "Maintenance", "Construction", "Other"]]
        
        self.observationsTable = Table("npsContractors")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Trip purpose",   placeholder: "Select or enter the trip purpose",   type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"],
                                    "Trip purpose": ["Delivery", "Maintenance", "Construction", "Other"]]
        self.observationsTable = Table("npsContractors")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    override func autoFillTextFields() {
        
        // This is a completely new observation
        if self.isAddingNewObservation {
            
            // Get the current time as a string
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            
            // Initialize the observation
            self.observation = NPSContractorObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: formatter.string(from: now), driverName: "", destination: "", nPassengers: "", tripPurpose: "", nExpectedNights: "")
            
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = formatter.string(from: now)
            self.textFields[7]?.text = "0"
            self.saveButton.isEnabled = false
            
            // The observation already exists and is open for viewing/editing
        } else {
            // Query the db to get the observation
            guard let id = self.observationId else {
                fatalError("No ID passed from the tableViewController")
            }
            
            let record: Row
            do {
                record = (try db.pluck(observationsTable.where(idColumn == id.datatypeValue)))!
            } catch {
                fatalError("Query was unsuccessful because \(error.localizedDescription)")
            }
            self.observation = NPSContractorObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], tripPurpose: record[tripPurposeColumn], nExpectedNights: record[nExpectedNightsColumn], comments: record[commentsColumn])
            
            self.dropDownTextFields[0]?.text = self.observation?.observerName
            self.textFields[1]?.text = self.observation?.date
            self.textFields[2]?.text = self.observation?.time
            self.textFields[3]?.text = self.observation?.driverName
            self.dropDownTextFields[4]?.text = self.observation?.destination
            self.dropDownTextFields[5]?.text = self.observation?.tripPurpose
            self.textFields[6]?.text = self.observation?.nPassengers
            self.textFields[7]?.text  = self.observation?.nExpectedNights
            self.textFields[8]?.text = self.observation?.comments
            self.saveButton.isEnabled = true
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        // update the observation
        updateData()
        
        // Update the database
        // Add a new record
        if self.isAddingNewObservation {
            insertRecord()
            
            // Update an existing record
        } else {
            updateRecord()
        }
        
        // Assign the right ID to the observation
        var max: Int64!
        do {
                        max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            print(error.localizedDescription)
        }
        observation?.id = Int(max)
        
        dismissController()
    }
    
    override func dismissController() {
        if self.isAddingNewObservation {
            // Dismiss the last 2 controllers (the current one + AddObs menu) from the stack to get back to the tableView
            let presentingController = self.presentingViewController?.presentingViewController as! BusTableViewController
            /*presentingController.modalPresentationStyle = .custom
             presentingController.transitioningDelegate = self
             presentingController.modalTransitionStyle = .flipHorizontal*/
            presentingController.dismiss(animated: true, completion: nil)
            presentingController.tableView.reloadData()
            //presentingController.dismissTransition = LeftToRightTransition()
            //presentingController.dismiss(animated: true, completion: {presentingController.dismissTransition = nil})
        } else {
            // Just dismiss this controller to get back to the tableView
            let presentingController = self.presentingViewController as! BaseTableViewController
            self.dismissTransition = LeftToRightTransition()
            dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
            presentingController.tableView.reloadData()
        }
    }
    
    //MARK: - Private methods
    @objc override func updateData(){

        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let driverName = self.textFields[3]?.text ?? ""
        let destination = self.dropDownTextFields[4]?.text ?? ""
        let tripPurpose = self.dropDownTextFields[5]?.text ?? ""
        let nPassengers = self.textFields[6]?.text ?? ""
        let nExpectedNights = self.textFields[7]?.text ?? ""
        let comments = self.textFields[8]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !driverName.isEmpty &&
                !destination.isEmpty &&
                !tripPurpose.isEmpty &&
                !nPassengers.isEmpty &&
                !nExpectedNights.isEmpty
        
        if fieldsFull {
            
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            self.observation?.tripPurpose = tripPurpose
            self.observation?.nPassengers = nPassengers
            self.observation?.nExpectedNights = nExpectedNights
            self.observation?.comments = comments
            
            self.saveButton.isEnabled = true
        }
        
    }
    
    // Add record to DB
    override func insertRecord() {
        // Insert into DB
        do {
            let rowid = try db.run(observationsTable.insert(observerNameColumn <- (self.observation?.observerName)!,
                                                            dateColumn <- (self.observation?.date)!,
                                                            timeColumn <- (self.observation?.time)!,
                                                            driverNameColumn <- (self.observation?.driverName)!,
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            tripPurposeColumn <- (self.observation?.tripPurpose)!,
                                                            nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            print("insertion failed: \(error)")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            print(record)
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        tripPurposeColumn <- (self.observation?.tripPurpose)!,
                                        nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
                print("updated record")
            } else {
                print("record not found")
            }
        } catch {
            print("Update failed")
        }
    }
}


//MARK: -
//MARK: -
class EmployeeObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: EmployeeObservation?
    let permitHolderColumn = Expression<String>("permitHolder")
    //private let observationsTable = Table("employees")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Permit holder's last name",   placeholder: "Enter the permit holder's last name",   type: "normal"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]]
        
        self.observationsTable = Table("employees")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Permit holder's last name",   placeholder: "Enter the permit holder's last name",   type: "normal"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]]
        
        self.observationsTable = Table("employees")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    override func autoFillTextFields() {
        
        // This is a completely new observation
        if self.isAddingNewObservation {
            // Get the current time as a string
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            
            // Initialize the observation
            self.observation = EmployeeObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: formatter.string(from: now), driverName: "", destination: "", nPassengers: "", permitHolder: "")
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            
            self.textFields[2]?.text = formatter.string(from: now)
            
            self.saveButton.isEnabled = false
            
            // The observation already exists and is open for viewing/editing
        } else {
            // Query the db to get the observation
            guard let id = self.observationId else {
                fatalError("No ID passed from the tableViewController")
            }
            
            let record: Row
            do {
                record = (try db.pluck(observationsTable.where(idColumn == id.datatypeValue)))!
            } catch {
                fatalError("Query was unsuccessful because \(error.localizedDescription)")
            }
            self.observation = EmployeeObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], permitHolder: record[permitHolderColumn], comments: record[commentsColumn])
            
            self.dropDownTextFields[0]?.text = self.observation?.observerName
            self.textFields[1]?.text = self.observation?.date
            self.textFields[2]?.text = self.observation?.time
            self.textFields[3]?.text = self.observation?.driverName
            self.dropDownTextFields[4]?.text = self.observation?.destination
            self.textFields[5]?.text = self.observation?.permitHolder
            self.textFields[6]?.text = self.observation?.nPassengers
            self.textFields[7]?.text = self.observation?.comments
            self.saveButton.isEnabled = true
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        // update the observation
        updateData()
        
        // Update the database
        // Add a new record
        if self.isAddingNewObservation {
            insertRecord()
            
            // Update an existing record
        } else {
            updateRecord()
        }
        
        // Assign the right ID to the observation
        var max: Int64!
        do {
                        max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            print(error.localizedDescription)
        }
        observation?.id = Int(max)
        
        dismissController()
    }
    
    override func dismissController() {
        if self.isAddingNewObservation {
            // Dismiss the last 2 controllers (the current one + AddObs menu) from the stack to get back to the tableView
            let presentingController = self.presentingViewController?.presentingViewController as! BusTableViewController
            /*presentingController.modalPresentationStyle = .custom
             presentingController.transitioningDelegate = self
             presentingController.modalTransitionStyle = .flipHorizontal*/
            presentingController.dismiss(animated: true, completion: nil)
            presentingController.tableView.reloadData()
            //presentingController.dismissTransition = LeftToRightTransition()
            //presentingController.dismiss(animated: true, completion: {presentingController.dismissTransition = nil})
        } else {
            // Just dismiss this controller to get back to the tableView
            let presentingController = self.presentingViewController as! BaseTableViewController
            self.dismissTransition = LeftToRightTransition()
            dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
            presentingController.tableView.reloadData()
        }
    }
    
    //MARK: - DB methods
    @objc override func updateData(){
        
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let driverName = self.textFields[3]?.text ?? ""
        let destination = self.dropDownTextFields[4]?.text ?? ""
        let permitHolder = self.textFields[5]?.text ?? ""
        let nPassengers = self.textFields[6]?.text ?? ""
        let comments = self.textFields[7]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !driverName.isEmpty &&
                !destination.isEmpty &&
                !permitHolder.isEmpty &&
                !nPassengers.isEmpty
        
        if fieldsFull {
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            self.observation?.permitHolder = permitHolder
            self.observation?.nPassengers = nPassengers
            self.observation?.comments = comments
            
            self.saveButton.isEnabled = true
        }
        
    }
    
    // Add record to DB
    override func insertRecord() {
        // Insert into DB
        do {
            let rowid = try db.run(observationsTable.insert(observerNameColumn <- (self.observation?.observerName)!,
                                                            dateColumn <- (self.observation?.date)!,
                                                            timeColumn <- (self.observation?.time)!,
                                                            driverNameColumn <- (self.observation?.driverName)!,
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            permitHolderColumn <- (self.observation?.permitHolder)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            print("insertion failed: \(error)")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            print(record)
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        permitHolderColumn <- (self.observation?.permitHolder)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
                print("updated record")
            } else {
                print("record not found")
            }
        } catch {
            print("Update failed")
        }
    }
}

//MARK: -
//MARK: -
class RightOfWayObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: RightOfWayObservation?
    let permitHolderColumn = Expression<String>("permitHolder")
    let tripPurposeColumn = Expression<String>("tripPurpose")
    //private let observationsTable = Table("rightOfWay")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Permit holder's last name",   placeholder: "Enter the permit holder's last name",   type: "normal"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]]
        
        self.observationsTable = Table("rightOfWay")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Permit holder's last name",   placeholder: "Enter the permit holder's last name",   type: "normal"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]]
        
        self.observationsTable = Table("rightOfWay")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    override func autoFillTextFields() {
        
        // This is a completely new observation
        if self.isAddingNewObservation {
            // Get the current time as a string
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let currentTime = formatter.string(from: now)
            
            // Create the observation instance
            self.observation = RightOfWayObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, driverName: "", destination: "", nPassengers: "", permitHolder: "", tripPurpose: "N/A")
            
            //Fill in text fields
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = currentTime
            self.saveButton.isEnabled = false
            
            // The observation already exists and is open for viewing/editing
        } else {
            // Query the db to get the observation
            guard let id = self.observationId else {
                fatalError("No ID passed from the tableViewController")
            }
            
            let record: Row
            do {
                record = (try db.pluck(observationsTable.where(idColumn == id.datatypeValue)))!
            } catch {
                fatalError("Query was unsuccessful because \(error.localizedDescription)")
            }
            self.observation = RightOfWayObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], permitHolder: record[permitHolderColumn], tripPurpose: record[tripPurposeColumn], comments: record[commentsColumn])
            
            self.dropDownTextFields[0]?.text = self.observation?.observerName
            self.textFields[1]?.text = self.observation?.date
            self.textFields[2]?.text = self.observation?.time
            self.textFields[3]?.text = self.observation?.driverName
            self.dropDownTextFields[4]?.text = self.observation?.destination
            self.textFields[5]?.text = self.observation?.permitHolder
            self.textFields[6]?.text = self.observation?.nPassengers
            self.textFields[7]?.text = self.observation?.comments
            self.saveButton.isEnabled = true
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        // update the observation
        updateData()
        
        // Update the database
        // Add a new record
        if self.isAddingNewObservation {
            insertRecord()
            
            // Update an existing record
        } else {
            updateRecord()
        }
        
        // Assign the right ID to the observation
        var max: Int64!
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            print(error.localizedDescription)
        }
        observation?.id = Int(max)
        
        dismissController()
    }
    
    /*override func dismissController() {
        if self.isAddingNewObservation {
            // Dismiss the last 2 controllers (the current one + AddObs menu) from the stack to get back to the tableView
            let presentingController = self.presentingViewController?.presentingViewController as! BaseTableViewController
            /*presentingController.modalPresentationStyle = .custom
             presentingController.transitioningDelegate = self
             presentingController.modalTransitionStyle = .flipHorizontal*/
            presentingController.dismiss(animated: true, completion: nil)
            presentingController.tableView.reloadData()
            //presentingController.dismissTransition = LeftToRightTransition()
            //presentingController.dismiss(animated: true, completion: {presentingController.dismissTransition = nil})
        } else {
            // Just dismiss this controller to get back to the tableView
            let presentingController = self.presentingViewController as! BaseTableViewController
            self.dismissTransition = LeftToRightTransition()
            dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
            presentingController.tableView.reloadData()
        }
    }*/
    
    //MARK: - DB methods
    @objc override func updateData(){
        
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let driverName = self.textFields[3]?.text ?? ""
        let destination = self.dropDownTextFields[4]?.text ?? ""
        let permitHolder = self.textFields[5]?.text ?? ""
        let nPassengers = self.textFields[6]?.text ?? ""
        let comments = self.textFields[7]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !driverName.isEmpty &&
                !destination.isEmpty &&
                !permitHolder.isEmpty &&
                !nPassengers.isEmpty
        
        if fieldsFull {
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            self.observation?.permitHolder = permitHolder
            self.observation?.nPassengers = nPassengers
            self.observation?.tripPurpose = ""
            self.observation?.comments = comments
            
            self.saveButton.isEnabled = true
        }
        
    }
    
    // Add record to DB
    override func insertRecord() {
        // Insert into DB
        do {
            let rowid = try db.run(observationsTable.insert(observerNameColumn <- (self.observation?.observerName)!,
                                                            dateColumn <- (self.observation?.date)!,
                                                            timeColumn <- (self.observation?.time)!,
                                                            driverNameColumn <- (self.observation?.driverName)!,
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            permitHolderColumn <- (self.observation?.permitHolder)!,
                                                            tripPurposeColumn <- (self.observation?.tripPurpose)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            print("insertion failed: \(error)")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            print(record)
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        permitHolderColumn <- (self.observation?.permitHolder)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
                print("updated record")
            } else {
                print("record not found")
            }
        } catch {
            print("Update failed")
        }
    }
}


//MARK: -
//MARK: -
/*class TeklanikaCamperObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: TeklanikaCamperObservation?
    let permitHolderColumn = Expression<String>("permitHolder")
    //private let observationsTable = Table("tekCampers")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Permit holder's last name",   placeholder: "Enter the permit holder's last name",   type: "normal"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]]
        
        self.observationsTable = Table("tekCampers")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's name", placeholder: "Enter the driver's last name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Permit holder's last name",   placeholder: "Enter the permit holder's last name",   type: "normal"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"],
                                    "Destination": ["Primrose/Mile 17", "Teklanika", "Toklat", "Stony Overlook", "Eielson", "Wonder Lake", "Kantishna", "Other"]]
        
        self.observationsTable = Table("tekCampers")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    override func autoFillTextFields() {
        
        // This is a completely new observation
        if self.isAddingNewObservation {
            
            // Get the current time as a string
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let currentTime = formatter.string(from: now)
            
            // Initialize the observation
            self.observation = TeklanikaCamperObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, destination: "", nPassengers: "", hasTekPass: false)
            
            //
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = formatter.string(from: now)
            
            self.saveButton.isEnabled = false
            
            // The observation already exists and is open for viewing/editing
        } else {
            self.dropDownTextFields[0]?.text = self.observation?.observerName
            self.textFields[1]?.text = self.observation?.date
            self.textFields[2]?.text = self.observation?.time
            self.textFields[3]?.text = self.observation?.driverName
            self.dropDownTextFields[4]?.text = self.observation?.destination
            self.textFields[5]?.text = self.observation?.permitHolder
            self.textFields[6]?.text = self.observation?.nPassengers
            self.textFields[7]?.text = self.observation?.comments
            self.saveButton.isEnabled = true
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        // update the observation
        updateData()
        
        // Update the database
        // Add a new record
        if self.isAddingNewObservation {
            insertRecord()
            
            // Update an existing record
        } else {
            updateRecord()
        }
        
        // Assign the right ID to the observation
        var max: Int64!
        do {
                        max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            print(error.localizedDescription)
        }
        observation?.id = Int(max)
        
        dismissController()
    }
    
    override func dismissController() {
        if self.isAddingNewObservation {
            // Dismiss the last 2 controllers (the current one + AddObs menu) from the stack to get back to the tableView
            let presentingController = self.presentingViewController?.presentingViewController as! BusTableViewController
            /*presentingController.modalPresentationStyle = .custom
             presentingController.transitioningDelegate = self
             presentingController.modalTransitionStyle = .flipHorizontal*/
            presentingController.dismiss(animated: true, completion: nil)
            presentingController.tableView.reloadData()
            //presentingController.dismissTransition = LeftToRightTransition()
            //presentingController.dismiss(animated: true, completion: {presentingController.dismissTransition = nil})
        } else {
            // Just dismiss this controller to get back to the tableView
            let presentingController = self.presentingViewController as! BaseTableViewController
            self.dismissTransition = LeftToRightTransition()
            dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
            presentingController.tableView.reloadData()
        }
    }
    
    //MARK: - DB methods
    @objc override func updateData(){
        
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let driverName = self.textFields[3]?.text ?? ""
        let destination = self.dropDownTextFields[4]?.text ?? ""
        let permitHolder = self.textFields[5]?.text ?? ""
        let nPassengers = self.textFields[6]?.text ?? ""
        let comments = self.textFields[7]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !driverName.isEmpty &&
                !destination.isEmpty &&
                !permitHolder.isEmpty &&
                !nPassengers.isEmpty
        
        if fieldsFull {
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            self.observation?.permitHolder = permitHolder
            self.observation?.nPassengers = nPassengers
            self.observation?.comments = comments
            
            self.saveButton.isEnabled = true
        }
        
    }
    
    // Add record to DB
    override func insertRecord() {
        // Insert into DB
        do {
            let rowid = try db.run(observationsTable.insert(observerNameColumn <- (self.observation?.observerName)!,
                                                            dateColumn <- (self.observation?.date)!,
                                                            timeColumn <- (self.observation?.time)!,
                                                            driverNameColumn <- (self.observation?.driverName)!,
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            permitHolderColumn <- (self.observation?.permitHolder)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            print("insertion failed: \(error)")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            print(record)
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        permitHolderColumn <- (self.observation?.permitHolder)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
                print("updated record")
            } else {
                print("record not found")
            }
        } catch {
            print("Update failed")
        }
    }
}



//MARK: -
//MARK: -
class CyclistObservationViewController: BaseObservationViewController {
    //let observationTable = Table("cyclists")
    var observation: Observation?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.observationsTable = Table("cyclists")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.observationsTable = Table("cyclists")
    }
}*/







