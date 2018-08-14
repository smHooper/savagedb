//
//  SessionViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/10/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import SQLite
import os.log

class SessionViewController: BaseFormViewController {
    
    //MARK: - Properties
    var viewVehiclesButton: UIBarButtonItem!
    var userData: UserData?
    
    //MARK: DB properties
    let sessionsTable = Table("sessions")
    let idColumn = Expression<Int64>("id")
    let observerNameColumn = Expression<String>("observerName")
    let dateColumn = Expression<String>("date")
    let openTimeColumn = Expression<String>("openTime")
    let closeTimeColumn = Expression<String>("closeTime")
    
    //MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date", type: "date"),
                             (label: "Open time",     placeholder: "Select the check station openning time", type: "time"),
                             (label: "Close time",    placeholder: "Select the check station closing time", type: "time")]
        self.dropDownMenuOptions = ["Observer name": observers]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date", type: "date"),
                             (label: "Open time",     placeholder: "Select the check station openning time", type: "time"),
                             (label: "Close time",    placeholder: "Select the check station closing time", type: "time")]
        self.dropDownMenuOptions = ["Observer name": observers]
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // First check if there's user data from a previous session
        if let userData = loadUserData() {
            dbPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(userData.activeDatabase).path
            self.userData = userData
            print(dbPath)
        }
        
        // Then check if the database at dbPath exists
        let url = URL(fileURLWithPath: dbPath)
        if FileManager.default.fileExists(atPath: url.path){
            // The user is opening the app again after closing it or returning from another scene
            do {self.db = try Connection(dbPath)}
            catch {print(error)}
            if let session = loadSession() {
                self.dropDownTextFields[0]?.text = session.observerName
                self.textFields[1]?.text = session.date
                self.textFields[2]?.text = session.openTime
                self.textFields[3]?.text = session.closeTime
                self.viewVehiclesButton.isEnabled = true // Returning to view so make sure it's enabled
            }
            // The user is returning to the session scene from another scene
            else if let session = self.session {
                self.dropDownTextFields[0]?.text = session.observerName
                self.textFields[1]?.text = session.date
                self.textFields[2]?.text = session.openTime
                self.textFields[3]?.text = session.closeTime
                self.viewVehiclesButton.isEnabled = true // Returning to view so make sure it's enabled
            }
        }
        // The user has opened the app for the first time since data were cleared
        else {
            // date defaults to today
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            self.textFields[1]?.text = formatter.string(from: now)
            self.textFields[2]?.text = "6:30 AM"
            self.textFields[3]?.text = "9:30 PM"
            
            // Disable navigation to vehicle list until all fields are filled
            self.viewVehiclesButton.isEnabled = false
            
            // Create the userData instance for storing info
            self.userData = UserData(creationTime: Date(), lastModifiedTime: Date(), activeDatabase: URL(fileURLWithPath: dbPath).lastPathComponent)
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    //MARK: - Navigation
    // Set up the nav bar
    override func setNavigationBar() {
        super.setNavigationBar()
        
        // Customize the nav bar
        let navItem = UINavigationItem(title: "Shift Info")
        self.viewVehiclesButton = UIBarButtonItem(title: "View vehicles", style: .plain, target: nil, action: #selector(SessionViewController.moveToVehicleList))
        navItem.rightBarButtonItem = self.viewVehiclesButton
        self.navigationBar.setItems([navItem], animated: false)
    }
    
    @objc func moveToVehicleList(){
        
        let vehicleTableViewContoller = BaseTableViewController()
        vehicleTableViewContoller.modalPresentationStyle = .custom
        vehicleTableViewContoller.transitioningDelegate = self
        self.presentTransition = RightToLeftTransition()
        present(vehicleTableViewContoller, animated: true, completion: {[weak self] in self?.presentTransition = nil})
    }
    
    
    //MARK: Data model methods
    @objc override func updateData(){
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let openTime = self.textFields[2]?.text ?? ""
        let closeTime = self.textFields[3]?.text ?? ""
        if !observerName.isEmpty && !openTime.isEmpty && !closeTime.isEmpty && !date.isEmpty {
            // Update the DB
            if let session = loadSession() {
                // The session already exists in the DB, so update it
                do {
                    // Select the record to update
                    let record = sessionsTable.filter(idColumn == session.id.datatypeValue)
                    // Update all fields
                    if try db.run(record.update(observerNameColumn <- observerName,
                                                dateColumn <- date,
                                                openTimeColumn <- openTime,
                                                closeTimeColumn <- closeTime)) > 0 {
                    } else {
                        print("record not found")
                    }
                } catch {
                    print("Session update failed")
                }
                // Get the actual id of the insert row and assign it to the observation that was just inserted. Now when the cell in the obsTableView is selected (e.g., for delete()), the right ID will be returned. This is exclusively so that when if an observation is deleted right after it's created, the right ID is given to retreive a record to delete from the DB.
                var max: Int64!
                do {
                    max = try db.scalar(sessionsTable.select(idColumn.max))
                } catch {
                    print(error.localizedDescription)
                }
                let thisId = Int(max)
                self.session = Session(id: thisId, observerName: observerName, openTime: openTime, closeTime: closeTime, givenDate: date)
                
                // Update the UserData instance
                self.userData?.update(databaseFileName: URL(fileURLWithPath: dbPath).lastPathComponent)
            }
            
            // Create the DB
            else {
                // Set the dbPath with a unique tag that includes the observer's name and a timestamp
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formatter.dateStyle = .none
                let now = Date()
                let currentTimeString = formatter.string(from: now).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "-")
                let dateString = "\(date.replacingOccurrences(of: "/", with: "-"))"
                let fileNameTag = "\(observerName.replacingOccurrences(of: " ", with: "_"))_\(dateString)_\(currentTimeString)"
                
                if let documentsDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).absoluteString {
                    dbPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("savageChecker_\(fileNameTag).db").absoluteString
                }
                
                // Set up the database
                configureDatabase()
                
                // This is a new session so create a new recod in the DB
                do {
                    let rowid = try db.run(sessionsTable.insert(observerNameColumn <- observerName,
                                                                dateColumn <- date,
                                                                openTimeColumn <- openTime,
                                                                closeTimeColumn <- closeTime))
                    self.session?.id = Int(rowid)
                } catch {
                    print("Session insertion failed: \(error)")
                }
                
                // Save the UserData instance
                self.userData?.update(databaseFileName: URL(fileURLWithPath: dbPath).lastPathComponent)
            }
            
            //print("Session updated")
            
            // Enable the nav button
            self.viewVehiclesButton.isEnabled = true
            
        }
            // Disable the view vehicles button until all fields are filled in
        else {
            self.viewVehiclesButton.isEnabled = false
        }
    }
    
    
    //MARK: - TextFieldDelegate methods
    
    /*@objc override  func dropDownDidChange(notification: NSNotification) {
        
        let currentText = self.dropDownTextFields[self.currentTextField]?.text ?? ""
        
        super.dropDownDidChange(notification: notification)
        
        // This doesn't work
        if self.textFieldIds[self.currentTextField].label == "Observer name" {//&& observerName == currentText{
            sendDateEntryAlert = true // Originally set at the top of ObservationViewControllers.swift
        }
    }*/
    
    
    //MARK: Private methods
    private func loadSession() -> Session? {
        // ************* check that the table exists first **********************
        var rows = [Row]()
        do {
            guard let db = self.db else {
                return nil
            }
            rows = Array(try db.prepare(sessionsTable))
        } catch {
            //fatalError(error.localizedDescription)
            return nil
        }

        if rows.count > 1 {
            fatalError("Multiple sessions found")
        }
        var session: Session?
        for row in rows{
            session = Session(id: Int(row[idColumn]), observerName: row[observerNameColumn], openTime:row[openTimeColumn], closeTime: row[closeTimeColumn], givenDate: row[dateColumn])
        }
        guard let thisSession = session else {
            return nil
        }
        
        return thisSession
    }

    // Connect to DB and create all necessary tables
    func configureDatabase(){
        // Open a connection to the database
        //var db : Connection?
        do {
            self.db = try Connection(dbPath)
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
            try db?.run(sessionsTable.create(ifNotExists: true) { t in
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
            try db?.run(observationsTable.create(ifNotExists: true) { t in
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
            try db?.run(busesTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn, defaultValue: " ")
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
            try db?.run(NPSVehicleTable.create(ifNotExists: true) { t in
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
        let approvedTypeColumn = Expression<String>("approvedType")
        
        let NPSApprovedTable = Table("npsApproved")
        do {
            try db?.run(NPSApprovedTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
                t.column(tripPurposeColumn)
                t.column(approvedTypeColumn)
                t.column(nExpectedNightsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - NPS conctractor table
        let organizationNameColumn = Expression<String>("organizationName")
        let NPSContractorTable = Table("npsContractors")
        do {
            try db?.run(NPSContractorTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn, defaultValue: " ")
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
                t.column(tripPurposeColumn)
                t.column(nExpectedNightsColumn)
                t.column(organizationNameColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - employee table
        let permitHolderColumn = Expression<String>("permitHolder")
        let EmployeeTable = Table("employees")
        do {
            try db?.run(EmployeeTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn, defaultValue: " ")
                t.column(nPassengersColumn)
                t.column(commentsColumn)
                t.column(permitHolderColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Right of way table
        let permitNumberColumn = Expression<String>("permitNumber")
        let rightOfWayTable = Table("rightOfWay")
        do {
            try db?.run(rightOfWayTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn, defaultValue: " ")
                t.column(nPassengersColumn)
                t.column(commentsColumn)
                t.column(permitNumberColumn)
                t.column(tripPurposeColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Tek camper table
        let hasTekPassColumn = Expression<Bool>("hasTekPass")
        let teklanikaCamperTable = Table("tekCampers")
        do {
            try db?.run(teklanikaCamperTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn, defaultValue: " ")
                t.column(destinationColumn, defaultValue: " ")
                t.column(nPassengersColumn)
                t.column(commentsColumn)
                t.column(hasTekPassColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Propho table
        let photographerTable = Table("photographers")
        do {
            try db?.run(photographerTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn)
                t.column(destinationColumn, defaultValue: " ")
                t.column(nPassengersColumn)
                t.column(commentsColumn)
                t.column(permitNumberColumn)
                t.column(nExpectedNightsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Accessibility table
        let accessibilityTable = Table("accessibility")
        do {
            try db?.run(accessibilityTable.create(ifNotExists: true) { t in
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
        
        // MARK: - Cyclist table
        let cyclistTable = Table("cyclists")
        do {
            try db?.run(cyclistTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn, defaultValue: " ")
                t.column(destinationColumn)
                t.column(nPassengersColumn)
                t.column(commentsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Hunter table
        let hunterTable = Table("subsistenceUsers")
        do {
            try db?.run(hunterTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn, defaultValue: " ")
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
            try db?.run(roadLotteryTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(timeColumn)
                t.column(driverNameColumn, defaultValue: " ")
                t.column(destinationColumn, defaultValue: " ")
                t.column(nPassengersColumn)
                t.column(permitNumberColumn)
                t.column(commentsColumn)
            })
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // MARK: - Other table
        let otherVehicleTable = Table("other")
        do {
            try db?.run(otherVehicleTable.create(ifNotExists: true) { t in
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
}
