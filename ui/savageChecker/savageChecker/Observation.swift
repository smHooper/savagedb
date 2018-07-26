//
//  Observation.swift
//  savageChecker
//
//  Definition of all vehicle observation classes
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
    
    var busType: String?
    var busNumber: String?
    var isTraining: Bool?
    var nOvernightPassengers = "0"
    
    // Not stored in DB
    private var isLodgeBus = false
    
    init?(id: Int, observerName: String, date: String, time: String, driverName: String, destination: String, nPassengers: String, busType: String, busNumber: String, isTraining: Bool, nOvernightPassengers: String = "0", comments: String = ""){
        
        super.init(id: id, observerName: observerName, date: date, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers, comments: comments)
        
        self.busType = busType
        self.busNumber = busNumber
        self.isTraining = isTraining
        self.nOvernightPassengers = nOvernightPassengers
    }
}

class NPSVehicleObservation: Observation {
    
    var tripPurpose: String?
    var workDivision: String?
    var workGroup: String?
    var nExpectedNights = "0"
    
    init?(id: Int, observerName: String, date: String, time: String, driverName: String, destination: String, nPassengers: String, tripPurpose: String, workDivision: String, workGroup: String, nExpectedNights: String = "0", comments: String = ""){
        
        super.init(id: id, observerName: observerName, date: date, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers, comments: comments)
        
        self.tripPurpose = tripPurpose
        self.workDivision = workDivision
        self.workGroup = workGroup
        self.nExpectedNights = nExpectedNights
    }
}

class NPSApprovedObservation: Observation {
    
    var vehicleType: String?
    var tripPurpose: String?
    var nExpectedNights = "0"
    
    init?(id: Int, observerName: String, date: String, time: String, driverName: String, destination: String, nPassengers: String, vehicleType: String, tripPurpose: String, nExpectedNights: String = "0", comments: String = ""){
        
        super.init(id: id, observerName: observerName, date: date, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers, comments: comments)
        
        self.vehicleType = vehicleType
        self.tripPurpose = tripPurpose
        self.nExpectedNights = nExpectedNights
        
    }
}

class NPSContractorObservation: Observation {
    
    var tripPurpose: String?
    var nExpectedNights = "0"
    
    init?(id: Int, observerName: String, date: String, time: String, driverName: String, destination: String, nPassengers: String, tripPurpose: String, nExpectedNights: String = "0", comments: String = ""){
        
        super.init(id: id, observerName: observerName, date: date, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers, comments: comments)
        
        self.tripPurpose = tripPurpose
        self.nExpectedNights = nExpectedNights
    }
}


class EmployeeObservation: Observation {
    
    var permitHolder: String?
    
    init?(id: Int, observerName: String, date: String, time: String, driverName: String, destination: String, nPassengers: String, permitHolder: String, comments: String = ""){
        
        super.init(id: id, observerName: observerName, date: date, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers, comments: comments)
        
        self.permitHolder = permitHolder
    }
}


class RightOfWayObservation: Observation {
    
    var tripPurpose: String?
    var permitNumber: String?
    
    init?(id: Int, observerName: String, date: String, time: String, driverName: String, destination: String = "Kantishna", nPassengers: String, permitNumber: String, tripPurpose: String = "N/A", comments: String = ""){
        
        super.init(id: id, observerName: observerName, date: date, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers, comments: comments)
        
        self.permitNumber = permitNumber
        self.tripPurpose = tripPurpose
    }
}


class TeklanikaCamperObservation: Observation {
    
    var hasTekPass: Bool?
    
    init?(id: Int, observerName: String, date: String, time: String, destination: String, nPassengers: String, hasTekPass: Bool, driverName: String = "N/A", comments: String = ""){
        
        super.init(id: id, observerName: observerName, date: date, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers, comments: comments)
        
        self.hasTekPass = hasTekPass
    }
}


// Not needed because this class doesn't have any other properties than Observation base class
// class CyclistObservation: Observation {

//}


class PhotographerObservation: Observation {
    
    var permitNumber: String?
    var nExpectedNights = "0"
    
    init?(id: Int, observerName: String, date: String, time: String, driverName: String, destination: String, nPassengers: String, permitNumber: String, nExpectedNights: String = "0", comments: String = ""){
        
        super.init(id: id, observerName: observerName, date: date, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers, comments: comments)
        
        self.permitNumber = permitNumber
        self.nExpectedNights = nExpectedNights
    }
}


/*class AccessibilityObservation: Observation {

    
    init?(id: Int, observerName: String, date: String, time: String, driverName: String, destination: String, nPassengers: String, comments: String = ""){
        
        super.init(id: id, observerName: observerName, date: date, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers, comments: comments)
    }
    
}*/

// Not needed because this class doesn't have any other properties than Observation base class
// class HunterObservation: Observation {

//}

class RoadLotteryObservation: Observation {

    var permitNumber: String?
    
    init?(id: Int, observerName: String, date: String, time: String, driverName: String, destination: String = "", nPassengers: String, permitNumber: String, comments: String = ""){
        
        super.init(id: id, observerName: observerName, date: date, time: time, driverName: driverName, destination: destination, nPassengers: nPassengers, comments: comments)
        
        self.permitNumber = permitNumber
    }
}

