//
//  UserData.swift
//  savageChecker
//
//  Created by Sam Hooper on 8/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import Foundation
import os.log

class UserData: NSObject, NSCoding {
    
    //MARK: Properties
    let creationDate: String
    var lastModifiedTime: Date
    var activeDatabase: String
    
    //MARK: Archiving Paths
    static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveURL = documentsDirectory.appendingPathComponent("userData")
    
    //MARK: Types
    struct PropertyKey {
        static let creationDate = "creationDate"
        static let lastModifiedTime = "lastModifiedTime"
        static let activeDatabase = "activeDatabase"
    }
    
    init?(creationDate: String, lastModifiedTime: Date, activeDatabase: String){
        
        // Check that all required attributes are non-mepty
        guard !activeDatabase.isEmpty else {
            return nil
        }
        
        self.creationDate = creationDate
        self.lastModifiedTime = lastModifiedTime
        self.activeDatabase = activeDatabase
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.creationDate, forKey: PropertyKey.creationDate)
        aCoder.encode(self.lastModifiedTime, forKey: PropertyKey.lastModifiedTime)
        aCoder.encode(self.activeDatabase, forKey: PropertyKey.activeDatabase)
    }
    
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        // Initialize required properties.
        guard let creationDate = aDecoder.decodeObject(forKey: PropertyKey.creationDate) as? String else {
            os_log("Unable to decode the name for a UserData object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let lastModifiedTime = aDecoder.decodeObject(forKey: PropertyKey.lastModifiedTime) as? Date else {
            os_log("Unable to decode the name for a UserData object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let activeDatabase = aDecoder.decodeObject(forKey: PropertyKey.activeDatabase) as? String else {
            os_log("Unable to decode the name for a UserData object.", log: OSLog.default, type: .debug)
            return nil
        }

        self.init(creationDate: creationDate, lastModifiedTime: lastModifiedTime, activeDatabase: activeDatabase)
    }
    
    
    func update(databaseFileName: String) {
        self.activeDatabase = databaseFileName
        self.lastModifiedTime = Date() //Date() always returns current date/time
        
        // Save it to disk
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self, toFile: userDataPath)
        if isSuccessfulSave {
            os_log("User data successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save user data...", log: OSLog.default, type: .error)
        }
    }

}
