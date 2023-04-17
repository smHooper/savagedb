//
//  Constants.swift
//  savageChecker
//
//  Created by Sam Hooper on 6/25/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import Foundation
import UIKit

//let dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)/savageChecker.db"

let observationIcons: DictionaryLiteral = ["Bus": "busIcon",
                                           "Lodge Bus": "lodgeBusIcon",
                                           "NPS Vehicle": "npsVehicleIcon",
                                           "NPS Approved": "npsApprovedIcon",
                                           "NPS Contractor": "npsContractorIcon",
                                           "Employee": "employeeIcon",
                                           "Right of Way": "rightOfWayIcon",
                                           "Tek Camper": "tekCamperIcon",
                                           "Bicycle": "cyclistIcon",
                                           "Photographer": "busIcon",
                                           "Accessibility": "busIcon",
                                           "Hunting": "busIcon",
                                           "Road lottery": "busIcon",
                                           "Other": "busIcon"]

let userDataPath = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("__admin__").appendingPathComponent("userData").path

let dateStringFormat = "M-d-yyyy"

let launchScreenQuotes = [
    "Industrial tourism is a threat to the national parks. But the chief victims of the system are the motorized tourists. They are being robbed and robbing themselves. So long as they are unwilling to crawl out of their cars they will not discover the treasures of the national parks and will never escape the stress and turmoil of the urban-suburban complexes which they had hoped, presumably, to leave behind for a while.\n\n\t- Edward Abbey",
    "Wilderness is not a luxury but a necessity of the human spirit, and as vital to our lives as water and good bread. A civilization which destroys what little remains of the wild, the spare, the original, is cutting itself off from its origins and betraying the principle of civilization itself.\n\n\t- Edward Abbey",
    "A world without open country would be universal jail.\n\n\t- Edward Abbey",
    "There are some good things to be said about walking. Not many, but some. Walking takes longer, for example, than any other known form of locomotion except crawling. Thus it stretches time and prolongs life. Life is already too short to waste on speed. I have a friend who’s always in a hurry; he never gets anywhere. Walking makes the world much bigger and thus more interesting. You have time to observe the details.\n\n\t- Edward Abbey",
    "This is the most beautiful place on Earth. There are many such places. Every man, every woman, carries in heart and mind the image of the ideal place, the right place, the one true home, known or unknown, actual or visionary.\n\n\t- Edward Abbey",
    "Only by going alone in silence, without baggage, can one truly get into the heart of the wilderness. All other travel is mere dust and hotels and baggage and chatter.\n\n\t- John Muir",
    "The snow is melting into music.\n\n\t- John Muir",
    "Thousands of tired, nerve-shaken, over-civilized people are beginning to find out that going to the mountains is going home; that wildness is a necessity; and that mountain parks and reservations are useful not only as fountains of timber and irrigating rivers, but as fountains of life.\n\n\t- John Muir",
    "This one noble park is big enough and rich enough for a whole life of study and aesthetic enjoyment. It is good for everybody, no matter how benumbed with care, encrusted with a mail of business habits like a tree with bark. None can escape its charms. Its natural beauty cleans and warms like a fire, and you will be willing to stay forever in one place like a tree.\n\n\t- John Muir (on Yosemite)",
    "Highest ranking among the intangible values of the park is its distinct wilderness feel. To gaze across a vast expanse of tundra towards nameless rugged mountains, or upon the fastness of ever-imposing Denali, and to have one's meditations interrupted by a migrating band of caribou is an experience which cannot be duplicated elsewhere.\n\n\t- NPS Mission 66 Prospectus, 1956\n",
    "The national park will not serve its purpose if we encourage the visitor to hurry as fast as possible for a mere glimpse of scenery from a car, and a few snapshots. Rather there is an obligation inherent in a national park, to help the visitor get some understanding, the esthetic meaning of what is in the place.\n\n\t- Olaus Murie",
    "...when one becomes responsible for what is to happen to such a landscape his prime duty is to protect and perpetuate whatever of beauty and inspirational value, inherent in that landscape, is due to nature and to circumstances not of one’s contriving, and to humbly subordinate to that purpose any impulse to exercise upon it one’s own skill as a creative designer.\n\n\t- Frederick Law Olmsted",
    "...let the tourist be on his own, and not be spoon-fed at intervals. Let him be encouraged to keep his eyes open, do his own looking and exploring, and catch what he can of the magic of wilderness.\n\n\t- Adolph Murie"
]

let backgroundImages = [""]

let navigationButtonSize: CGFloat = 35
let navigationBarSize: CGFloat = 54
var statusBarHeight: CGFloat = 20

let observationViewControllers = ["Bus": BusObservationViewController.self,
                                  "Lodge Bus": LodgeBusObservationViewController.self,
                                  "NPS Vehicle": NPSVehicleObservationViewController.self,
                                  "NPS Approved": NPSApprovedObservationViewController.self,
                                  "NPS Contractor": NPSContractorObservationViewController.self,
                                  "Employee": EmployeeObservationViewController.self,
                                  "Right of Way": RightOfWayObservationViewController.self,
                                  "Tek Camper": TeklanikaCamperObservationViewController.self,
                                  "Bicycle": CyclistObservationViewController.self,
                                  "Photographer": PhotographerObservationViewController.self,
                                  "Accessibility": AccessibilityObservationViewController.self,
                                  "Subsistence": SubsistenceObservationViewController.self,
                                  "Road Lottery": RoadLotteryObservationViewController.self,
                                  "Other": OtherObservationViewController.self]
let navBarColors = ["Bus": UIColor(red: 145/255, green: 90/255, blue: 119/255, alpha: 1),
                    "Lodge Bus": UIColor(red: 145/255, green: 90/255, blue: 119/255, alpha: 1),
                    "NPS Vehicle": UIColor(red: 145/255, green: 90/255, blue: 119/255, alpha: 1),
                    "NPS Approved": UIColor(red: 83/255, green: 123/255, blue: 158/255, alpha: 1),
                    "NPS Contractor": UIColor(red: 158/255, green: 158/255, blue: 158/255, alpha: 1),
                    "Employee": UIColor(red: 194/255, green: 89/255, blue: 99/255, alpha: 1),
                    "Right of Way": UIColor(red: 145/255, green: 90/255, blue: 119/255, alpha: 1),
                    "Tek Camper": UIColor(red: 145/255, green: 90/255, blue: 119/255, alpha: 1),
                    "Bicycle": UIColor(red: 145/255, green: 90/255, blue: 119/255, alpha: 1),
                    "Photographer": UIColor(red: 212/255, green: 138/255, blue: 68/255, alpha: 1),
                    "Accessibility": UIColor(red: 128/255, green: 110/255, blue: 171/255, alpha: 1),
                    "Subsistence": UIColor(red: 214/255, green: 204/255, blue: 45/255, alpha: 1),
                    "Road Lottery": UIColor(red: 145/255, green: 90/255, blue: 119/255, alpha: 1),
                    "Other": UIColor(red: 145/255, green: 90/255, blue: 119/255, alpha: 1)]

let tableNames = ["BusObservationViewController": "buses",
                  "LodgeBusObservationViewController": "buses",
                  "NPSVehicleObservationViewController": "nps_vehicles",
                  "NPSApprovedObservationViewController": "nps_approved",
                  "NPSContractorObservationViewController": "nps_contractors",
                  "EmployeeObservationViewController": "employee_vehicles",
                  "RightOfWayObservationViewController": "inholders",
                  "TeklanikaCamperObservationViewController": "tek_campers",
                  "CyclistObservationViewController": "cyclists",
                  "PhotographerObservationViewController": "photographers",
                  "AccessibilityObservationViewController": "accessibility",
                  "SubsistenceObservationViewController": "subsistence",
                  "RoadLotteryObservationViewController": "road_lottery",
                  "OtherObservationViewController": "other_vehicles"]
let autoCompleteDBURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("autoCompleteOptions.db")
