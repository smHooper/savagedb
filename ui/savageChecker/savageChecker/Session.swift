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


class Session {//}: NSObject, NSCoding {
    
    //MARK: Properties
    var id: Int
    var observerName: String
    var date: String // Store as string because Swift almost certainly uses different epoch than Python
    var openTime: String
    var closeTime: String
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("session")
    
    //MARK: Types
    struct PropertyKey {
        static let observerName = "observer_name"
        static let date = "date"
        static let openTime = "open_time"
        static let closeTime = "close_time"
    }
    
    init?(id: Int, observerName: String, openTime: String?, closeTime: String?, givenDate: String? = ""){
        
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
        if (givenDate?.isEmpty)! {
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            self.date = formatter.string(from: now)
        } else {
            self.date = givenDate!
        }
        
        self.id = id
        self.observerName = observerName
        self.openTime = openTime!
        self.closeTime = closeTime!
    }
    
}
