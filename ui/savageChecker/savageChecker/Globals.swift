//
//  Globals.swift
//  savageChecker
//
//  Created by Sam Hooper on 8/9/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import SQLite
import UIKit
import os.log

var dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)/savageChecker.db"

// Vars to store dropdownOptions that are redefined when JSON is parsed
var destinations = [String]()
var observers = [String]()
var dropDownJSON = JSON()
var busTypes = [String]()
var lodges = [String]()
var npsVehicleWorkDivisions = [String]()
var npsVehicleWorkGroups = [String: [String]]() // Dictionary of string arrays
var npsApprovedCategories = [String]()
var npsContractorTripPurposes = [String]()

var showQuoteAtStartup = true
var showHelpTips = false
// var sendDateEntryAlert = true //instantiated in ObservationViewControllers.swift


func getConfigURL() -> URL?{
    var jsonURL = URL(fileURLWithPath: "")
    // Look for config file in Documents folder.
    let fileManager = FileManager.default
    if let documentsDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).absoluteString {
        let url = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("savageCheckerConfig.json")
        
        if fileManager.fileExists(atPath: url.path) {
            jsonURL = url
        }
            // If it's not there, use the default config file in Resources
        else if let url = Bundle.main.url(forResource: "savageCheckerConfig", withExtension: "json") {
            jsonURL = url
        } else {
            os_log("Could not configure get JSON file url", log: OSLog.default, type: .debug)
        }
    }
    
    return jsonURL
}
