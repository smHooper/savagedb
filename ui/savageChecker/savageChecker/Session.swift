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
    var observer: String
    //var date: String // Store as string because Swift almost certainly uses different epoch than Python
    // Make open/close times optional because in a given session, someone probably either opens, closes, or neither
    var openTime: String
    //var closeTime: String
    
    init?(observer: String, openTime: String){//date: String, openTime: String){//}, closeTime: String?){
        // Check that all attributes are non-mepty
        guard !observer.isEmpty else {
            return nil
        }
        /*guard !date.isEmpty else {
            return nil
        }*/
        guard !openTime.isEmpty else {
            return nil
        }
        /*guard !closeTime.isEmpty else {
            return nil
        }*/
        
        self.observer = observer
        //self.date = date
        self.openTime = openTime
        //self.closeTime = closeTime
    }
    
    
}
