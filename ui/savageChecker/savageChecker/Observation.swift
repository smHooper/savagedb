//
//  Observation.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import Foundation
import os.log


class Observation {//: NSObject, NSCoding {
    
    //MARK: Properties
    var id: Int
    var time: String
    var date: String
    var observerName: String
    var driverName: String
    var destination: String
    var nPassengers: String
    
    //MARK: Archiving paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("observations")
    
    //MARK: Types
    struct PropertyKey{
        static let time = "time"
        static let date = "date"
        static let observerName = "observerName"
        static let driverName = "driverName"
        static let destination = "destination"
        static let nPassengers = "nPassengers"
    }
    
    init?(session: Session, id: Int, time: String, driverName: String, destination: String, nPassengers: String){
        // All observations must belong to a session, and observer name and date are pulled directly from that session
        if session.observerName.isEmpty {
            return nil
        }
        if session.date.isEmpty {
            return nil
        }
        
        //Initialize stored properties
        //self.session = session
        self.id = id
        self.time = time // make this optional and set to now if empty
        self.driverName = driverName
        self.destination = destination
        self.nPassengers = nPassengers
        self.date = session.date
        self.observerName = session.observerName
    }
    
    /*//MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(time, forKey: PropertyKey.time)
        aCoder.encode(date, forKey: PropertyKey.date)
        aCoder.encode(observerName, forKey: PropertyKey.observerName)
        aCoder.encode(driverName, forKey: PropertyKey.driverName)
        aCoder.encode(destination, forKey: PropertyKey.destination)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // Try to initialize all required attributes
        guard let time = aDecoder.decodeObject(forKey: PropertyKey.time) as? String else {
            os_log("Unable to decode the name for an Observation object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let date = aDecoder.decodeObject(forKey: PropertyKey.date) as? String else {
            os_log("Unable to decode the name for an Observation object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let observerName = aDecoder.decodeObject(forKey: PropertyKey.observerName) as? String else {
            os_log("Unable to decode the name for an Observation object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let driverName = aDecoder.decodeObject(forKey: PropertyKey.driverName) as? String else {
            os_log("Unable to decode the name for an Observation object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let destination = aDecoder.decodeObject(forKey: PropertyKey.destination) as? String else {
            os_log("Unable to decode the name for an Observation object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let nPassengers = aDecoder.decodeObject(forKey: PropertyKey.nPassengers) as? String else {
            os_log("Unable to decode the name for an Observation object.", log: OSLog.default, type: .debug)
            return nil
        }
        let session = Session(observerName: observerName, openTime: "12:00 AM", closeTime: "12:00 PM", givenDate: date)
        self.init(session: session!, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers)
    }*/
}


/*class BusObservation: Observation {
    
    var busNumber: String?
    var busType: String?
    
    init?(session: Session, time: String, driverName: String, destination: String, nPassengers: String, busType: String, busNumber: String){
        super.init(session: session, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers)
        
        self.busType = busType
        self.busNumber = busNumber
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}*/


