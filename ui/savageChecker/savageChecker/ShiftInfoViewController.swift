//
//  ShiftInfoViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 2/12/19.
//  Copyright © 2019 Sam Hooper. All rights reserved.
//


import UIKit
import SQLite
import os.log
import QuartzCore

class ShiftInfoViewController: BaseFormViewController {
    
    //MARK: - Properties
    var saveButton = UIButton(type: .system)
    var userData: UserData?
    var isNewSession: Bool? = false
    var dataHasChanged = false
    
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
        
        self.topSpacing = 20.0
        
        super.viewDidLoad()
        
        // Show animated quote the first time the view loads, but allow user to swipe to cancel
        //showQuote(seconds: 5.0)
        
        for subview in self.view.subviews {
            if subview.tag == -1 {
                subview.removeFromSuperview()
            }
        }
        self.scrollView.delegate = self
        
        // Add a title at the top
        let titleLabel = UILabel()
        titleLabel.text = "Shift Info"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        self.view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.sideSpacing * 3).isActive = true
        
        // Add the upload button
        let controllerFrame = getVisibleFrame()
        self.saveButton.setTitle("Save", for: .normal)
        self.saveButton.titleLabel!.font = UIFont.systemFont(ofSize: 22)
        self.saveButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        self.view.addSubview(self.saveButton)
        self.saveButton.translatesAutoresizingMaskIntoConstraints = false
        self.saveButton.bottomAnchor.constraint(equalTo: self.view.topAnchor, constant: self.preferredContentSize.height - self.sideSpacing * 2).isActive = true
        self.saveButton.isEnabled = false
        

        
        // Draw lines to separate buttons from text
        //  Horizontal line
        let lineColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.4)
        let horizontalLine = UIView(frame: CGRect(x:0, y: 0, width: controllerFrame.width, height: 1))
        self.view.addSubview(horizontalLine)
        horizontalLine.backgroundColor = lineColor
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        horizontalLine.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        horizontalLine.topAnchor.constraint(equalTo: saveButton.topAnchor, constant: -self.sideSpacing).isActive = true
        horizontalLine.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        horizontalLine.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        
        loadData()
        
        // Use a different layout depending on whether this is a new shift
        if let isNew = self.isNewSession, isNew == true {
            // Set the save button in the middle
            self.saveButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            
        } else {
            // Set the save button on the right side
            self.saveButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: controllerFrame.width/4).isActive = true
            
            //  Vertical line
            let verticalLine = UIView(frame: CGRect(x:0, y: 0, width: 1, height: 1))
            self.view.addSubview(verticalLine)
            verticalLine.backgroundColor = lineColor
            verticalLine.translatesAutoresizingMaskIntoConstraints = false
            verticalLine.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            verticalLine.topAnchor.constraint(equalTo: saveButton.topAnchor, constant: -self.sideSpacing).isActive = true
            verticalLine.widthAnchor.constraint(equalToConstant: 1.0).isActive = true
            verticalLine.bottomAnchor.constraint(equalTo: saveButton.bottomAnchor).isActive = true
            
            // Add a cancel button at the bottom on the left side
            let cancelButton = UIButton(type: .system)
            cancelButton.setTitle("Cancel", for: .normal)
            cancelButton.titleLabel!.font = UIFont.systemFont(ofSize: 22)
            cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
            self.view.addSubview(cancelButton)
            cancelButton.translatesAutoresizingMaskIntoConstraints = false
            cancelButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -controllerFrame.width/4).isActive = true
            cancelButton.centerYAnchor.constraint(equalTo: self.saveButton.centerYAnchor).isActive = true
        }
        
    }
    
    func loadData() {
        // First check if there's user data from a previous session
        if let userData = loadUserData() {
            dbPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(userData.activeDatabase).path
            self.userData = userData
        }
        print(dbPath)
        
        // Then check if the database at dbPath exists
        let url = URL(fileURLWithPath: dbPath)
        if FileManager.default.fileExists(atPath: url.path){
            // The user is opening the app again after closing it or returning from another scene
            do {self.db = try Connection(dbPath)}
            catch {
                os_log("Connecting to DB in SessionViewController.loadData() failed", log: OSLog.default, type: .debug)
                print(error)}
            if let session = loadSession() {
                self.dropDownTextFields[0]?.text = session.observerName
                self.textFields[1]?.text = session.date
                self.textFields[2]?.text = session.openTime
                self.textFields[3]?.text = session.closeTime
                //self.saveButton.isEnabled = true // Returning to view so make sure it's enabled
                self.session = session
            }
                // The user is returning to the session scene from another scene
            else if let session = self.session {
                self.dropDownTextFields[0]?.text = session.observerName
                self.textFields[1]?.text = session.date
                self.textFields[2]?.text = session.openTime
                self.textFields[3]?.text = session.closeTime
                //self.saveButton.isEnabled = true // Returning to view so make sure it's enabled
            }
            // The db doesn't have a sessions table because it hasn't been configured yet
            else {
                createSession()
            }
        }
        // The user is coming back to the session form for the first time since data were cleared
        else {
            createSession()
        }
    }
    
    
    func createSession(){
        // date defaults to today
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        self.textFields[1]?.text = formatter.string(from: now)
        self.textFields[2]?.text = "6:30 AM"
        self.textFields[3]?.text = "9:30 PM"
        
        // Disable navigation to vehicle list until all fields are filled
        self.saveButton.isEnabled = false
        
        // Create the userData instance for storing info
        self.userData = UserData(creationTime: Date(), lastModifiedTime: Date(), activeDatabase: URL(fileURLWithPath: dbPath).lastPathComponent)
        
        self.isNewSession = true
    }
    
    // Cancel animation (to be used with swipe gesture)
    @objc func cancelAnimation() {
        print("swipeLeft")
        self.view.layer.removeAllAnimations()
    }
    
    
    //MARK: - Navigation
    // Set up the nav bar
    override func setNavigationBar() {
        super.setNavigationBar()
        
        // Customize the nav bar
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isOpaque = false
    }
    
    @objc func cancelButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Data model methods
    
    func validateInput() -> Bool {
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let openTime = self.textFields[2]?.text ?? ""
        let closeTime = self.textFields[3]?.text ?? ""
        if !observerName.isEmpty && !openTime.isEmpty && !closeTime.isEmpty && !date.isEmpty {
            self.saveButton.isEnabled = true
            return true
        } else {
            self.saveButton.isEnabled = false
            return false
        }
        
    }
    
    @objc override func updateData() {
        if validateInput() {
            self.saveButton.isEnabled = true
        }
        // All fields aren't full, so disable the save button
        else {
            self.saveButton.isEnabled = false
        }
    }
    
    @objc func saveButtonPressed(){
        
        // Check that all text fields are filled in
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let openTime = self.textFields[2]?.text ?? ""
        let closeTime = self.textFields[3]?.text ?? ""
        if !observerName.isEmpty && !openTime.isEmpty && !closeTime.isEmpty && !date.isEmpty {
            // Try to update the DB
            if let session = self.session {
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
                        os_log("record not found", log: OSLog.default, type: .debug)
                    }
                } catch {
                    os_log("Session update failed", log: OSLog.default, type: .debug)
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
                //self.userData?.update(databaseFileName: URL(fileURLWithPath: dbPath).lastPathComponent)
            }
                
            // If the session is nil, this is a new session so create the DB
            else {
                // initialize the session instance
                self.session = Session(id: -1, observerName: observerName, openTime: openTime, closeTime: closeTime, givenDate: date)
                
                // Set the dbPath with a unique tag that includes the observer's name and a timestamp
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formatter.dateStyle = .none
                let now = Date()
                let currentTimeString = formatter.string(from: now).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "-")
                let dateString = "\(date.replacingOccurrences(of: "/", with: "-"))"
                let observerNameString = observerName.replacingOccurrences(of: " ", with: "_")
                let fileNameTag = "\(observerNameString)_\(dateString)_\(currentTimeString)"
                
                guard let documentsDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
                    os_log("Could not find documents directory", log: OSLog.default, type: .debug)
                    return
                }
                
                // If observer name was the field just modified, check to see if there's an existing DB from today with this user's name.
                //  If so, ask user if they wan't to edit the existing DB or create a new one
                var existingDBFile: String? = nil
                if self.currentTextField == 0 {
                    let databaseFiles = findFiles()
                    for dbFile in databaseFiles.sorted() {
                        if dbFile.contains(observerNameString) && dbFile.contains(dateString) {
                            existingDBFile = dbFile
                            break
                        }
                    }
                }
                // If existingDBFile isn't nil, then it was set because there's an existing DB with the observer's name
                if let existingDBFile = existingDBFile {
                    let alertTitle = "Existing database found"
                    let alertMessage = "A database named \(existingDBFile) already exists for this observer from today. Do you want to create a new database file or add/modify observations in the existing one?"
                    let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Create new file", style: .default, handler: {handler in
                        dbPath = documentsDirectory.appendingPathComponent("savageChecker_\(fileNameTag).db").path // Use new path
                        self.connectToDB()
                    }))
                    alertController.addAction(UIAlertAction(title: "Use existing file", style: .default, handler: {handler in
                        dbPath = documentsDirectory.appendingPathComponent(existingDBFile).path // Use existing path
                        self.isNewSession = false
                        print("dbPath after Use existing file selected: \(dbPath)")
                        self.connectToDB()
                    }))
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                    // Otherwise, just create a new DB with the new path
                else {
                    dbPath = documentsDirectory.appendingPathComponent("savageChecker_\(fileNameTag).db").path // Use new path
                    connectToDB()
                }
            }
            
            // Enable the nav button
            //self.saveButton.isEnabled = true
            
            // Save the UserData instance
            self.userData?.update(databaseFileName: URL(fileURLWithPath: dbPath).lastPathComponent)
        }
        
        dismiss(animated: true, completion: nil)
            // All fields aren't full, so disable the view vehicles button until all fields are filled in
        /*else {
            self.saveButton.isEnabled = false
        }*/
    }
    
    
    //MARK: Scrollview delegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
    }
    
    //MARK: Private methods
    private func connectToDB() {
        
        // Text fields should all be filled at this point, but unwrap safely just in case
        let observerName = self.dropDownTextFields[0]?.text ?? ""
        let date = self.textFields[1]?.text ?? ""
        let openTime = self.textFields[2]?.text ?? ""
        let closeTime = self.textFields[3]?.text ?? ""
        
        // Set up the database
        configureDatabase()
        
        if self.isNewSession ?? false {
            // This is a new session so create a new recod in the DB
            do {
                let rowid = try db.run(sessionsTable.insert(observerNameColumn <- observerName,
                                                            dateColumn <- date,
                                                            openTimeColumn <- openTime,
                                                            closeTimeColumn <- closeTime))
                self.session?.id = Int(rowid)
            } catch {
                print("Session insertion failed: \(error)")
                os_log("Session insertion failed", log: OSLog.default, type: .debug)
            }
        }
        
    }
    
    
    private func findFiles() -> [String]{
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var files = [String]()
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for url in fileURLs {
                let fileName = url.lastPathComponent
                if fileName != "savageChecker.db" && fileName.hasSuffix(".db"){
                    files.append(fileName)
                }
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
            os_log("Error while enumerating files", log: OSLog.default, type: .debug)
        }
        
        return files
    }
    
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
        
        /*if rows.count > 1 {
         fatalError("Multiple sessions found")
         }*/
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
        } catch {
            os_log("Couldn't cofigure the DB", log: OSLog.default, type: .debug)
            //fatalError(error.localizedDescription)
        }
        print(dbPath)
        
        // Make tables
        
        // MARK: - Session table
        let idColumn = Expression<Int64>("id")
        let observerNameColumn = Expression<String>("observerName")
        let dateColumn = Expression<String>("date")
        let openTimeColumn = Expression<String>("openTime")
        let closeTimeColumn = Expression<String>("closeTime")
        let uploadedColumn = Expression<Bool>("uploaded")
        
        let sessionsTable = Table("sessions")
        do {
            try db?.run(sessionsTable.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(observerNameColumn)
                t.column(dateColumn)
                t.column(openTimeColumn)
                t.column(closeTimeColumn)
                t.column(uploadedColumn, defaultValue: false)
            })
        } catch {
            os_log("Couldn't cofigure the the Session table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the Session table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the buses table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the npsVehicles table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the nps approved table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the nps contractors table", log: OSLog.default, type: .debug)
        }
        
        // MARK: - employee table
        let permitHolderColumn = Expression<String>("permitHolder")
        // add permit_number
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
        } catch {
            os_log("Couldn't cofigure the the employee table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the rightofway table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the tekCampers table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the photographers table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the accessibilty table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the cyclists table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the subsistenceUsers table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the roadLottery table", log: OSLog.default, type: .debug)
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
        } catch {
            os_log("Couldn't cofigure the the other table", log: OSLog.default, type: .debug)
        }
        
    }
}