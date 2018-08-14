//
//  Constants.swift
//  savageChecker
//
//  Created by Sam Hooper on 6/25/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import Foundation

//let dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)/savageChecker.db"

let observationIcons: DictionaryLiteral = ["Bus": "busIcon",
                                           "NPS Vehicle": "npsVehicleIcon",
                                           "NPS Approved": "npsApprovedIcon",
                                           "NPS Contractor": "npsContractorIcon",
                                           "Employee": "employeeIcon",
                                           "Right of Way": "rightOfWayIcon",
                                           "Tek Camper": "tekCamperIcon",
                                           "Bicycle": "cyclistIcon",
                                           "Propho": "busIcon",
                                           "Accessibility": "busIcon",
                                           "Hunting": "busIcon",
                                           "Road lottery": "busIcon",
                                           "Other": "busIcon"]

let userDataPath = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("userData").path

let backgroundImages = [""]
