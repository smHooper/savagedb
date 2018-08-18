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

let observationViewControllers = ["Bus": BusObservationViewController(),
                                  "Lodge Bus": LodgeBusObservationViewController(),
                                  "NPS Vehicle": NPSVehicleObservationViewController(),
                                  "NPS Approved": NPSApprovedObservationViewController(),
                                  "NPS Contractor": NPSContractorObservationViewController(),
                                  "Employee": EmployeeObservationViewController(),
                                  "Right of Way": RightOfWayObservationViewController(),
                                  "Tek Camper": TeklanikaCamperObservationViewController(),
                                  "Bicycle": CyclistObservationViewController(),
                                  "Propho": PhotographerObservationViewController(),
                                  "Accessibility": AccessibilityObservationViewController(),
                                  "Subsistence": SubsistenceObservationViewController(),
                                  "Road Lottery": RoadLotteryObservationViewController(),
                                  "Other": OtherObservationViewController()]

var statusBarHeight: CGFloat = 20


