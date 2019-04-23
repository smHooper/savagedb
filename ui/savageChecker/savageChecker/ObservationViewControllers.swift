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


var sendDateEntryAlert = true

class BaseFormViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate {//}, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Properties
    //MARK: Textfield layout properties
    var textFieldIds: [(label: String, placeholder: String, type: String)] = []
    var dropDownMenuOptions = Dictionary<String, [String]>()
    var textFields = [Int: UITextField]()
    var dropDownTextFields = [Int: DropDownTextField]()
    var boolSwitches = [Int: UISwitch]()
    var checkBoxes = [Int: CheckBoxControl]()
    var labels = [UILabel]()

    
    // track when the text field in focus changes with a property observer
    var currentTextField = 0 {
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
    
    
    //MARK: Layout properties
    // layout properties
    let tableView = UITableView(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
    let scrollView = UIScrollView()
    let container = UIView()
    var formWidthConstraint = NSLayoutConstraint()
    //var formHeightConstraint = NSLayoutConstraint()
    var topSpacing = 40.0
    let sideSpacing: CGFloat = 8.0
    let textFieldSpacing: CGFloat = 30.0
    let textFieldHeight: CGFloat = 50.0
    //let navigationBarHeight: CGFloat = 44
    var deviceOrientation = 0
    var currentScrollViewOffset: CGFloat = 0
    var labelFontSize: CGFloat = 20.0
    
    var presentTransition: UIViewControllerAnimatedTransitioning?
    var dismissTransition: UIViewControllerAnimatedTransitioning?
    
    
    //MARK: - Layout
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        
        // Make sure the scrollView container doesn't delay the touch recognition for dropdowns
        self.scrollView.delaysContentTouches = false
        
        // Open connection to the DB
        do {
            //print(dbPath)
            if URL(fileURLWithPath: dbPath).lastPathComponent != "savageChecker.db" {
                db = try Connection(dbPath)
            }
        } catch let error {
            showGenericAlert(message: "Could not connect to the database at \(dbPath) because \(error.localizedDescription)", title: "Database connection error")
            os_log("Could not connect to database in BaseFormViewController.viewDidLoad()", log: .default, type: .debug)
        }
        
        self.deviceOrientation = UIDevice.current.orientation.rawValue
        
        addBackground()
        
        setNavigationBar()
        setupLayout()
        
        
        // If the view was still in memory, it will try to load the view in its previous orientation.
        //  Check that the orientation is correct, and if it doesn't match the old orientation, reset the layout
        if self.deviceOrientation != UIDevice.current.orientation.rawValue {
            self.deviceOrientation = UIDevice.current.orientation.rawValue
            resetLayout()
        }
        
        // Set up notifications so view will scroll when keyboard obscures a text field
        //registerForKeyboardNotifications()
    }
    
    
    // Update constraints when rotated
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        resetLayout()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // If the view was still in memory, it will try to load the view in its previous orientation.
        //  Check that the orientation is correct, and if it doesn't match the old orientation, reset the layout
        if self.deviceOrientation != UIDevice.current.orientation.rawValue {
            self.deviceOrientation = UIDevice.current.orientation.rawValue
            resetLayout()
        }
        // Set up notifications so view will scroll when keyboard obscures a text field.
        //  Call this here because if the view is already loaded in memory, it won't get called in viewDidLoad()
        registerForKeyboardNotifications()
    }
    
    
    func resetLayout() {
        
        //let safeArea = self.view.safeAreaInsets
        //let screenSize = UIScreen.main.bounds // This is actually the screen size before rotation
        let currentScreenFrame = getCurrentScreenFrame()
        self.scrollView.contentSize = CGSize(width: currentScreenFrame.width - CGFloat(self.sideSpacing * 2), height: self.scrollView.contentSize.height)
        self.formWidthConstraint.constant = currentScreenFrame.width * 0.8
        self.scrollView.setNeedsUpdateConstraints()
        self.scrollView.layoutIfNeeded()
        self.view.layoutIfNeeded()
        self.navigationBar.frame = CGRect(x:0, y: UIApplication.shared.statusBarFrame.size.height, width: currentScreenFrame.width, height: navigationBarSize)
        
    }
    
    
    // Set up the text fields in place
    func setupLayout(){
        // Set up the container
        //let safeArea = self.view.safeAreaInsets
        self.scrollView.showsHorizontalScrollIndicator = false
        //scrollView.contentInsetAdjustmentBehavior = .automatic
        //scrollView.bounces = false
        
        self.view.addSubview(self.scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: self.sideSpacing).isActive = true
        self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: CGFloat(self.topSpacing) + navigationBarSize + UIApplication.shared.statusBarFrame.height).isActive = true
        self.scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -self.sideSpacing).isActive = true
        self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        self.scrollView.addSubview(container)
        
        // Set up constraints.
        self.container.translatesAutoresizingMaskIntoConstraints = false
        self.container.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        self.container.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        self.formWidthConstraint = self.container.widthAnchor.constraint(equalToConstant: getCurrentScreenFrame().width * 0.8)//.isActive = true
        self.formWidthConstraint.isActive = true
        
        
        var containerHeight = CGFloat(0.0)
        var lastBottomAnchor = container.topAnchor
        for i in 0..<textFieldIds.count {
            // Combine the label and the textField in a vertical stack view
            let label = UILabel()
            let thisLabelText = textFieldIds[i].label
            let font = UIFont.systemFont(ofSize: self.labelFontSize)
            let labelWidth = thisLabelText.width(withConstrainedHeight: 28.5, font: font)
            label.text = thisLabelText
            label.font = font
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
            textField.autocorrectionType = .no
            textField.borderStyle = .roundedRect
            textField.layer.borderColor = UIColor.clear.cgColor//.lightGray.cgColor
            textField.layer.borderWidth = 0.01//0.25
            textField.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
            textField.font = UIFont.systemFont(ofSize: 16.0)
            textField.layer.cornerRadius = 5
            //textField.frame.size.height = 28.5
            textField.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: textFieldHeight)//safeArea.left, y: 0, width: self.view.frame.size.width - safeArea.right, height: 28.5)
            textField.tag = i
            textField.delegate = self
            //textFields.append(textField)
            
            let stack = UIStackView()
            //let stackHeight = label.frame.height + CGFloat(self.sideSpacing) + textFields[i].frame.height
            let stackHeight = (label.text?.height(withConstrainedWidth: labelWidth, font: label.font))! + CGFloat(self.sideSpacing) + textField.frame.height
            stack.axis = .vertical
            stack.spacing = CGFloat(self.sideSpacing)
            stack.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: stackHeight)//safeArea.left, y: 0, width: self.view.frame.size.width - safeArea.right, height: stackHeight)
            
            containerHeight += stackHeight + CGFloat(self.textFieldSpacing)
            
            switch(textFieldIds[i].type) {
            case "normal", "date", "time", "number":
                // Don't do anything special
                textFields[i] = textField
                container.addSubview(textFields[i]!)
                textFields[i]?.translatesAutoresizingMaskIntoConstraints = false
                textFields[i]?.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
                textFields[i]?.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
                textFields[i]?.topAnchor.constraint(equalTo: labels[i].bottomAnchor, constant: self.sideSpacing).isActive = true
                textFields[i]?.heightAnchor.constraint(equalToConstant: textFieldHeight).isActive = true
                lastBottomAnchor = (textFields[i]?.bottomAnchor)!
            
            case "dropDown":
                // re-configure the text field
                dropDownTextFields[i] = DropDownTextField.init(frame: textField.frame)
                dropDownTextFields[i]!.placeholder = textFieldIds[i].placeholder
                textField.autocorrectionType = .no
                dropDownTextFields[i]!.borderStyle = .roundedRect
                dropDownTextFields[i]!.layer.borderColor = textField.layer.borderColor//UIColor.clear.cgColor//lightGray.cgColor
                dropDownTextFields[i]!.layer.borderWidth = textField.layer.borderWidth
                dropDownTextFields[i]!.backgroundColor = textField.backgroundColor//UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
                dropDownTextFields[i]!.font = textField.font//UIFont.systemFont(ofSize: 14.0)
                dropDownTextFields[i]!.layer.cornerRadius = textField.layer.cornerRadius//5
                dropDownTextFields[i]!.frame.size.height = textField.frame.size.height//28.5
                dropDownTextFields[i]!.tag = i
                dropDownTextFields[i]!.delegate = self
                
                // Set constraints
                container.addSubview(dropDownTextFields[i]!)
                dropDownTextFields[i]!.translatesAutoresizingMaskIntoConstraints = false
                dropDownTextFields[i]!.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
                dropDownTextFields[i]!.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
                dropDownTextFields[i]!.topAnchor.constraint(equalTo: labels[i].bottomAnchor, constant: self.sideSpacing).isActive = true
                dropDownTextFields[i]!.heightAnchor.constraint(equalToConstant: textFieldHeight).isActive = true
                lastBottomAnchor = dropDownTextFields[i]!.bottomAnchor
                
                //setDropdownBackground(textField: dropDownTextFields[i]!)
                
                //Set the drop down menu's options
                guard let dropDownOptions = dropDownMenuOptions[textFieldIds[i].label] else {
                    print("Either self.dropDownMenuOptions not set or \(textFieldIds[i].label) is not a key: \(self.dropDownMenuOptions)")
                    return
                }
                dropDownTextFields[i]!.dropView.dropDownOptions = dropDownOptions
                
                // Set up dropView constraints. If this is in DropDownTextField, it thows the error 'Unable to activate constraint with anchors <ID of constaint"> and <ID of other constaint> because they have no common ancestor.  Does the constraint or its anchors reference items in different view hierarchies?  That's illegal.'
                self.view.addSubview(dropDownTextFields[i]!.dropView)
                self.view.bringSubview(toFront: dropDownTextFields[i]!.dropView)
                dropDownTextFields[i]!.dropView.leftAnchor.constraint(equalTo: dropDownTextFields[i]!.leftAnchor).isActive = true
                dropDownTextFields[i]!.dropView.rightAnchor.constraint(equalTo: dropDownTextFields[i]!.rightAnchor).isActive = true
                dropDownTextFields[i]!.dropView.topAnchor.constraint(equalTo: dropDownTextFields[i]!.bottomAnchor).isActive = true
                dropDownTextFields[i]!.heightConstraint = dropDownTextFields[i]!.dropView.heightAnchor.constraint(equalToConstant: 0)
                
                // Add listener for notification from DropDownTextField.dropDownPressed()
                dropDownTextFields[i]?.dropDownID = i//textFieldIds[i].label
                NotificationCenter.default.addObserver(self, selector: #selector(dropDownDidChange(notification:)), name: Notification.Name("dropDownPressed:\(i)"), object: nil)//textFieldIds[i].label)"), object: nil)//.addObserver has nothing to do with the "Observation" class
            
            case "boolSwitch":
                textFields[i] = textField
                textFields[i]?.isEnabled = false
                //textFields[i]?.layer.borderColor = UIColor.clear.cgColor
                //textFields[i]?.borderStyle = .roundedRect
                textFields[i]?.contentVerticalAlignment = .center
                //textFields[i]?.contentHorizontalAlignment = .center
                textFields[i]?.textAlignment = .center
                
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
                textFields[i]?.widthAnchor.constraint(equalToConstant: textFieldHeight).isActive = true
                textFields[i]?.heightAnchor.constraint(equalToConstant: textField.frame.height).isActive = true
                
                lastBottomAnchor = (textFields[i]?.bottomAnchor)!
            
            case "checkBox":
                checkBoxes[i] = CheckBoxControl()
                checkBoxes[i]?.tag = i
                
                // Arrange the checkBox and the label
                container.addSubview(checkBoxes[i]!)
                checkBoxes[i]?.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
                checkBoxes[i]?.translatesAutoresizingMaskIntoConstraints = false
                if lastBottomAnchor == container.topAnchor {
                    checkBoxes[i]?.topAnchor.constraint(equalTo: lastBottomAnchor).isActive = true
                } else {
                    checkBoxes[i]?.topAnchor.constraint(equalTo: lastBottomAnchor, constant: self.textFieldSpacing).isActive = true
                }
                checkBoxes[i]?.heightAnchor.constraint(equalToConstant: self.textFieldHeight).isActive = true
                checkBoxes[i]?.widthAnchor.constraint(equalToConstant: self.textFieldHeight).isActive = true
                checkBoxes[i]?.addTarget(self, action: #selector(checkBoxTapped(sender:)), for: .touchUpInside)
                
                // For some reason, I can't just remove label constaints, so just get rid of the label and make a new one.
                labels[i].removeFromSuperview()
                labels.remove(at: i)
                let label = UILabel()
                let thisLabelText = textFieldIds[i].label
                let font = UIFont.systemFont(ofSize: self.labelFontSize)
                label.text = thisLabelText
                label.font = font
                labels.append(label)
                container.addSubview(labels[i])
                labels[i].translatesAutoresizingMaskIntoConstraints = false
                
                labels[i].leftAnchor.constraint(equalTo: checkBoxes[i]!.rightAnchor, constant: self.sideSpacing * 2).isActive = true
                labels[i].centerYAnchor.constraint(equalTo: checkBoxes[i]!.centerYAnchor).isActive = true
                lastBottomAnchor = checkBoxes[i]!.bottomAnchor
                
            default:
                os_log("Text field type not understood", log: OSLog.default, type: .debug)
            }
            
            // Set up custom keyboards
            switch(textFieldIds[i].type) {
            case "time", "date":
                //let datetimePicker = CustomDatetimePickerControl()
                //datetimePicker.setupDatetimePicker(textField: textFields[i]!, viewController: self, datetimeMode: textFieldIds[i].type)
                createDatetimePicker(textField: textFields[i]!)
            case "number":
                textFields[i]!.keyboardType = .numberPad
            default:
                let _ = 0
            }
        }
        // Now set the height contraint
        
        let contentWidth = self.view.frame.width - (self.sideSpacing * 2)
        let contentHeight = containerHeight + UIApplication.shared.statusBarFrame.height + navigationBarSize + CGFloat(self.topSpacing)
        container.heightAnchor.constraint(equalToConstant: contentHeight).isActive = true
        self.scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)//CGSize(width: container.frame.size.width, height: containerHeight)
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
        
        /*let cell = TextFieldCell()
        
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
        
        return cell*/
        return UITableViewCell()
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
        case "normal":
            textField.selectAll(nil)
        case "number":
            textField.selectAll(nil)
        case "dropDown":
            
            let field = textField as! DropDownTextField
            guard let text = textField.text else {
                return
            }
            
            textField.resignFirstResponder()
            
            //setDropdownBackground(textField: textField as! DropDownTextField)
            
            // Interp staff thought that other should be the actual entry rather than having people type something in
            // Hide keyboard if "Other" wasn't selected and the dropdown has not yet been pressed
            /*if field.dropView.dropDownOptions.contains(text) || !field.dropDownWasPressed{
                textField.resignFirstResponder()
            } else {
                textField.becomeFirstResponder()
            }*/
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
        // Don't update after a dropDown finished editing because this method is
        //  called when it's first pressed and when a menu item is selected.
        //  dropDownDidChange() handles the latter via notification, and the former
        //  should be ignored.
        if self.textFieldIds[textField.tag].type != "dropDown" {
            updateData()
            dismissInputView()
        }
    }
    
    
    func getTextFieldCoordinates(textFieldId: Int) {
        
        
    }
    
    // Setup dropdown background view
    func setDropdownBackground(textField: DropDownTextField) {
        // Make sure the background is clear
        textField.dropView.tableView.backgroundColor = UIColor.clear
        textField.dropView.tableView.layer.backgroundColor = UIColor.clear.cgColor
        
        //let location = textField.view
        let frame = CGRect(x: self.sideSpacing, y: textField.frame.height, width: textField.frame.width, height: textField.dropView.height)
        
        /*let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        //always fill the view
        blurEffectView.frame = self.view.frame//bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.view.addSubview(blurEffectView)*/
        
        let backgroundView = UIImageView(image: self.view.takeSnapshot())
        backgroundView.contentMode = .scaleAspectFill
        let currentFrame = self.view.frame
        backgroundView.frame = frame//CGRect(x: currentFrame.minX - frame.minX, y: currentFrame.minY - frame.minY, width: currentFrame.width, height: currentFrame.height)
        /*blurEffectView.removeFromSuperview()
        
        let translucentWhite = UIView(frame: backgroundView.frame)
        translucentWhite.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
        backgroundView.addSubview(translucentWhite)*/
        
        textField.dropView.tableView.backgroundView = backgroundView
    }
    
    
    // Get notifications from keyboard so view can be moved up if text field is obscured by it
    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    // De-register notifications
    func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    // If text field would be obscured by keyboard, moving form view up
    @objc func keyboardWasShown(notification: NSNotification){
        // Calculate keyboard exact size
        var info = notification.userInfo!
        var keyboardHeight = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)!.cgRectValue.size.height
        
        // If this is a date or time field, add the height of the Done button bar
        let datetimeTypes = ["date", "time"]
        if datetimeTypes.contains(textFieldIds[self.currentTextField].type) {
            keyboardHeight += CGFloat(40) // add done toolbar height
        }
        
        let currentFieldFrame: CGRect
        switch textFieldIds[self.currentTextField].type {
        case "dropDown":
            currentFieldFrame = dropDownTextFields[self.currentTextField]!.frame
        default:
            currentFieldFrame = textFields[self.currentTextField]!.frame
        }
        
        // Check if the currently active text field is obscured. If so, scroll
        self.currentScrollViewOffset = self.scrollView.contentOffset.y // Record current offset so keyboardWillBeHidden() can get back to this location
        let offsetFromKeyboard = currentFieldFrame.maxY - (self.view.frame.height - (self.scrollView.frame.minY + CGFloat(self.topSpacing)) - keyboardHeight)
        if offsetFromKeyboard - self.currentScrollViewOffset > 0 { //If offsetFromKeyboard - currentOffset is positive, the view isn't obscured
            self.scrollView.contentOffset = CGPoint(x: 0, y: offsetFromKeyboard)
        }
    }
    
    
    // When keyboard disappears, restore original position
    @objc func keyboardWillBeHidden(notification: NSNotification){
        self.scrollView.contentOffset = CGPoint(x: 0, y: self.currentScrollViewOffset)
        self.view.endEditing(true)
    }
    
    
    // Update data when a the dropDown menu is selected
    @objc func dropDownDidChange(notification: NSNotification) {
        updateData()
    }
    
    // Dismiss keyboard when tapped outside of a text field
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissInputView))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    // Dismiss the keyboard, pickerView, or dropDown menu
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
    
    // Called when text a text field with type == "date" || "time" is laid out
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
            print("textfield \(sender.tag) passed to setupDatetimePicker was of type \(fieldType)")
            os_log("wrong type of field passed to setUpDatetimePicker()", log: .default, type: .debug)
        }
        
        sender.inputView = datetimePickerView
        //datetimePickerView.addTarget(self, action: #selector(handleDatetimePicker), for: UIControlEvents.valueChanged)
        datetimePickerView.tag = sender.tag
        
        // Set the default time to now
        if sender.text?.isEmpty ?? false {
            sender.text = formatter.string(from: now)
        }
    }
    
    func formatDatetime(textFieldId: Int, date: Date) -> String {
        let formatter = DateFormatter()
        
        // Set the formatter style for either a date or time
        let fieldType = self.textFieldIds[textFieldId].type
        switch(fieldType){
        case "time":
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        case "date":
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        default:
            print("textfield \(textFieldId) passed to setupDatetimePicker was of type \(fieldType)")
            os_log("wrong type of field passed to formatDatetime()", log: .default, type: .debug)
        }
        
        let datetimeString = formatter.string(from: date)
        
        return datetimeString
    }
    
    
    
    // Send a notification with the value from pickerView
    @objc func handleDatetimePicker(sender: UIDatePicker) {
        
        if let currentValue = self.textFields[sender.tag]?.text {
            var datetimeString = formatDatetime(textFieldId: sender.tag, date: sender.date)

            // If this is a date field, check if the date is today. If not, send an alert to make sure this is intentional
            if self.textFieldIds[sender.tag].type == "date" {
                let today = Date()
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .none
                let todayString = formatter.string(from: today)
                if datetimeString != todayString && sendDateEntryAlert {
                    let alertTitle = "Date Entry Alert"
                    let alertMessage = "You selected a date other than today. Was this intentional? If not, press Cancel."
                    let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: {action in self.dismissInputView(); self.textFields[sender.tag]?.text = datetimeString}))
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {handler in datetimeString = currentValue}))
                    alertController.addAction(UIAlertAction(title: "Yes, and don't ask again", style: .default, handler: {handler in self.dismissInputView(); self.textFields[sender.tag]?.text = datetimeString;
                        sendDateEntryAlert = false}))
                    present(alertController, animated: true, completion: nil)
                } else {
                    self.textFields[sender.tag]?.text = datetimeString
                }
            } else {
                self.textFields[sender.tag]?.text = datetimeString
            }
            
        } else {
            print("No text field matching datetimPicker id \(sender.tag) found")
            os_log("Bad notification sent to handleDatetimePicker. No matcing datetimePicker id found", log: .default, type: .debug)
            showGenericAlert(message: "No text field matching datetimPicker id \(sender.tag) found", title: "Unknown datetime field")
        }
            
    }
    
    // Create the datetime picker input view
    func createDatetimePicker(textField: UITextField) {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(BaseObservationViewController.datetimeDonePressed))
        doneButton.tag = textField.tag
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(datetimeCancelPressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        toolBar.setItems([flexSpace, cancelButton, flexSpace, doneButton, flexSpace], animated: true)
        
        // Make sure this is added to the controller when setupDatetimePicker() is called
        textField.inputAccessoryView = toolBar
        
        // Add a notification to retrieve the value from the datepicker
        //NotificationCenter.default.addObserver(self, selector: #selector(updateDatetimeField(notification:)), name: Notification.Name("dateTimePicked:\(textField.tag)"), object: nil)
    }

    
    @objc func datetimeCancelPressed() {
        dismissInputView()
    }
    
    
    // Check that the done button on custom DatePicker was pressed
    @objc func datetimeDonePressed(sender: UIBarButtonItem) {

        
        if let currentValue = self.textFields[sender.tag]?.text {
            let datetimePickerView = textFields[sender.tag]?.inputView as! UIDatePicker
            var datetimeString = formatDatetime(textFieldId: sender.tag, date: datetimePickerView.date)
            //var datetimeString = formatDatetime(textFieldId: sender.tag, date: sender.date)
            
            // If this is a date field, check if the date is today. If not, send an alert to make sure this is intentional
            if self.textFieldIds[sender.tag].type == "date" {
                let today = Date()
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .none
                let todayString = formatter.string(from: today)
                if datetimeString != todayString && sendDateEntryAlert {
                    let alertTitle = "Date Entry Alert"
                    let alertMessage = "You selected a date other than today. Was this intentional? If not, press Cancel."
                    let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: {action in self.dismissInputView(); self.textFields[sender.tag]?.text = datetimeString}))
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {handler in datetimeString = currentValue}))
                    alertController.addAction(UIAlertAction(title: "Yes, and don't ask again", style: .default, handler: {handler in self.dismissInputView(); self.textFields[sender.tag]?.text = datetimeString;
                        sendDateEntryAlert = false}))
                    present(alertController, animated: true, completion: nil)
                } else {
                    self.textFields[sender.tag]?.text = datetimeString
                }
            } else {
                self.textFields[sender.tag]?.text = datetimeString
            }
            
        } else {
            print("No text field matching datetimPicker id \(sender.tag) found")
            os_log("Bad notification sent to handleDatetimePicker. No matcing datetimePicker id found", log: .default, type: .debug)
            showGenericAlert(message: "No text field matching datetimPicker id \(sender.tag) found", title: "Unknown datetime field")
        }
        
        //textFields[sender.tag]?.text = datetimeString
        textFields[sender.tag]?.resignFirstResponder()
    }
    
    
    @objc func updateData(){
        // Dummy function. Needs to be overridden in sublcasses
        print("updateData() method not overriden")
    }
    
    
    // MARK: Navigation
    func setNavigationBar() {
        
        // Remove from superview and set to nil so if this method is called on rotation, the old nav bar isn't visible
        /*if let navigationBar = self.navigationBar {
            if self.view.subviews.contains(self.navigationBar) {
                self.navigationBar.removeFromSuperview()
                self.navigationBar = nil
            }
        }*/
        
        let screenSize: CGRect = UIScreen.main.bounds
        self.navigationBar = CustomNavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: screenSize.width, height: navigationBarSize))
        self.view.addSubview(self.navigationBar)
        
        self.navigationBar.translatesAutoresizingMaskIntoConstraints = false
        self.navigationBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.navigationBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.navigationBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: statusBarHeight).isActive = true
        self.navigationBar.heightAnchor.constraint(equalToConstant: navigationBarSize).isActive = true
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
    var qrString = ""
    var navBarColor = UIColor.lightGray
    
    // MARK: observation DB columns
    let idColumn = Expression<Int64>("id")
    let observerNameColumn = Expression<String>("observer_name")
    let dateColumn = Expression<String>("date")
    let timeColumn = Expression<String>("time")
    let driverNameColumn = Expression<String>("driver_name")
    let destinationColumn = Expression<String>("destination")
    let nPassengersColumn = Expression<String>("n_passengers")
    let commentsColumn = Expression<String>("comments")
    var dbColumns = [Expression<String>("observer_name"),
                     Expression<String>("date"),
                     Expression<String>("time"),
                     Expression<String>("driver_name"),
                     Expression<String>("destination"),
                     Expression<String>("n_passengers"),
                     Expression<String>("comments")]
    var observationsTable = Table("observations")
    
    // MARK: session DB properties
    let sessionsTable = Table("sessions")
    let openTimeColumn = Expression<String>("open_time")
    let closeTimeColumn = Expression<String>("close_time")
    
    
    // MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date", type: "date"),
                             (label: "Time",          placeholder: "Select the observation time", type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name", type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination", type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date", type: "date"),
                             (label: "Time",          placeholder: "Select the observation time", type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name", type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination", type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations]
    }

    
    //MARK: - Layout
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

        // Open connection to the DB
        do {
            db = try Connection(dbPath)
        } catch let error {
            showGenericAlert(message: error.localizedDescription, title: "Database connection error")
        }
        
        //Load the session
        do {
            try loadSession()
        } catch {
            showGenericAlert(message: "Could not load shift info because \(error.localizedDescription)", title: "Datbase error")
        }
        setNavigationBar()
        self.lastTextFieldIndex = self.textFields.count + self.dropDownTextFields.count - 1
        
        autoFillTextFields()
        
        for (i, _) in self.boolSwitches {
            if self.textFields[i]?.text == "Yes" {
                self.boolSwitches[i]?.isOn = true
            } else {
                self.boolSwitches[i]?.isOn = false
            }
        }
        
        // Make sure if driverName is a field for this vehicle type, the UITextField has autocapitalization set
        for (index, fieldInfo) in self.textFieldIds.enumerated() {
            if fieldInfo.label == "Driver's full name" {
                self.textFields[index]?.autocapitalizationType = .words
            }
        }
    }
    
    // Parse a JSON string from a QR code. The value of each item in the JSON string will only be used to fill a
    //  text field if the key for item matches the label of the text field
    func parseQRString() {
        if !self.qrString.isEmpty {
            if let json = try? JSON(data: self.qrString.data(using: .utf8, allowLossyConversion: false) ?? " ".data(using: .utf8)!) {
                let jsonDictionary = json.dictionary
                for (i, fieldInfo) in self.textFieldIds.enumerated() {
                    let controlName = fieldInfo.label
                    let value = json[controlName].string ?? ""
                    if jsonDictionary?[controlName]?.string != nil {
                        switch fieldInfo.type {
                        case "normal", "number":
                            self.textFields[i]?.text = value
                        case "dropDown":
                            self.dropDownTextFields[i]?.text = value
                        default:
                            let _ = 1
                        }
                    }
                }
            } else {
                os_log("Could not parse self.qrString", log: .default, type: .debug)
                showGenericAlert(message: "Problem encountered while parsing QR code string: \(self.qrString)", title: "QR code read error")
            }
        }
    }
    
    func getObservationRecord(id: Int) -> Row? {
        do {
            guard let record = try db.pluck(self.observationsTable.where(idColumn == id.datatypeValue)) else {
                os_log("Could not load data because query of record failed in autofillTextFields", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because the query returned nil. If you save your entry, it will be an entirely new observation.", title: "Data loading error")
                self.isAddingNewObservation = true
                return nil
            }
            return record
        } catch {
            os_log("Could not load data because query of record failed in autofillTextFields", log: .default, type: .debug)
            showGenericAlert(message: "Could not load data because \(error.localizedDescription). If you save your entry, it will be an entirely new observation", title: "Data loading error")
            self.isAddingNewObservation = true
            return nil
        }
        
    }
    
    // This portion of viewDidLoad() needs to be easily overridable to customize the order of text fields
    func autoFillTextFields(){

        // This is a completely new observation
        if self.isAddingNewObservation {
            //self.observation = observation
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            self.textFields[2]?.text = formatter.string(from: now)//*/
            saveButton.isEnabled = false
            
            if !self.qrString.isEmpty {
                parseQRString()
            }
        // The observation already exists and is open for viewing/editing
        } else {
            self.dropDownTextFields[0]?.text = observation?.observerName
            self.textFields[1]?.text = observation?.date
            self.textFields[2]?.text = observation?.time
            self.textFields[3]?.text = observation?.driverName
            self.dropDownTextFields[4]?.text = observation?.destination
            self.textFields[5]?.text = observation?.nPassengers
            self.textFields[self.lastTextFieldIndex]?.text = observation?.comments // Comments will always be the last one*/
        }
    }
    
    @objc func getObservationFromNotification(notification: NSNotification) {
        guard let observation = notification.object as? Observation else {
            print("Couldn't downcast observation: \(String(describing: notification.object))")
            return
        }
        self.observation = observation
    }
    
    // MARK: - Navigation
    override func setNavigationBar() {
        /*let screenSize: CGRect = UIScreen.main.bounds
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        self.navigationBar = CustomNavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: screenSize.width, height: 44))*/
        
        super.setNavigationBar()
        
        let navItem = UINavigationItem(title: self.title ?? "")
        self.saveButton = UIBarButtonItem(title: "Save", style: .plain, target: nil, action: #selector(saveButtonPressed))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: #selector(cancelButtonPressed))
        navItem.rightBarButtonItem = self.saveButton
        navItem.leftBarButtonItem = cancelButton
        self.navigationBar.setItems([navItem], animated: false)
        //self.navigationBar.backgroundColor = self.navBarColor
        
        //self.view.addSubview(self.navigationBar)
    }
    
    
    // Dismiss with left to right transiton
    @objc func cancelButtonPressed() {
        dismissController()
    }
    
    
    // Configure tableview controller before it's presented
    @objc func saveButtonPressed() {
        
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        var max: Int64!
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
        } catch {
            print(error.localizedDescription)
        }
        observation?.id = Int(max)
        
        dismissController()
        
    }
    
    func dismissController() {
        if self.isAddingNewObservation {
            // Go back to the addObs menu
            if let presentingController = self.presentingViewController as? BaseTableViewController {
                // The only way this would happen is if the db was deleted while viewing an existing record (in which case isAddingNewObservation is set to true)
                dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
                presentingController.loadData()
            } else if self.qrString.isEmpty {
                //let presentingController = self.presentingViewController!
                self.dismissTransition = RightToLeftTransition()
                dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
            // Dismiss the last 2 controllers (the current one + either the scanner or menu) from the stack to get back to the tableView
            } else if let presentingController = self.presentingViewController?.presentingViewController as? BaseTableViewController ?? self.presentingViewController?.presentingViewController as? AddObservationViewController {
                presentingController.dismiss(animated: true, completion: nil)
            } else {
                dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
            }
        } else {
            // Dismiss this controller to get back to the tableView. Also reload the data.
            // This way, if the database was deleted while on this screen, the table view will only have 1 record and a differet one couldn't be erroneously selected
            self.dismissTransition = LeftToRightTransition()
            dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
            if let presentingController = self.presentingViewController as? BaseTableViewController {
                presentingController.loadData()//tableView.reloadData()
            }
        }
        
        // Deregister notifications from keyboard
        deregisterFromKeyboardNotifications()
    }

    
    //MARK: - Private methods
    
    func checkCurrentDb() -> Bool {
        // Helper function to verify that the data have not been deleted. If so, show an alert and reload the table
        if !currentDbExists() {
            showDbNotExistsAlert()
            print(false)
            self.isAddingNewObservation = true // Because the db will be new, this is a new observation
            return false
        } else {
            print(true)
            return true
        }
    }
    
    
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
        
    }
    
    // Check if the last two records in this table are identical
    func lastRecordDuplicated() -> Bool {
        
        // Check if the table even has more than 1 record, and if not, return false
        if let recordCount = try? db.scalar(self.observationsTable.count), recordCount <= 1 {
            return false
        }
        
        // Check if the observation was made within 5 minutes of the last observation
        
        
        // Get all columns names
        let tableName: String
        if let tname = self.observationsTable.asSQL().components(separatedBy: " ").last {
            // .asSQL() produces simple SQL SELECT stmt, but need to get rid of ""
            tableName = tname.replacingOccurrences(of: "\"", with: "")
        } else {
            return false
        }
        var columnNameString = ""
        if let statement = try? db.prepare(self.observationsTable.asSQL()){
            for (index, colName) in statement.columnNames.enumerated() {
                if colName != "id" && colName != "time" {
                    columnNameString += "\(colName), "
                }
            }
            // Trim off the last ", "
            columnNameString = String(columnNameString[..<columnNameString.index(columnNameString.endIndex, offsetBy: -2)])
        } else {
            return false
        }
        
        // Run SQL to check if the last 2 records are identical
        let sql = "SELECT * FROM \(tableName) WHERE id IN (SELECT id FROM \(tableName) ORDER BY id DESC LIMIT 2) GROUP BY \(columnNameString)"
        var uniqueRowCount = 0
        if let statement = try? db.prepare(sql) {
            for row in statement {
                uniqueRowCount += 1
            }
        }
        
        if uniqueRowCount == 1 {
            // The last 2 were identical
            return true
        } else if uniqueRowCount == 2 {
            // Both rows were unique
            return false
        } else {
            // This should never happen, but just in case return false
            return false
        }
        
    }
    
    
    func showDuplicatedAlert(isNewObservation: Bool) {
        let alertTitle = "Identical record alert"
        let alertMessage = "This observation is identical to the last observation you entered for this type of vehicle. Was this intentional? To save the observation as is, press Yes (you can always edit it afterward, if necessary)."
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: {action in
            self.dismissController()})) //keep record and dismiss the controller
        
        // If this is an update to a new observation, we don't want the user to be able to delete it. Just limit options to saving and cancelling
        if isNewObservation {
            alertController.addAction(UIAlertAction(title: "No", style: .destructive, handler: {action in
                self.deleteLastRecord(controller: alertController); // delete record
                self.dismissController() // dismiss controller
            }))
            alertController.message? += " To remove the observation and start over, press No."
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {action in
            self.deleteLastRecord(controller: alertController)})) // just delete record but allow user to make changes to data
        present(alertController, animated: true, completion: nil)
    }
    
    
    func deleteLastRecord(controller: UIAlertController) {
        
        let deleteErrorController = UIAlertController(title: "Delete error", message: "There was a problem while deleting this observation. You will have to delete it manually", preferredStyle: .alert)
        
        if let maxId = try? db.scalar(self.observationsTable.select(idColumn.max)) {
            let lastRecord = self.observationsTable.filter(idColumn == maxId ?? 2147483647)
            if let deletedId = try? db.run(lastRecord.delete()) {
                print("deleted \(deletedId)")
            } else {
                controller.dismiss(animated: false, completion: nil)
                present(deleteErrorController, animated: true, completion:nil)
            }
        } else {
            controller.dismiss(animated: false, completion: nil)
            present(deleteErrorController, animated: true, completion:nil)
        }
        
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
            os_log("Record insertion failed", log: OSLog.default, type: .debug)
        }
    }
    
    func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
            }
        } catch {
            os_log("Record not found", log: OSLog.default, type: .debug)
        }
    }
    
    private func loadSession() throws { //}-> Session?{
        
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
        let rows = Array(try db.prepare(sessionsTable))
        if rows.count > 1 {
            print("Multiple sessions found")
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
    let busTypeColumn = Expression<String>("bus_type")
    let busNumberColumn = Expression<String>("bus_number")
    let isTrainingColumn = Expression<Bool>("is_training")
    let nOvernightPassengersColumn = Expression<String>("n_lodge_ovrnt")
    
    let destinationLookup = ["Denali Natural History Tour": "Teklanika",
                             "Tundra Wilderness Tour": "Stony Overlook",
                             "Kantishna Experience": "Kantishna",
                             "Camper": "Kantishna",
                             "Spare": "Igloo"]
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Bus type",      placeholder: "Select the type of bus",              type: "dropDown"),
                             (label: "Bus number",    placeholder: "Enter the bus number (printed on the bus)", type: "number"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Training bus?", placeholder: "",                                    type: "checkBox"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (excluding the driver)", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Bus type": parseJSON(controllerLabel: "Bus", fieldName: "Bus type")]
        self.observationsTable = Table("buses")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Bus type",      placeholder: "Select the type of bus",              type: "dropDown"),
                             (label: "Bus number",    placeholder: "Enter the bus number (printed on the bus)", type: "number"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Training bus?", placeholder: "",                                    type: "checkBox"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (excluding the driver)", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Bus type": parseJSON(controllerLabel: "Bus", fieldName: "Bus type")]
        self.observationsTable = Table("buses")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // This needs to go in viewDidAppear() because viewDidLoad() only gets called the first time you push to each type of view controller
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
            
            self.observation = BusObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, driverName: "", destination: "", nPassengers: "", busType: "", busNumber: "", isTraining: false, nOvernightPassengers: "")
            
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = currentTime
            self.textFields[6]?.text = "No"
            self.saveButton.isEnabled = false
            
            if !self.qrString.isEmpty {
                parseQRString()
            }
        // The observation already exists and is open for viewing/editing
        } else {
            // Query the db to get the observation
            if let id = self.observationId {
                guard let record = getObservationRecord(id: id) else {
                    return
                }

                self.observation = BusObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], busType: record[busTypeColumn], busNumber: record[busNumberColumn], isTraining: record[isTrainingColumn], nOvernightPassengers: "0", comments: record[commentsColumn])

                self.dropDownTextFields[0]?.text = self.observation?.observerName
                self.textFields[1]?.text = self.observation?.date
                self.textFields[2]?.text = self.observation?.time
                self.dropDownTextFields[3]?.text = self.observation?.busType
                self.textFields[4]?.text = self.observation?.busNumber
                self.dropDownTextFields[5]?.text = self.observation?.destination
                if (self.observation?.isTraining)! {
                    self.checkBoxes[6]?.isSelected = true
                } else {
                    self.checkBoxes[6]?.isSelected = false
                }
                self.textFields[7]?.text = self.observation?.nPassengers
                self.textFields[8]?.text = self.observation?.comments
                self.saveButton.isEnabled = true
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    

    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        
        if lastRecordDuplicated() {
            showDuplicatedAlert(isNewObservation: self.isAddingNewObservation)
            
        } else {
        
            // Assign the right ID to the observation
            var max: Int64? = 2147483647
            do {
                max = try db.scalar(observationsTable.select(idColumn.max))
                if max == nil {
                    max = 0
                }
            } catch {
                showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
                os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
            }
            observation?.id = Int(max!)
            
            dismissController()
        }
    }
    
    
    // Check if a
    @objc override func dropDownDidChange(notification: NSNotification) {
        
        super.dropDownDidChange(notification: notification)
        
        // Check if the destination field has been filled yet
        let destinationText = self.dropDownTextFields[5]?.text ?? ""
        // If this field is the bus type field and destination hasn't been filled in (wouldn't want to change it unexpectedly)
        if self.textFieldIds[self.currentTextField].label == "Bus type" && destinationText.isEmpty {
            // Check if bus type field is empty, and if it isn't then try to set the destination
            if let busType = self.dropDownTextFields[self.currentTextField]!.text {
                self.dropDownTextFields[5]?.text = destinationLookup[busType] ?? ""
            }
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
        let destination = self.dropDownTextFields[5]?.text ?? ""
        //let isTraining = self.textFields[6]?.text ?? ""
        let nPassengers = self.textFields[7]?.text ?? ""
        let comments = self.textFields[8]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
            !date.isEmpty &&
            !time.isEmpty &&
            !busType.isEmpty &&
            !busNumber.isEmpty &&
            !destination.isEmpty &&
            !nPassengers.isEmpty

        if fieldsFull {
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.busType = busType
            self.observation?.busNumber = busNumber
            self.observation?.destination = destination
            if let isTrainingCheckBox = self.checkBoxes[6] {
                self.observation?.isTraining = isTrainingCheckBox.isSelected
            } else {
                self.observation?.isTraining = false
            }
            /*if isTraining == "Yes" {
                self.observation?.isTraining = true
            } else {
                self.observation?.isTraining = false
            }*/
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
                                                            busTypeColumn <- (self.observation?.busType)!,
                                                            busNumberColumn <- (self.observation?.busNumber)!,
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            isTrainingColumn <- (self.observation?.isTraining)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            nOvernightPassengersColumn <- (self.observation?.nOvernightPassengers)!, //Set when initating new observation in autoFillTextFields()
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Record insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        busTypeColumn <- (self.observation?.busType)!,
                                        busNumberColumn <- (self.observation?.busNumber)!,
                                        isTrainingColumn <- (self.observation?.isTraining)!,
                                        nOvernightPassengersColumn <- (self.observation?.nOvernightPassengers)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Record update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
}

//MARK: -
//MARK: -
class LodgeBusObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: BusObservation?
    let busTypeColumn = Expression<String>("bus_type")
    let busNumberColumn = Expression<String>("bus_number")
    let isTrainingColumn = Expression<Bool>("is_training")
    let nOvernightPassengersColumn = Expression<String>("n_lodge_ovrnt")

    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Lodge",         placeholder: "Select the type of bus",              type: "dropDown"),
                             (label: "Permit number", placeholder: "Enter the permit number (printed on the permit)", type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Training bus?", placeholder: "",                                    type: "checkBox"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (excluding the driver and employees)", type: "number"),
                             (label: "Number of overnight lodge guests", placeholder: "Enter the number of overnight lodge guests (excluding the driver and employees)", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Lodge": parseJSON(controllerLabel: "Lodge Bus", fieldName: "Lodge")]
        
        // These observations still get stored in the buses table. Lodge buses are a separately form because Savage box staff requested it, but that distinction is unnecessary for the DB
        self.observationsTable = Table("buses")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Lodge",         placeholder: "Select the type of bus",              type: "dropDown"),
                             (label: "Permit number", placeholder: "Enter the bus number (printed on the bus)", type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Training bus?", placeholder: "",                                    type: "checkBox"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (excluding the driver and employees)", type: "number"),
                             (label: "Number of overnight lodge guests", placeholder: "Enter the number of overnight lodge guests (excluding the driver and employees)", type: "normal"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Lodge": ["Denali Backcountry Lodge", "Kantishna Roadhouse", "Camp Denali/North Face", "Other"]]
        self.observationsTable = Table("buses")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
        
        // Make sure all alphabetic characters in the permit number field are capitalized (only inholder permits have letters in them)
        for (index, fieldInfo) in self.textFieldIds.enumerated() {
            if fieldInfo.label == "Permit number" {
                self.textFields[index]?.autocapitalizationType = .allCharacters
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // This needs to go in viewDidAppear() because viewDidLoad() only gets called the first time you push to each type of view controller
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
            
            self.observation = BusObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, driverName: "", destination: "Kantishna", nPassengers: "", busType: "", busNumber: "", isTraining: false, nOvernightPassengers: "")
            
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = currentTime
            self.dropDownTextFields[5]?.text = "Kantishna"
            self.textFields[6]?.text = "No"
            self.saveButton.isEnabled = false
            
            parseQRString()
            
            // The observation already exists and is open for viewing/editing
        } else {
            // Query the db to get the observation
            if let id = self.observationId {
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = BusObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], busType: record[busTypeColumn], busNumber: record[busNumberColumn], isTraining: record[isTrainingColumn], nOvernightPassengers: record[nOvernightPassengersColumn], comments: record[commentsColumn])
                
                self.dropDownTextFields[0]?.text = self.observation?.observerName
                self.textFields[1]?.text = self.observation?.date
                self.textFields[2]?.text = self.observation?.time
                self.dropDownTextFields[3]?.text = self.observation?.busType
                self.textFields[4]?.text = self.observation?.busNumber
                self.dropDownTextFields[5]?.text = self.observation?.destination
                if (self.observation?.isTraining)! {
                    self.checkBoxes[6]?.isSelected = true
                } else {
                    self.checkBoxes[6]?.isSelected = false
                }
                self.textFields[7]?.text = self.observation?.nPassengers
                self.textFields[8]?.text  = self.observation?.nOvernightPassengers
                self.textFields[9]?.text = self.observation?.comments
                self.saveButton.isEnabled = true
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        
        if lastRecordDuplicated() {
            showDuplicatedAlert(isNewObservation: self.isAddingNewObservation)
            
        } else {
            
            // Assign the right ID to the observation
            var max: Int64? = 2147483647
            do {
                max = try db.scalar(observationsTable.select(idColumn.max))
                if max == nil {
                    max = 0
                }
            } catch {
                showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
                os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
            }
            observation?.id = Int(max!)
            
            dismissController()
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
        let destination = self.dropDownTextFields[5]?.text ?? ""
        //let isTraining = self.textFields[6]?.text ?? ""
        let nPassengers = self.textFields[7]?.text ?? ""
        let nOvernightPassengers = self.textFields[8]?.text ?? ""
        let comments = self.textFields[9]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !busType.isEmpty &&
                !busNumber.isEmpty &&
                !destination.isEmpty &&
                !nPassengers.isEmpty &&
                !nOvernightPassengers.isEmpty
        
        if fieldsFull {
            
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.busType = busType
            self.observation?.busNumber = busNumber
            self.observation?.destination = destination
            if let isTrainingCheckBox = self.checkBoxes[6] {
                self.observation?.isTraining = isTrainingCheckBox.isSelected
            } else {
                self.observation?.isTraining = false
            }
            /*if isTraining == "Yes" {
                self.observation?.isTraining = true
            } else {
                self.observation?.isTraining = false
            }*/
            self.observation?.nPassengers = nPassengers
            self.observation?.nOvernightPassengers = nOvernightPassengers
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
                                                            busTypeColumn <- (self.observation?.busType)!,
                                                            busNumberColumn <- (self.observation?.busNumber)!,
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            isTrainingColumn <- (self.observation?.isTraining)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            nOvernightPassengersColumn <- (self.observation?.nOvernightPassengers)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Record insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        busTypeColumn <- (self.observation?.busType)!,
                                        busNumberColumn <- (self.observation?.busNumber)!,
                                        isTrainingColumn <- (self.observation?.isTraining)!,
                                        nOvernightPassengersColumn <- (self.observation?.nOvernightPassengers)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Record update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
}




//MARK: -
//MARK: -
class NPSVehicleObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: NPSVehicleObservation?
    let tripPurposeColumn = Expression<String>("trip_purpose")
    let workGroupColumn = Expression<String>("work_group")
    let nExpectedNightsColumn = Expression<String>("n_nights")
    //private let observationsTable = Table("nps_vehicles")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name",     type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",             type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",             type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",            type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",         type: "dropDown"),
                             (label: "Work group",    placeholder: "Select or enter the work group",          type: "dropDown"),
                             (label: "Trip purpose",  placeholder: "Select or enter the purpose of the trip", type: "dropDown"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)",    type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Work group": parseJSON(controllerLabel: "NPS Vehicle", fieldName: "Work group"),
                                    "Trip purpose": parseJSON(controllerLabel: "NPS Vehicle", fieldName: "Trip purpose")]
        self.observationsTable = Table("nps_vehicles")

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name",     type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",             type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",             type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",            type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",         type: "dropDown"),
                             (label: "Work group",    placeholder: "Select or enter the work group",          type: "dropDown"),
                             (label: "Trip purpose",  placeholder: "Select or enter the purpose of the trip", type: "dropDown"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)",    type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    //"Work division": parseJSON(controllerLabel: "NPS Vehicle", fieldName: "Work division"),
                                    "Work group": parseJSON(controllerLabel: "NPS Vehicle", fieldName: "Work group"),
                                    "Trip purpose": parseJSON(controllerLabel: "NPS Vehicle", fieldName: "Trip purpose")]
        self.observationsTable = Table("nps_vehicles")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoFillTextFields()
    }
    
    override func autoFillTextFields() {

        // The observation already exists and is open for viewing/editing
        if self.isAddingNewObservation {
            // Get the current time as a string
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let currentTime = formatter.string(from: now)
            
            // Initialize the observation
            self.observation = NPSVehicleObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, driverName: "", destination: "", nPassengers: "", tripPurpose: "", workGroup: "")
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            
            // Fill text fields with defaults
            self.textFields[2]?.text = currentTime
            //self.dropDownTextFields[7]?.text = "N/A"
            self.textFields[7]?.text = "0"
            self.saveButton.isEnabled = false
            
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = NPSVehicleObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], tripPurpose: record[tripPurposeColumn], workGroup: record[workGroupColumn], comments: record[commentsColumn])
                
                // Fill text fields
                self.dropDownTextFields[0]?.text = self.observation?.observerName
                self.textFields[1]?.text = self.observation?.date
                self.textFields[2]?.text = self.observation?.time
                self.textFields[3]?.text = self.observation?.driverName
                self.dropDownTextFields[4]?.text = self.observation?.destination
                self.dropDownTextFields[5]?.text = self.observation?.workGroup
                self.dropDownTextFields[6]?.text  = self.observation?.tripPurpose
                self.textFields[7]?.text = self.observation?.nExpectedNights
                self.textFields[8]?.text = self.observation?.nPassengers
                self.textFields[9]?.text = self.observation?.comments
                self.saveButton.isEnabled = true
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    
    @objc private func setWorkGroupOptions(){
        // Clear the workgroup field
        dropDownTextFields[6]?.text?.removeAll()
        
        let workGroupField = dropDownJSON["NPS Vehicle"]["Work group"]
        var workGroups = [String: [String]]()
        for (key, array) in workGroupField["options"] {
            var optionsArray = [String]()
            for item in array.arrayValue { optionsArray.append(item.stringValue) }
            workGroups[key] = optionsArray
        }
        
        let division = (dropDownTextFields[5]?.text)!
        
        if workGroups.keys.contains(division) && division != "Other" {
            dropDownTextFields[6]?.dropView.dropDownOptions = workGroups[division]!
            dropDownTextFields[6]?.isEnabled = true
            labels[6].textColor = UIColor.black
        } else { //"Other" was selected and the field was filled manually with keyboard
            dropDownTextFields[6]?.dropView.dropDownOptions = []
            dropDownTextFields[6]?.text = "Other"
            dropDownTextFields[6]?.isEnabled = false
            labels[6].textColor = UIColor.gray
        }
        
        dropDownTextFields[6]?.dropView.tableView.reloadData()
        //dropDownTextFields[6]?.isEnabled = true
        labels[6].text = textFieldIds[6].label
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        
        if lastRecordDuplicated() {
            showDuplicatedAlert(isNewObservation: self.isAddingNewObservation)
            
        } else {
            
            // Assign the right ID to the observation
            var max: Int64? = 2147483647
            do {
                max = try db.scalar(observationsTable.select(idColumn.max))
                if max == nil {
                    max = 0
                }
            } catch {
                showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
                os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
            }
            observation?.id = Int(max!)
            
            dismissController()
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
        let workGroup = self.dropDownTextFields[5]?.text ?? ""
        let tripPurpose = self.dropDownTextFields[6]?.text ?? ""
        let nExpectedNights = self.textFields[7]?.text ?? ""
        let nPassengers = self.textFields[8]?.text ?? ""
        let comments = self.textFields[9]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !driverName.isEmpty &&
                !workGroup.isEmpty &&
                !tripPurpose.isEmpty &&
                !nExpectedNights.isEmpty &&
                !destination.isEmpty &&
                !nPassengers.isEmpty
        
        if fieldsFull {
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.driverName = driverName
            self.observation?.workGroup = workGroup
            self.observation?.tripPurpose = tripPurpose
            self.observation?.nExpectedNights = nExpectedNights
            self.observation?.destination = destination
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
                                                            workGroupColumn <- (self.observation?.workGroup)!,
                                                            tripPurposeColumn <- (self.observation?.tripPurpose)!,
                                                            nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Row insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)

            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        tripPurposeColumn <- (self.observation?.tripPurpose)!,
                                        workGroupColumn <- (self.observation?.workGroup)!,
                                        nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Row update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
}


//MARK: -
//MARK: -
class NPSApprovedObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: NPSApprovedObservation?
    let tripPurposeColumn = Expression<String>("trip_purpose")
    let nExpectedNightsColumn = Expression<String>("n_nights")
    let approvedTypeColumn = Expression<String>("approved_type")
    let permitNumberColumn = Expression<String>("permit_number")
    
    //private let observationsTable = Table("nps_approved")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Approved category",  placeholder: "Select the type of vehicle",          type: "dropDown"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",           type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Approved category": parseJSON(controllerLabel: "NPS Approved", fieldName: "Approved category")]
        
        self.observationsTable = Table("nps_approved")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Approved category",  placeholder: "Select the type of vehicle",          type: "dropDown"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",           type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Approved category": parseJSON(controllerLabel: "NPS Approved", fieldName: "Approved category")]
        
        self.observationsTable = Table("nps_approved")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //autoFillTextFields()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            self.observation = NPSApprovedObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, driverName: "", destination: "", nPassengers: "", approvedType: "", nExpectedNights: "")
            
            // Fill in text fields with defaults
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = currentTime
            self.textFields[7]?.text = "0"
            self.saveButton.isEnabled = false
            
            parseQRString()
            
        // The observation already exists and is open for viewing/editing
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = NPSApprovedObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], approvedType: record[approvedTypeColumn], nExpectedNights: record[nExpectedNightsColumn], permitNumber: record[permitNumberColumn], comments: record[commentsColumn])
                
                // Fill text fields
                self.dropDownTextFields[0]?.text = self.observation?.observerName
                self.textFields[1]?.text = self.observation?.date
                self.textFields[2]?.text = self.observation?.time
                self.dropDownTextFields[3]?.text = self.observation?.approvedType
                self.textFields[4]?.text = self.observation?.driverName
                self.dropDownTextFields[5]?.text = self.observation?.destination
                self.textFields[6]?.text = self.observation?.nPassengers
                self.textFields[7]?.text  = self.observation?.nExpectedNights
                self.textFields[8]?.text = self.observation?.permitNumber
                self.textFields[9]?.text = self.observation?.comments
                self.saveButton.isEnabled = true
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }

        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        
        if lastRecordDuplicated() {
            showDuplicatedAlert(isNewObservation: self.isAddingNewObservation)
            
        } else {
            
            // Assign the right ID to the observation
            var max: Int64? = 2147483647
            do {
                max = try db.scalar(observationsTable.select(idColumn.max))
                if max == nil {
                    max = 0
                }
            } catch {
                showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
                os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
            }
            observation?.id = Int(max!)
            
            dismissController()
        }
    }
    
    //MARK: - Private methods
    @objc override func updateData(){
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let approvedType = self.dropDownTextFields[3]?.text ?? ""
        let driverName = self.textFields[4]?.text ?? ""
        let destination = self.dropDownTextFields[5]?.text ?? ""
        let nPassengers = self.textFields[6]?.text ?? ""
        let nExpectedNights = self.textFields[7]?.text ?? ""
        let permitNumber = self.textFields[8]?.text ?? ""
        let comments = self.textFields[9]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !approvedType.isEmpty &&
                !driverName.isEmpty &&
                !destination.isEmpty &&
                !nPassengers.isEmpty &&
                !nExpectedNights.isEmpty
        
        if fieldsFull {
            
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.approvedType = approvedType
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            self.observation?.nPassengers = nPassengers
            self.observation?.nExpectedNights = nExpectedNights
            self.observation?.permitNumber = permitNumber
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
                                                            approvedTypeColumn <- (self.observation?.approvedType)!,
                                                            driverNameColumn <- (self.observation?.driverName)!,
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                                            permitNumberColumn <- (self.observation?.permitNumber)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Row insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        approvedTypeColumn <- (self.observation?.approvedType)!,
                                        nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                        permitNumberColumn <- (self.observation?.permitNumber)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Row update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
}


//MARK: -
//MARK: -
class NPSContractorObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: NPSContractorObservation?
    let projectTypeColumn = Expression<String>("project_type")
    let nExpectedNightsColumn = Expression<String>("n_nights")
    let organizationNameColumn = Expression<String>("organization")
    let permitNumberColumn = Expression<String>("permit_number")
    //private let observationsTable = Table("nps_contractors")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Company/Organization name", placeholder: "Enter the contractor's company or organization name",   type: "normal"),
                             //(label: "Project type",   placeholder: "Select a the type of project the contract is for (if known)",   type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",           type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations]//"Project type": parseJSON(controllerLabel: "NPS Contractor", fieldName: "Project type")]
        
        self.observationsTable = Table("nps_contractors")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Company/Organization Name", placeholder: "Enter the contractor's company or organization name",   type: "normal"),
                             //(label: "Project type",   placeholder: "Select a the type of project the contract is for (if known)",   type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",           type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations]//"Project type": parseJSON(controllerLabel: "NPS Contractor", fieldName: "Project type")]
        self.observationsTable = Table("nps_contractors")
    }
    
    //MARK: - Layout
    /*override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
    }*/
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            self.observation = NPSContractorObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: formatter.string(from: now), driverName: "", destination: "", nPassengers: "", nExpectedNights: "", organizationName: "")
            
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = formatter.string(from: now)
            self.textFields[7]?.text = "0"
            self.saveButton.isEnabled = false
            
            parseQRString()
            
            // The observation already exists and is open for viewing/editing
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = NPSContractorObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], nExpectedNights: record[nExpectedNightsColumn], organizationName: record[organizationNameColumn], permitNumber: record[permitNumberColumn], comments: record[commentsColumn])
                
                // Fill text fields
                self.dropDownTextFields[0]?.text = self.observation?.observerName
                self.textFields[1]?.text = self.observation?.date
                self.textFields[2]?.text = self.observation?.time
                self.dropDownTextFields[3]?.text = self.observation?.destination
                self.textFields[4]?.text = self.observation?.driverName
                self.textFields[5]?.text = self.observation?.organizationName
                self.textFields[6]?.text = self.observation?.nPassengers
                self.textFields[7]?.text  = self.observation?.nExpectedNights
                self.textFields[8]?.text = self.observation?.permitNumber
                self.textFields[9]?.text = self.observation?.comments
                self.saveButton.isEnabled = true
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        
        if lastRecordDuplicated() {
            showDuplicatedAlert(isNewObservation: self.isAddingNewObservation)
            
        } else {
            
            // Assign the right ID to the observation
            var max: Int64? = 2147483647
            do {
                max = try db.scalar(observationsTable.select(idColumn.max))
                if max == nil {
                    max = 0
                }
            } catch {
                showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
                os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
            }
            observation?.id = Int(max!)
            
            dismissController()
        }
    }
    
    
    //MARK: - Private methods
    @objc override func updateData(){

        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let destination = self.dropDownTextFields[3]?.text ?? ""
        let driverName = self.textFields[4]?.text ?? ""
        let organizationName = self.textFields[5]?.text ?? ""
        let nPassengers = self.textFields[6]?.text ?? ""
        let nExpectedNights = self.textFields[7]?.text ?? ""
        let permitNumber = self.textFields[8]?.text ?? ""
        let comments = self.textFields[9]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !destination.isEmpty &&
                !driverName.isEmpty &&
                !organizationName.isEmpty &&
                !nPassengers.isEmpty &&
                !nExpectedNights.isEmpty
        
        if fieldsFull {
            
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.destination = destination
            self.observation?.driverName = driverName
            self.observation?.organizationName = organizationName
            self.observation?.nPassengers = nPassengers
            self.observation?.nExpectedNights = nExpectedNights
            self.observation?.permitNumber = permitNumber
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
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            driverNameColumn <- (self.observation?.driverName)!,
                                                            organizationNameColumn <- (self.observation?.organizationName)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                                            permitNumberColumn <- (self.observation?.permitNumber)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Row insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        organizationNameColumn <- (self.observation?.organizationName)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                        permitNumberColumn <- (self.observation?.permitNumber)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Row update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
}


//MARK: -
//MARK: -
class EmployeeObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: EmployeeObservation?
    let permitHolderColumn = Expression<String>("permit_holder")
    let permitNumberColumn = Expression<String>("permit_number")
    //private let observationsTable = Table("employee_vehicles")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",   type: "normal"),
                             (label: "Destination",   placeholder: "Select the destination",              type: "dropDown"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",           type: "number"),
                             (label: "Permit holder",   placeholder: "Enter the name of the person the permit was issued to",   type: "normal"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations]
        
        self.observationsTable = Table("employee_vehicles")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",   type: "normal"),
                             (label: "Destination",   placeholder: "Select the destination",              type: "dropDown"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",           type: "number"),
                             (label: "Permit holder",   placeholder: "Enter the name of the person the permit was issued to",   type: "normal"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations]
        
        self.observationsTable = Table("employee_vehicles")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            self.observation = EmployeeObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: formatter.string(from: now), driverName: "", destination: "", nPassengers: "", permitNumber: "", permitHolder: "")
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            
            self.textFields[2]?.text = formatter.string(from: now)
            
            self.saveButton.isEnabled = false
            
            parseQRString()
            
        // The observation already exists and is open for viewing/editing
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = EmployeeObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], permitNumber: record[permitNumberColumn], permitHolder: record[permitHolderColumn], comments: record[commentsColumn])
                
                // Fill text fields
                self.dropDownTextFields[0]?.text = self.observation?.observerName
                self.textFields[1]?.text = self.observation?.date
                self.textFields[2]?.text = self.observation?.time
                self.textFields[3]?.text = self.observation?.driverName
                self.dropDownTextFields[4]?.text = self.observation?.destination
                self.textFields[5]?.text = self.observation?.permitNumber
                self.textFields[6]?.text = self.observation?.permitHolder
                self.textFields[7]?.text = self.observation?.nPassengers
                self.textFields[8]?.text = self.observation?.comments
                self.saveButton.isEnabled = true
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
        
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
        
        if lastRecordDuplicated() {
            showDuplicatedAlert(isNewObservation: self.isAddingNewObservation)
            
        } else {
            
            // Assign the right ID to the observation
            var max: Int64? = 2147483647
            do {
                max = try db.scalar(observationsTable.select(idColumn.max))
                if max == nil {
                    max = 0
                }
            } catch {
                showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
                os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
            }
            observation?.id = Int(max!)
            
            dismissController()
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
        let permitNumber = self.textFields[5]?.text ?? ""
        let permitHolder = self.textFields[6]?.text ?? ""
        let nPassengers = self.textFields[7]?.text ?? ""
        let comments = self.textFields[8]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !driverName.isEmpty &&
                !destination.isEmpty &&
                !(permitHolder.isEmpty || permitNumber.isEmpty) && // Only one needs to be filled
                !nPassengers.isEmpty
        
        if fieldsFull {
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            self.observation?.permitNumber = permitNumber
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
                                                            permitNumberColumn <- (self.observation?.permitNumber)!,
                                                            permitHolderColumn <- (self.observation?.permitHolder)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Row insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)

            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        permitNumberColumn <- (self.observation?.permitNumber)!,
                                        permitHolderColumn <- (self.observation?.permitHolder)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Row update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
}

//MARK: -
//MARK: -
class RightOfWayObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: RightOfWayObservation?
    let permitNumberColumn = Expression<String>("permit_number")
    let permitHolderColumn = Expression<String>("permit_holder")
    let tripPurposeColumn = Expression<String>("trip_purpose")
    //private let observationsTable = Table("inholders")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select the destination",              type: "dropDown"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",   type: "normal"),
                             (label: "Permit holder",   placeholder: "Select the inholder whose permit the driver is using",   type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Permit holder": parseJSON(controllerLabel: "Right of Way", fieldName: "Permit holder")]
        
        self.observationsTable = Table("inholders")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select the destination",              type: "dropDown"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",   type: "normal"),
                             (label: "Permit holder",   placeholder: "Select the inholder whose permit the driver is using",   type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Permit holder": parseJSON(controllerLabel: "Right of Way", fieldName: "Permit holder")]
        
        self.observationsTable = Table("inholders")
    }
    
    //MARK: - Layout
    /*override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
    }*/
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoFillTextFields()
        
        // Make sure all alphabetic characters in the permit number field are capitalized (only inholder permits have letters in them)
        for (index, fieldInfo) in self.textFieldIds.enumerated() {
            if fieldInfo.label == "Permit number" {
                self.textFields[index]?.autocapitalizationType = .allCharacters
            }
        }
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
            self.observation = RightOfWayObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, driverName: "", destination: "Kantishna", nPassengers: "", permitNumber: "", permitHolder: "")
            
            //Fill in text fields
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = currentTime
            self.dropDownTextFields[4]?.text = "Kantishna"
            self.saveButton.isEnabled = false
            
            parseQRString()
            
            // The observation already exists and is open for viewing/editing
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = RightOfWayObservation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], permitNumber: record[permitNumberColumn], permitHolder: record[permitHolderColumn], comments: record[commentsColumn])
                
                // Fill text fields
                self.dropDownTextFields[0]?.text = self.observation?.observerName
                self.textFields[1]?.text = self.observation?.date
                self.textFields[2]?.text = self.observation?.time
                self.textFields[3]?.text = self.observation?.driverName
                self.dropDownTextFields[4]?.text = self.observation?.destination
                self.textFields[5]?.text = self.observation?.permitNumber
                self.dropDownTextFields[6]?.text = self.observation?.permitHolder
                self.textFields[7]?.text = self.observation?.nPassengers
                self.textFields[8]?.text = self.observation?.comments
                self.saveButton.isEnabled = true
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        
        if lastRecordDuplicated() {
            showDuplicatedAlert(isNewObservation: self.isAddingNewObservation)
            
        } else {
            
            // Assign the right ID to the observation
            var max: Int64? = 2147483647
            do {
                max = try db.scalar(observationsTable.select(idColumn.max))
                if max == nil {
                    max = 0
                }
            } catch {
                showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
                os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
            }
            observation?.id = Int(max!)
            
            dismissController()
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
        let permitNumber = self.textFields[5]?.text ?? ""
        let permitHolder = self.dropDownTextFields[6]?.text ?? ""
        let nPassengers = self.textFields[7]?.text ?? ""
        let comments = self.textFields[8]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !driverName.isEmpty &&
                !permitHolder.isEmpty &&
                !permitNumber.isEmpty && 
                !nPassengers.isEmpty
        
        if fieldsFull {
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            self.observation?.permitNumber = permitNumber
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
                                                            permitNumberColumn <- (self.observation?.permitNumber)!,
                                                            permitHolderColumn <- (self.observation?.permitHolder)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Row insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)
            
            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        permitNumberColumn <- (self.observation?.permitNumber)!,
                                        permitHolderColumn <- (self.observation?.permitHolder)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Row update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
}


//MARK: -
//MARK: -
class TeklanikaCamperObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: TeklanikaCamperObservation?
    let hasTekPassColumn = Expression<Bool>("has_tek_pass") // Doesn't need to go in master DB, but need it for data persistence in the app
    //private let observationsTable = Table("tek_campers")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Does the vehicle have a Tek Pass?", placeholder: "",                type: "checkBox"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers]
        
        self.observationsTable = Table("tek_campers")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Does the vehicle have a Tek Pass?", placeholder: "",                type: "checkBox"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers]
        
        self.observationsTable = Table("tek_campers")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            self.observation = TeklanikaCamperObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, destination: "Teklanika", nPassengers: "", hasTekPass: false)
            
            // Fill text fields with defaults
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = formatter.string(from: now)
            //self.textFields[3]?.text = "No"
            
            self.saveButton.isEnabled = false
            
            // The observation already exists and is open for viewing/editing
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = TeklanikaCamperObservation(id: id,
                                                              observerName: record[observerNameColumn],
                                                              date: record[dateColumn],
                                                              time: record[timeColumn],
                                                              destination: record[destinationColumn],
                                                              nPassengers: record[nPassengersColumn],
                                                              hasTekPass: record[hasTekPassColumn],
                                                              driverName: record[driverNameColumn],
                                                              comments: record[commentsColumn])
                self.dropDownTextFields[0]?.text = self.observation?.observerName
                self.textFields[1]?.text = self.observation?.date
                self.textFields[2]?.text = self.observation?.time
                if (self.observation?.hasTekPass)! {
                    self.checkBoxes[3]?.isSelected = true
                } else {
                    self.checkBoxes[3]?.isSelected = false
                }
                self.textFields[4]?.text = self.observation?.nPassengers
                self.textFields[5]?.text = self.observation?.comments
                self.saveButton.isEnabled = true
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        var max: Int64? = 2147483647
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
            os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
        }
        observation?.id = Int(max!)
        
        dismissController()
    }
    
    //MARK: - DB methods
    @objc override func updateData(){
        
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        //let hasTekPass = self.textFields[3]?.text ?? ""
        let nPassengers = self.textFields[4]?.text ?? ""
        let comments = self.textFields[5]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !nPassengers.isEmpty
        
        if fieldsFull {
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            if let hasPassCheckBox = self.checkBoxes[3] {
                self.observation?.hasTekPass = hasPassCheckBox.isSelected
            } else {
                self.observation?.hasTekPass = false
            }
            /*if hasTekPass == "Yes" {
                self.observation?.hasTekPass = true
            } else {
                self.observation?.hasTekPass = false
            }*/
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
                                                            destinationColumn <- (self.observation?.destination)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            hasTekPassColumn <- (self.observation?.hasTekPass)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Row insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)

            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        hasTekPassColumn <- (self.observation?.hasTekPass)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Record update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
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

        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date", type: "date"),
                             (label: "Time",          placeholder: "Select the observation time", type: "time"),
                             (label: "Destination",   placeholder: "Select or enter the destination", type: "dropDown"),
                             (label: "Number of bikes", placeholder: "Enter the total number of bikes", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.observationsTable = Table("cyclists")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date", type: "date"),
                             (label: "Time",          placeholder: "Select the observation time", type: "time"),
                             (label: "Destination",   placeholder: "Select or enter the destination", type: "dropDown"),
                             (label: "Number of bikes", placeholder: "Enter the total number of bikes", type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.observationsTable = Table("cyclists")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoFillTextFields()
    }
    
    override func autoFillTextFields() {
        super.autoFillTextFields()
        // super.autoFillTextFields will fill in what we need if it's a new observation. If not, though, we need to fill everything in because the Observation isn't initialized until after super.autoFill() is called
        if self.isAddingNewObservation {
            // Can get time from text field because super.autfill() already fills it in
            let time = (self.textFields[2]?.text)!
            self.observation = Observation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: time, driverName: "Null", destination: "", nPassengers: "")
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = Observation(id: id, observerName: record[observerNameColumn], date: record[dateColumn], time: record[timeColumn], driverName: record[driverNameColumn], destination: record[destinationColumn], nPassengers: record[nPassengersColumn], comments: record[commentsColumn])
                
                // Fill text fields
                self.dropDownTextFields[0]?.text = observation?.observerName
                self.textFields[1]?.text = observation?.date
                self.textFields[2]?.text = observation?.time
                self.dropDownTextFields[3]?.text = self.observation?.destination
                self.textFields[4]?.text = self.observation?.nPassengers
                self.textFields[5]?.text = self.observation?.comments
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        var max: Int64? = 2147483647
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
            os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
        }
        observation?.id = Int(max!)
        
        dismissController()
    }
    
    
    //MARK: - DB methods
    @objc override func updateData(){
        
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let destination = self.dropDownTextFields[3]?.text ?? ""
        let nPassengers = self.textFields[4]?.text ?? ""
        let comments = self.textFields[5]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !destination.isEmpty &&
                !nPassengers.isEmpty
        
        if fieldsFull {
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.destination = destination
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
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Record insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)

            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Record update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
}


//MARK: -
//MARK: -
class PhotographerObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: PhotographerObservation?
    let permitNumberColumn = Expression<String>("permit_number")
    let nExpectedNightsColumn = Expression<String>("n_nights")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Permit number", placeholder: "Enter the permit number",             type: "number"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.observationsTable = Table("photographers")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Permit number", placeholder: "Enter the permit number",             type: "number"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Number of expected nights", placeholder: "Enter the number of anticipated nights beyond the check station",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.observationsTable = Table("photographers")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            self.observation = PhotographerObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, driverName: "", destination: "", nPassengers: "", permitNumber: "")
            
            // Fill text fields with defaults
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = formatter.string(from: now)
            self.textFields[7]?.text = "0"
            
            self.saveButton.isEnabled = false
            
            parseQRString()
            
            // The observation already exists and is open for viewing/editing
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = PhotographerObservation(id: id,
                                                           observerName: record[observerNameColumn],
                                                           date: record[dateColumn],
                                                           time: record[timeColumn],
                                                           driverName: record[driverNameColumn],
                                                           destination: record[destinationColumn],
                                                           nPassengers: record[nPassengersColumn],
                                                           permitNumber: record[permitNumberColumn],
                                                           nExpectedNights: record[nExpectedNightsColumn],
                                                           comments: record[commentsColumn])
                // Fill text fields
                self.dropDownTextFields[0]?.text = self.observation?.observerName
                self.textFields[1]?.text = self.observation?.date
                self.textFields[2]?.text = self.observation?.time
                self.textFields[3]?.text = self.observation?.driverName
                self.dropDownTextFields[4]?.text = self.observation?.destination
                self.textFields[5]?.text = self.observation?.permitNumber
                self.textFields[6]?.text = self.observation?.nPassengers
                self.textFields[7]?.text = self.observation?.nExpectedNights
                self.textFields[8]?.text = self.observation?.comments
                self.saveButton.isEnabled = true
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        
        if lastRecordDuplicated() {
            showDuplicatedAlert(isNewObservation: self.isAddingNewObservation)
            
        } else {
            
        // Assign the right ID to the observation
        var max: Int64? = 2147483647
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
            os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
        }
        observation?.id = Int(max!)
        
        dismissController()
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
        let permitNumber = self.textFields[5]?.text ?? ""
        let nPassengers = self.textFields[6]?.text ?? ""
        let nExpectedNights = self.textFields[7]?.text ?? ""
        let comments = self.textFields[8]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !driverName.isEmpty &&
                !destination.isEmpty &&
                !nPassengers.isEmpty &&
                !nExpectedNights.isEmpty
        
        if fieldsFull {
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            self.observation?.permitNumber = permitNumber
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
                                                            permitNumberColumn <- (self.observation?.permitNumber)!,
                                                            nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Record insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)

            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        permitNumberColumn <- (self.observation?.permitNumber)!,
                                        nExpectedNightsColumn <- (self.observation?.nExpectedNights)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Record update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
}


//MARK: -
//MARK: -
class AccessibilityObservationViewController: BaseObservationViewController {
    
    //MARK: - Properties
    //MARK: DB properties
    var observation: AccessibilityObservation?
    let tripPurposeColumn = Expression<String>("trip_purpose")
    let permitNumberColumn = Expression<String>("permit_number")

    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Trip purpose": ["Other"]]
        
        self.observationsTable = Table("accessibility")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Trip purpose": ["Other"]]
        
        self.observationsTable = Table("accessibility")
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            self.observation = AccessibilityObservation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: currentTime, driverName: "", destination: "", nPassengers: "")
            
            // Fill text fields with defaults
            self.dropDownTextFields[0]?.text = session?.observerName
            self.textFields[1]?.text = session?.date
            self.textFields[2]?.text = formatter.string(from: now)
            //self.dropDownTextFields[5]?.text = "N/A"
            
            self.saveButton.isEnabled = false
            
            parseQRString()
            
        // The observation already exists and is open for viewing/editing
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = AccessibilityObservation(id: id,
                                                            observerName: record[observerNameColumn],
                                                            date: record[dateColumn],
                                                            time: record[timeColumn],
                                                            driverName: record[driverNameColumn],
                                                            destination: record[destinationColumn],
                                                            nPassengers: record[nPassengersColumn],
                                                            permitNumber: record[permitNumberColumn],
                                                            comments: record[commentsColumn])
                self.dropDownTextFields[0]?.text = self.observation?.observerName
                self.textFields[1]?.text = self.observation?.date
                self.textFields[2]?.text = self.observation?.time
                self.textFields[3]?.text = self.observation?.driverName
                self.dropDownTextFields[4]?.text = self.observation?.destination
                self.textFields[5]?.text = self.observation?.nPassengers
                self.textFields[6]?.text = self.observation?.permitNumber
                self.textFields[7]?.text = self.observation?.comments
                self.saveButton.isEnabled = true
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        var max: Int64? = 2147483647
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
            os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
        }
        observation?.id = Int(max!)
        
        dismissController()
    }
    
    //MARK: - DB methods
    @objc override func updateData(){
        
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let driverName = self.textFields[3]?.text ?? ""
        let destination = self.dropDownTextFields[4]?.text ?? ""
        let nPassengers = self.textFields[5]?.text ?? ""
        let permitNumber = self.textFields[6]?.text ?? ""
        let comments = self.textFields[7]?.text ?? ""
        
        let fieldsFull =
            !observerName.isEmpty &&
                !date.isEmpty &&
                !time.isEmpty &&
                !driverName.isEmpty &&
                !destination.isEmpty &&
                !nPassengers.isEmpty
        
        if fieldsFull {
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.driverName = driverName
            self.observation?.destination = destination
            self.observation?.nPassengers = nPassengers
            self.observation?.permitNumber = permitNumber
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
                                                            permitNumberColumn <- (self.observation?.permitNumber)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Record insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)

            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        permitNumberColumn <- (self.observation?.permitNumber)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Record update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
}


//MARK:-
//MARK:-
class SubsistenceObservationViewController: BaseObservationViewController {
    
    var permitNumberColumn = Expression<String>("permit_number")
    var observation: SubsistenceObservation? //No class specific to this view controller because a hunting observation doesn't add any additional properties to the base class
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Trip purpose": ["Other"]]
        
        self.observationsTable = Table("subsistence")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date",         type: "date"),
                             (label: "Time",          placeholder: "Select the observation time",         type: "time"),
                             (label: "Driver's full name", placeholder: "Enter the driver's full name",        type: "normal"),
                             (label: "Destination",   placeholder: "Select or enter the destination",     type: "dropDown"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Permit number",   placeholder: "Enter the permit number (printed on the permit)",   type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.dropDownMenuOptions = ["Observer name": observers,
                                    "Destination": destinations,
                                    "Trip purpose": ["Other"]]
        
        self.observationsTable = Table("subsistence")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoFillTextFields()
    }
    
    // This portion of viewDidLoad() needs to be easily overridable to customize the order of texr fields
    override func autoFillTextFields(){
        super.autoFillTextFields()
        
        // Initialize the observation. Also, fill destination field with default.
        if self.isAddingNewObservation {
            self.observation = SubsistenceObservation(id: -1, observerName: "", date: (session?.date)!, time: self.textFields[2]!.text!, driverName: "", destination: "Kantishna", nPassengers: "")
            self.dropDownTextFields[4]?.text = "Kantishna"
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = SubsistenceObservation(id: id,
                                                          observerName: record[observerNameColumn],
                                                          date: record[dateColumn],
                                                          time: record[timeColumn],
                                                          driverName: record[driverNameColumn],
                                                          destination: record[destinationColumn],
                                                          nPassengers: record[nPassengersColumn],
                                                          permitNumber: record[permitNumberColumn],
                                                          comments: record[commentsColumn])
                self.dropDownTextFields[0]?.text = observation?.observerName
                self.textFields[1]?.text = observation?.date
                self.textFields[2]?.text = observation?.time
                self.textFields[3]?.text = observation?.driverName
                self.dropDownTextFields[4]?.text = observation?.destination
                self.textFields[5]?.text = observation?.nPassengers
                self.textFields[6]?.text = observation?.permitNumber
                self.textFields[7]?.text = observation?.comments
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    //MARK: - DB methods
    @objc override func updateData(){
        super.updateData()
        
        // Would be enabled in super.updateData if all fields are full
        if self.saveButton.isEnabled {
            // Update the observation instance
            self.observation?.observerName = self.dropDownTextFields[0]!.text!
            self.observation?.date = self.textFields[1]!.text!
            self.observation?.time = self.textFields[2]!.text!
            self.observation?.driverName = self.textFields[3]!.text!
            self.observation?.destination = self.dropDownTextFields[4]!.text!
            self.observation?.nPassengers = self.textFields[5]!.text!
            self.observation?.permitNumber = self.textFields[6]!.text!
            self.observation?.comments = self.textFields[7]!.text!
            
            //self.saveButton.isEnabled = true
        }
    }
    
    // Need to override these methods even though they're identical to the super's because super.observation has to be private in order for other classes to override this property with a different type of observation
    override func insertRecord() {
        // Can just get text values from the observation because it has to be updated before saveButton is enabled
        let observerName = observation?.observerName
        let date = observation?.date
        let time = observation?.time
        let driverName = observation?.driverName
        let destination = observation?.destination
        let nPassengers = observation?.nPassengers
        let permitNumber = observation?.permitNumber
        let comments = observation?.comments
        
        // Insert into DB
        do {
            let rowid = try db.run(observationsTable.insert(observerNameColumn <- observerName!,
                                                            dateColumn <- date!,
                                                            timeColumn <- time!,
                                                            driverNameColumn <- driverName!,
                                                            destinationColumn <- destination!,
                                                            nPassengersColumn <- nPassengers!,
                                                            permitNumberColumn <- permitNumber!,
                                                            commentsColumn <- comments!))
        } catch {
            os_log("Record insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)

            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        permitNumberColumn <- (self.observation?.permitNumber)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Record update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        var max: Int64? = 2147483647
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
            os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
        }
        observation?.id = Int(max!)
        
        dismissController()
    }
}


//MARK:-
//MARK:-
class RoadLotteryObservationViewController: BaseObservationViewController {
    
    var observation: RoadLotteryObservation?
    let permitNumberColumn = Expression<String>("permit_number")
    
    // MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date", type: "date"),
                             (label: "Time",          placeholder: "Select the observation time", type: "time"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Permit number", placeholder: "Enter the permit number",  type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.observationsTable = Table("road_lottery")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date", type: "date"),
                             (label: "Time",          placeholder: "Select the observation time", type: "time"),
                             (label: "Number of passengers", placeholder: "Enter the number of passengers (including driver)", type: "number"),
                             (label: "Permit number", placeholder: "Enter the permit number",  type: "number"),
                             (label: "Comments",      placeholder: "Enter additional comments (optional)", type: "normal")]
        
        self.observationsTable = Table("road_lottery")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoFillTextFields()
    }
    
    
    // This portion of viewDidLoad() needs to be easily overridable to customize the order of texr fields
    override func autoFillTextFields(){
        super.autoFillTextFields()
        
        // Initialize the observation. Also, fill destination field with default.
        if self.isAddingNewObservation {
            self.observation = RoadLotteryObservation(id: -1, observerName: "",
                                                      date: (session?.date)!,
                                                      time: self.textFields[2]!.text!,
                                                      driverName: "Null", destination: "Null",
                                                      nPassengers: "",
                                                      permitNumber: "-1")
            //self.textFields[4]?.text = "-1"
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = RoadLotteryObservation(id: id,
                                                          observerName: record[observerNameColumn],
                                                          date: record[dateColumn],
                                                          time: record[timeColumn],
                                                          driverName: record[driverNameColumn],
                                                          destination: record[destinationColumn],
                                                          nPassengers: record[nPassengersColumn],
                                                          permitNumber: record[permitNumberColumn],
                                                          comments: record[commentsColumn])
                self.dropDownTextFields[0]?.text = observation?.observerName
                self.textFields[1]?.text = observation?.date
                self.textFields[2]?.text = observation?.time
                self.textFields[3]?.text = observation?.nPassengers
                self.textFields[4]?.text = observation?.permitNumber
                self.textFields[5]?.text = observation?.comments
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    //MARK: - DB methods
    @objc override func updateData(){
        //super.updateData()
        
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let time = self.textFields[2]?.text ?? ""
        let nPassengers = self.textFields[3]?.text ?? ""
        let permitNumber = self.textFields[4]?.text ?? "-1" //This is an optional field for now
        let comments = self.textFields[5]?.text ?? ""

        
        if !observerName.isEmpty && !date.isEmpty && !time.isEmpty && !nPassengers.isEmpty {//}&& !permitNumber.isEmpty {
            // Update the observation instance
            self.observation?.observerName = observerName
            self.observation?.date = date
            self.observation?.time = time
            self.observation?.nPassengers = nPassengers
            self.observation?.permitNumber = permitNumber
            self.observation?.comments = comments
            
            self.saveButton.isEnabled = true
        }
    }
    
    // Need to override these methods even though they're identical to the super's because super.observation has to be private in order for other classes to override this property with a different type of observation
    override func insertRecord() {
        
        // Insert into DB
        do {
            let rowid = try db.run(observationsTable.insert(observerNameColumn <- (self.observation?.observerName)!,
                                                            dateColumn <- (self.observation?.date)!,
                                                            timeColumn <- (self.observation?.time)!,
                                                            nPassengersColumn <- (self.observation?.nPassengers)!,
                                                            permitNumberColumn <- (self.observation?.permitNumber)!,
                                                            commentsColumn <- (self.observation?.comments)!))
        } catch {
            os_log("Record insertion failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not insert new record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)

            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        permitNumberColumn <- (self.observation?.permitNumber)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
                showGenericAlert(message: "Could not update record because the record with id \(String(describing: self.observation?.id)) could not be found", title: "Database error")
            }
        } catch {
            os_log("Record update failed", log: OSLog.default, type: .debug)
            showGenericAlert(message: "Could not update record because \(error.localizedDescription)", title: "Database error")
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        var max: Int64? = 2147483647
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
            os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
        }
        observation?.id = Int(max!)
        
        dismissController()
    }
}


//MARK:-
//MARK:-
class OtherObservationViewController: BaseObservationViewController {
    
    var observation: Observation? //No class specific to this view controller because a hunting observation doesn't add any additional properties to the base class
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.observationsTable = Table("other_vehicles")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.observationsTable = Table("other_vehicles")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autoFillTextFields()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoFillTextFields()
    }
    
    // This portion of viewDidLoad() needs to be easily overridable to customize the order of texr fields
    override func autoFillTextFields(){
        super.autoFillTextFields()
        
        // Initialize the observation. Also, fill destination field with default.
        if self.isAddingNewObservation {
            self.observation = Observation(id: -1, observerName: session?.observerName ?? "", date: session?.date ?? "", time: self.textFields[2]?.text ?? "", driverName: "", destination: "Null", nPassengers: "")
            //self.dropDownTextFields[4]?.text = "N/A"
        } else {
            if let id = self.observationId {
                // Load observation
                guard let record = getObservationRecord(id: id) else {
                    return
                }
                self.observation = Observation(id: id,
                                               observerName: record[observerNameColumn],
                                               date: record[dateColumn],
                                               time: record[timeColumn],
                                               driverName: record[driverNameColumn],
                                               destination: record[destinationColumn],
                                               nPassengers: record[nPassengersColumn],
                                               comments: record[commentsColumn])
                self.dropDownTextFields[0]?.text = observation?.observerName
                self.textFields[1]?.text = observation?.date
                self.textFields[2]?.text = observation?.time
                self.textFields[3]?.text = observation?.driverName
                self.dropDownTextFields[4]?.text = observation?.destination
                self.textFields[5]?.text = observation?.nPassengers
                self.textFields[6]?.text = observation?.comments
            } else {
                os_log("Could not load data because no ID passed from the tableViewController", log: .default, type: .debug)
                showGenericAlert(message: "Could not load data because no ID passed from the tableViewController. If you save your entry, it will be an entirely new observation", title: "Error")
                self.isAddingNewObservation = true
            }
        }
    }
    
    //MARK: - DB methods
    @objc override func updateData(){
        super.updateData()
        
        // Would be enabled in super.updateData if all fields are full
        if self.saveButton.isEnabled {
            // Update the observation instance
            self.observation?.observerName = self.dropDownTextFields[0]!.text!
            self.observation?.date = self.textFields[1]!.text!
            self.observation?.time = self.textFields[2]!.text!
            self.observation?.driverName = self.textFields[3]!.text!
            self.observation?.destination = self.dropDownTextFields[4]!.text!
            self.observation?.nPassengers = self.textFields[5]!.text!
            self.observation?.comments = self.textFields[6]!.text!
            
            //self.saveButton.isEnabled = true
        }
    }
    
    // Need to override these methods even though they're identical to the super's because super.observation has to be private in order for other classes to override this property with a different type of observation
    override func insertRecord() {
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
            os_log("Record insertion failed", log: OSLog.default, type: .debug)
        }
    }
    
    
    override func updateRecord() {
        do {
            // Select the record to update
            let record = observationsTable.filter(idColumn == (observation?.id.datatypeValue)!)

            // Update all fields
            if try db.run(record.update(observerNameColumn <- (self.observation?.observerName)!,
                                        dateColumn <- (self.observation?.date)!,
                                        timeColumn <- (self.observation?.time)!,
                                        driverNameColumn <- (self.observation?.driverName)!,
                                        destinationColumn <- (self.observation?.destination)!,
                                        nPassengersColumn <- (self.observation?.nPassengers)!,
                                        commentsColumn <- (self.observation?.comments)!)) > 0 {
            } else {
                os_log("Record not found", log: OSLog.default, type: .debug)
            }
        } catch {
            os_log("Record update failed", log: OSLog.default, type: .debug)
        }
    }
    
    //MARK:  - Navigation
    @objc override func saveButtonPressed() {
        if !checkCurrentDb() { return }
        // Reconnect in case the last time save button was pressed, the db didn't exist
        self.db = try? Connection(dbPath)
        
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
        var max: Int64? = 2147483647
        do {
            max = try db.scalar(observationsTable.select(idColumn.max))
            if max == nil {
                max = 0
            }
        } catch {
            showGenericAlert(message:"Problem saving data: \(error.localizedDescription)", title: "Database error")
            os_log("failed to save data properly because the observationID could not be properly set", log: .default, type: .debug)
        }
        observation?.id = Int(max!)
        
        dismissController()
    }
}



