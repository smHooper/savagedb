//
//  Observation.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import Foundation
import os.log


class Observation {
    
    //MARK: Properties
    var id: Int
    var time: String
    var date: String
    var observerName: String
    var driverName: String
    var destination: String
    var nPassengers: String
    var comments: String
    
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
    
    init?(id: Int, observerName: String, date: String, time: String, driverName: String, destination: String, nPassengers: String, comments: String = ""){
        /*// All observations must belong to a session, and observer name and date are pulled directly from that session
        if session.observerName.isEmpty {
            return nil
        }
        if session.date.isEmpty {
            return nil
        }*/
        
        
        //Initialize stored properties
        //self.session = session
        self.id = id
        self.observerName = observerName
        self.date = date
        self.time = time // make this optional and set to now if empty
        self.driverName = driverName
        self.destination = destination
        self.nPassengers = nPassengers
        self.comments = comments
    }
    
}


class BusObservation: Observation {
    
    var busNumber: String?
    var busType: String?
    var isTraining: Bool?
    var nOvernightPassengers = 0
    
    // Not stored in DB
    private var isLodgeBus = false
    
    init?(id: Int, observerName: String, date: String, time: String, driverName: String, destination: String, nPassengers: String, busType: String, busNumber: String, isTraining: Bool, nOvernightPassengers: Int = 0){
        super.init(id: id, observerName: observerName, date: date, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers)
        
        self.busType = busType
        self.busNumber = busNumber
        self.isTraining = isTraining
        self.nOvernightPassengers = nOvernightPassengers
        
    }

}


