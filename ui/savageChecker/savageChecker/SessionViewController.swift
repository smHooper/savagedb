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
    var isNewSession: Bool?
    
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
        showQuote(seconds: 5.0)
        loadData()
        
    }
    
    func showQuote(seconds: Double) {
        
        let borderSpacing: CGFloat = 16
        let randomIndex = Int(arc4random_uniform(UInt32(launchScreenQuotes.count)))
        let randomQuote = launchScreenQuotes[randomIndex]
        
        let screenBounds = UIScreen.main.bounds
        
        // Configure the message
        let messageViewWidth = min(screenBounds.width, 450)
        let font = UIFont.systemFont(ofSize: 18)
        let messageHeight = randomQuote.height(withConstrainedWidth: messageViewWidth - borderSpacing * 2, font: font)
        let messageFrame = CGRect(x: screenBounds.width/2 - messageViewWidth/2, y: screenBounds.height/2 - (messageHeight/2 + borderSpacing), width: messageViewWidth, height: messageHeight + borderSpacing * 2)
        let messageView = UITextView(frame: messageFrame)
        messageView.font = font
        messageView.layer.cornerRadius = 25
        messageView.layer.borderColor = UIColor.clear.cgColor
        messageView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        messageView.textContainerInset = UIEdgeInsets(top: borderSpacing, left: borderSpacing, bottom: borderSpacing, right: borderSpacing)
        messageView.text = randomQuote
        let blurEffect = UIBlurEffect(style: .light)
        let messageViewBackground = UIVisualEffectView(effect: blurEffect)
        messageViewBackground.frame = messageFrame
        messageViewBackground.layer.cornerRadius = messageView.layer.cornerRadius
        messageViewBackground.layer.masksToBounds = true
        messageView.addSubview(messageViewBackground)
        //messageView.sendSubview(toBack: messageViewBackground)
        
        // Add the message view with the background
        let screenView = UIImageView(frame: screenBounds)
        screenView.image = UIImage(named: "viewControllerBackground")
        screenView.contentMode = .scaleAspectFill
        screenView.addSubview(messageViewBackground)
        screenView.addSubview(messageView)
        self.view.addSubview(screenView)
        
        // Set up the false background that's identical to the viewController's background so it looks like all of the view controller elements fade into view
        let blurredBackground = UIImageView(frame: screenView.frame)//image:
        blurredBackground.image = UIImage(named: "viewControllerBackgroundBlurred")
        blurredBackground.alpha = 0.0
        let translucentWhite = UIView(frame: screenView.frame)
        translucentWhite.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        blurredBackground.addSubview(translucentWhite)
        self.view.addSubview(blurredBackground)
        
        let quoteTimeSeconds = min(7, max(Double(randomQuote.count)/200 * 5, 3))
        
        // First, animate the messageView disappearing
        UIView.animate(withDuration: 0.75, delay: quoteTimeSeconds, animations: { messageView.alpha = 0.0; messageViewBackground.alpha = 0.0}, completion: {_ in
            messageView.removeFromSuperview()
            // Next, animate the blurred background appearing
            UIView.animate(withDuration: 0.75, delay: 0.2, animations: {blurredBackground.alpha = 1.0}, completion: {_ in
                screenView.removeFromSuperview()
                // Finally, make the blurred background disappear. Because it's just a crossfade, it looks like the screen elements are the ones fading into view.
                UIView.animate(withDuration: 0.5, animations: {blurredBackground.alpha = 0.0}, completion: {_ in
                    blurredBackground.removeFromSuperview()
                })
            })
        })
        
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
                os_log("Connecting to DB in SessionViewController.loadData() failed", log: OSLog.default, type: .default)
                print(error)}
            if let session = loadSession() {
                self.dropDownTextFields[0]?.text = session.observerName
                self.textFields[1]?.text = session.date
                self.textFields[2]?.text = session.openTime
                self.textFields[3]?.text = session.closeTime
                self.viewVehiclesButton.isEnabled = true // Returning to view so make sure it's enabled
                self.session = session
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
        // The user is coming back the the session form for the first time since data were cleared
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
            
            self.isNewSession = true
        }
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
                        os_log("record not found", log: OSLog.default, type: .default)
                    }
                } catch {
                    os_log("Session update failed", log: OSLog.default, type: .default)
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
                    os_log("Could not find documents directory", log: OSLog.default, type: .default)
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
                    present(alertController, animated: true, completion: nil)
                }
                // Otherwise, just create a new DB with the new path
                else {
                    dbPath = documentsDirectory.appendingPathComponent("savageChecker_\(fileNameTag).db").path // Use new path
                    connectToDB()
                }
            }
            
            // Enable the nav button
            self.viewVehiclesButton.isEnabled = true
            
            // Save the UserData instance
            self.userData?.update(databaseFileName: URL(fileURLWithPath: dbPath).lastPathComponent)
        }
        
        // All fields aren't full, so disable the view vehicles button until all fields are filled in
        else {
            self.viewVehiclesButton.isEnabled = false
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
                os_log("Session insertion failed", log: OSLog.default, type: .default)
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
            os_log("Error while enumerating files", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the DB", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the Session table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the Session table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the buses table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the npsVehicles table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the nps approved table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the nps contractors table", log: OSLog.default, type: .default)
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
        } catch {
            os_log("Couldn't cofigure the the employee table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the rightofway table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the tekCampers table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the photographers table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the accessibilty table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the cyclists table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the subsistenceUsers table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the roadLottery table", log: OSLog.default, type: .default)
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
            os_log("Couldn't cofigure the the other table", log: OSLog.default, type: .default)
        }
        
    }
}
