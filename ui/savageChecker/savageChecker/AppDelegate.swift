//
//  AppDelegate.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/10/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
//import SQLite3
import SQLite


let dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)/savageChecker.db"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        configureDatabase()
        
        return true
    }
    
    // Connect to DB and create all necessary tables
    func configureDatabase(){
        // Open a connection to the database
        let db : Connection
        do {
            db = try Connection(dbPath)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        print(dbPath)
        
        // Make tables
        
        // MARK: - Session table
        let idColumn = Expression<Int64>("id")
        let observerNameColumn = Expression<String>("observerName")
        let dateColumn = Expression<String>("date")
        let openTimeColumn = Expression<String>("openTime")
        let closeTimeColumn = Expression<String>("closeTime")
        
        let sessionsTable = Table("sessions")
        do {
            try db.run(sessionsTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(openTimeColumn)
                t.column(closeTimeColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Observations table
        let timeColumn = Expression<String>("time")
        let driverNameColumn = Expression<String>("driverName")
        let destinationColumn = Expression<String>("destination")
        let nPassengersColumn = Expression<String>("nPassengers")
        let commentsColumn = Expression<String>("comments")
        
        let observationsTable = Table("observations")
        do {
            try db.run(observationsTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Buses table
        let busTypeColumn = Expression<String>("busType")
        let busNumberColumn = Expression<String>("busNumber")
        let isTrainingColumn = Expression<Bool>("isTraining")
        let nOvernightPassengersColumn = Expression<String>("nOvernightPassengers")
        
        let busesTable = Table("buses")
        do {
            try db.run(busesTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
                t.column(busTypeColumn)
                t.column(busNumberColumn)
                t.column(isTrainingColumn)
                t.column(nOvernightPassengersColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - NPS vehicle table
        let tripPurposeColumn = Expression<String>("tripPurpose")
        let workDivisionColumn = Expression<String>("workDivision")
        let workGroupColumn = Expression<String>("workGroup")
        let nExpectedNightsColumn = Expression<String>("nExpectedDays")
        
        let NPSVehicleTable = Table("npsVehicles")
        do {
            try db.run(NPSVehicleTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
                t.column(tripPurposeColumn)
                t.column(workDivisionColumn)
                t.column(workGroupColumn)
                t.column(nExpectedNightsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - NPS approved table
        let vehicleTypeColumn = Expression<String>("vehicleType")
        
        let NPSApprovedTable = Table("npsApproved")
        do {
            try db.run(NPSApprovedTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
                t.column(tripPurposeColumn)
                t.column(vehicleTypeColumn)
                t.column(nExpectedNightsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - NPS conctractor table
        let NPSContractorTable = Table("npsContractors")
        do {
            try db.run(NPSContractorTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
                t.column(tripPurposeColumn)
                t.column(nExpectedNightsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - employee table
        let permitHolderColumn = Expression<String>("permitHolder")
        let EmployeeTable = Table("employees")
        do {
            try db.run(EmployeeTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(permitHolderColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Right of way table
        let rightOfWayTable = Table("rightOfWay")
        do {
            try db.run(rightOfWayTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(permitHolderColumn)
                t.column(tripPurposeColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Tek camper table
        let hasTekPassColumn = Expression<Bool>("hasTekPass")
        let teklanikaCamperTable = Table("tekCampers")
        do {
            try db.run(teklanikaCamperTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(hasTekPassColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Propho table
        let permitNumberColumn = Expression<String>("permitNumber")
        let photographerTable = Table("photographers")
        do {
            try db.run(photographerTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(permitNumberColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Accessibility table
        let accessibilityTable = Table("accessibility")
        do {
            try db.run(accessibilityTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(tripPurposeColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Cyclist table
        let cyclistTable = Table("cyclists")
        do {
            try db.run(cyclistTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Hunter table
        let hunterTable = Table("hunters")
        do {
            try db.run(hunterTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Road lottery table
        let roadLotteryTable = Table("roadLottery")
        do {
            try db.run(roadLotteryTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        let otherVehicleTable = Table("other")
        do {
            try db.run(otherVehicleTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
    
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        //print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        //print("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        //print("applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //print("applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        //print("applicationWillTerminate")
    }


}
