//
//  Session.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/10/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import Foundation
import UIKit
import os.log


class Session: NSObject, NSCoding {
    
    //MARK: Properties
    var observerName: String
    var date: String // Store as string because Swift almost certainly uses different epoch than Python
    var openTime: String
    var closeTime: String
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("session")
    
    //MARK: Types
    struct PropertyKey {
        static let observerName = "observerName"
        static let date = "date"
        static let openTime = "openTime"
        static let closeTime = "closeTime"
    }
    
    init?(observerName: String, openTime: String?, closeTime: String?, givenDate: String? = ""){
        
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
            formatter.dateStyle = .short
            self.date = formatter.string(from: now)
        } else {
            self.date = givenDate!
        }

        self.observerName = observerName
        self.openTime = openTime!
        self.closeTime = closeTime!
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(observerName, forKey: PropertyKey.observerName)
        aCoder.encode(date, forKey: PropertyKey.date)
        aCoder.encode(openTime, forKey: PropertyKey.openTime)
        aCoder.encode(closeTime, forKey: PropertyKey.closeTime)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        // Initialize required properties.
        guard let observerName = aDecoder.decodeObject(forKey: PropertyKey.observerName) as? String else {
            os_log("Unable to decode the name for a Session object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let date = aDecoder.decodeObject(forKey: PropertyKey.date) as? String else {
            os_log("Unable to decode the name for a Session object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let openTime = aDecoder.decodeObject(forKey: PropertyKey.openTime) as? String else {
            os_log("Unable to decode the name for a Session object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let closeTime = aDecoder.decodeObject(forKey: PropertyKey.closeTime) as? String else {
            os_log("Unable to decode the name for a Session object.", log: OSLog.default, type: .debug)
            return nil
        }

        self.init(observerName: observerName, openTime: openTime, closeTime: closeTime, givenDate: date)
    }
    
}
