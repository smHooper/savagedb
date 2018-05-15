//
//  Observation.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import Foundation


class Observation {
    
    //MARK: Properties
    var time: String
    var date: String
    var observerName: String
    var driverName: String
    var destination: String
    
    init?(session: Session, time: String, driverName: String, destination: String){
        // All observations must belong to a session, and observer name and date are pulled directly from that session
        if session.observerName.isEmpty {
            return nil
        }
        if session.date.isEmpty {
            return nil
        }
        
        //Initialized stored properties
        //self.session = session
        self.time = time // make this optional and set to now if empty
        self.driverName = driverName
        self.destination = destination
        self.date = session.date
        self.observerName = session.observerName

        
    }
}
