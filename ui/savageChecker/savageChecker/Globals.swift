//
//  Globals.swift
//  savageChecker
//
//  Created by Sam Hooper on 8/9/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import SQLite
import UIKit

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



