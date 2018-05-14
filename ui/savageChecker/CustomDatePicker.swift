//
//  CustomDatePicker.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

/*import UIKit

class CustomDatePicker: UIDatePicker {
    
    var assignedTextField: UITextField!
    var viewController: UIViewController!

    init(textField: UITextField, viewController: UIViewController){
        //super.init()

        
        self.assignedTextField = textField
        self.viewController = viewController
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.viewController.view.frame.size.height/6, width: viewController.view.frame.size.width, height: 40.0))
        toolBar.layer.position = CGPoint(x: viewController.view.frame.size.width/2, y: self.viewController.view.frame.size.height-20.0)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self.viewController, action: #selector(donePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self.viewController, action: nil)
        toolBar.setItems([flexSpace, doneButton, flexSpace], animated: true)
        
        // Make sure this is added to the controller when openTimeTextFieldEditing is called
        //openTimeTextField.inputAccessoryView = toolBar
        assignedTextField.inputAccessoryView = toolBar
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Check that the done button on custom DatePicker was pressed
    @objc func donePressed(sender: UIBarButtonItem) {
        assignedTextField.resignFirstResponder()
    }
    
}*/

/*//
 //  CustomDatePicker.swift
 //  savageChecker
 //
 //  Created by Sam Hooper on 5/10/18.
 //  Copyright © 2018 Sam Hooper. All rights reserved.
 //
 
 import UIKit
 import Foundation
 
 class CustomDateField: UIDatePicker {
 var textField: UITextField!
 var viewController: UIViewController!
 
 init(textField: UITextField){
 super.init()
 }
 
 required init?(coder aDecoder: NSCoder) {
 fatalError("init(coder:) has not been implemented")
 }
 @objc func dismiss(sender: UIBarButtonItem) {
 textField.resignFirstResponder()
 }
 }*/
