//
//  Globals.swift
//  savageChecker
//
//  Created by Sam Hooper on 8/9/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import SQLite


var dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)/savageChecker.db"

// Vars to store dropdownOptions that are redefined when JSON is parsed
var destinations = [String]()
var observers = [String]()

