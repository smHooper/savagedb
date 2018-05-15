//
//  Session.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/10/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import Foundation
import UIKit


class Session {
    
    //MARK: Properties
    var observerName: String
    var date: String // Store as string because Swift almost certainly uses different epoch than Python
    // Make open/close times optional because in a given session, someone probably either opens, closes, or neither
    var openTime: String
    var closeTime: String
    
    init?(observerName: String, openTime: String?, closeTime: String?, givenDate: String?){
        
        // Check that all required attributes are non-mepty
        guard !observerName.isEmpty else {
            return nil
        }
        guard !(openTime?.isEmpty)! else {
            return nil
        }
        guard !(closeTime?.isEmpty)! else {
            return nil
        }
        
        //If date is not given or is empty
        if !(givenDate?.isEmpty)! {
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            self.date = formatter.string(from: now)
        } else {
            self.date = givenDate!
        }

        self.observerName = observerName
        self.openTime = openTime!
        self.closeTime = closeTime!
    }
    
    
}
