//
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
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func dismiss(sender: UIBarButtonItem) {
        textField.resignFirstResponder()
    }
}//*/
