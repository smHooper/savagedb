//
//  CustomDatePicker.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit

class CustomDatetimePickerControl: UIView {
    
    let datetimePickerView = UIDatePicker()
    var doneButton: UIBarButtonItem!
    var assignedTextField: UITextField!
    var viewController: UIViewController!
    var datetimeMode = "Date"

    
    //MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    func setupDatetimePicker(textField: UITextField, viewController: UIViewController){

        self.assignedTextField = textField
        self.viewController = viewController
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.viewController.view.frame.size.height/6, width: viewController.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: viewController.view.frame.size.width/2, y: self.viewController.view.frame.size.height-20.0)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self.viewController, action: #selector(donePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self.viewController, action: nil)
        toolBar.setItems([flexSpace, doneButton, flexSpace], animated: true)
        
        self.datetimePickerView.tag = self.assignedTextField.tag
        
        // Make sure this is added to the controller when openTimeTextFieldEditing is called
        //openTimeTextField.inputAccessoryView = toolBar
        self.assignedTextField.inputAccessoryView = toolBar
        
        
        // Set up the datetimepicker
        // Use the current time if one has not been set yet
        let now = Date()
        let formatter = DateFormatter()
        
        // Check if this is a time or date field
        switch(self.datetimeMode){
        case "time":
            datetimePickerView.datePickerMode = UIDatePickerMode.time
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        case "date":
            datetimePickerView.datePickerMode = UIDatePickerMode.date
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        default:
            print("textfield \(self.assignedTextField.tag) passed to setupDatetimePicker was of type \(datetimeMode)")
            os_log("wrong type of field passed to setUpDatetimePicker()", log: .default, type: .debug)
        }
        
        self.assignedTextField.inputView = self.datetimePickerView
        //datetimePickerView.addTarget(self, action: #selector(handleDatetimePicker), for: UIControlEvents.valueChanged)
        
        
        // Set the default time to now
        if self.assignedTextField.text?.isEmpty ?? false {
            self.assignedTextField.text = formatter.string(from: now)
        }
        
    }
    
    
    @objc func donePressed(sender: UIBarButtonItem) {
        
        if let currentValue = sender.text {
            var datetimeString = formatDatetime(textFieldId: sender.tag, date: sender.date)
            
            // If this is a date field, check if the date is today. If not, send an alert to make sure this is intentional
            if self.datetimeMode == "date" {
                let today = Date()
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .none
                let todayString = formatter.string(from: today)
                if datetimeString != todayString && sendDateEntryAlert {
                    let alertTitle = "Date Entry Alert"
                    let alertMessage = "You selected a date other than today. Was this intentional? If not, press Cancel."
                    let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: {action in self.dismissInputView(); self.assignedTextField.text = datetimeString}))
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {handler in datetimeString = currentValue}))
                    alertController.addAction(UIAlertAction(title: "Yes, and don't ask again", style: .default, handler: {handler in self.dismissInputView(); self.assignedTextField.text = datetimeString;
                        sendDateEntryAlert = false}))
                    present(alertController, animated: true, completion: nil)
                } else {
                    self.assignedTextField.text = datetimeString
                }
            } else {
                self.assignedTextField.text = datetimeString
            }
            
        } else {
            print("No text field matching datetimPicker id \(sender.tag) found")
            os_log("Bad notification sent to handleDatetimePicker. No matcing datetimePicker id found", log: .default, type: .debug)
            showGenericAlert(message: "No text field matching datetimPicker id \(sender.tag) found", title: "Unknown datetime field")
        }
        
        self.assignedTextField.resignFirstResponder()
    }
    
    
    func formatDatetime(date: Date) -> String {
        let formatter = DateFormatter()
        
        // Set the formatter style for either a date or time
        //let fieldType = self.textFieldIds[textFieldId].type
        switch(self.datetimeMode){
        case "time":
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        case "date":
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        default:
            print("textfield \(self.datetimePickerView.tag) passed to setupDatetimePicker was of type \(self.datetimeMode)")
            os_log("wrong type of field passed to formatDatetime()", log: .default, type: .debug)
        }
        
        let datetimeString = formatter.string(from: date)
        
        return datetimeString
    }
    
}
