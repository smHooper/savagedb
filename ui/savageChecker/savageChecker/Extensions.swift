//
//  Extensions.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/31/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import SQLite

// Get dimensions of text labels
extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}


extension UIViewController {
    
    static var formSheetSize = CGSize(width: min(UIScreen.main.bounds.width, 400), height: min(UIScreen.main.bounds.height, 600))
    var formSheetFrame: CGRect {
        let contentSize = UIViewController.formSheetSize//CGSize(width: min(self.view.frame.width, 400), height: min(self.view.frame.height, 600))
        let frame = self.view.frame
        let controllerMinX = frame.minX + frame.width/2 - contentSize.width/2
        let controllerMinY = frame.minY + frame.height/2 - contentSize.height/2
        return CGRect(x: controllerMinX, y: controllerMinY, width: contentSize.width, height: contentSize.height)
    }
    
    var blurredSnapshotView: UIView {
        get {
            let blurEffect = UIBlurEffect(style: .light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            // Only apply the blur if the user hasn't disabled transparency effects
            if !UIAccessibilityIsReduceTransparencyEnabled() {
                self.view.backgroundColor = .clear
                
                let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
                let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
                
                blurEffectView.frame = self.view.frame//bounds
                blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
                self.view.addSubview(blurEffectView)
                self.view.addSubview(vibrancyView)
                
            } else {
                // ************ Might need to make a dummy blur effect so that removeFromSuperview() in AddObservationMenu transition doesn't choke
                self.view.backgroundColor = .black
            }
        
            
            // Get image of all currently visible views with the blur
            let backgroundView = UIImageView(image: self.view.takeSnapshot())
            
            // remove blurview
            blurEffectView.removeFromSuperview()
            
            // Since a .formSheet modal presentation will show the image in the upper left corner of the frame, offset the frame so it displays in the right place
            backgroundView.contentMode = .scaleAspectFill
            let currentFrame = self.view.frame
            backgroundView.frame = CGRect(x: currentFrame.minX - formSheetFrame.minX, y: currentFrame.minY - formSheetFrame.minY, width: currentFrame.width, height: currentFrame.height)
            
            // Add translucent white
            let whiteAlpha: CGFloat = 0 // this is just here in case I want to use this in the future
            if whiteAlpha > 0 {
                let translucentWhite = UIView(frame: backgroundView.frame)
                translucentWhite.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: whiteAlpha)
                backgroundView.addSubview(translucentWhite)
            }
            
            return backgroundView
        }
        /*set {
            
        }*/
    }
    
    func getCurrentDateTime() -> (date: String, time: String) {
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let currentTime = formatter.string(from: now)
        
        formatter.timeStyle = .none
        formatter.dateStyle = .short
        let currentDate = formatter.string(from: now)
        
        return (date: currentDate, time: currentTime)
    }
    
    func addBackground(showWhiteView: Bool = true) {
        /*let startingBackGroundView = UIImageView(image: UIImage(named: "viewControllerBackground"))
        startingBackGroundView.frame = self.view.frame
        startingBackGroundView.contentMode = .scaleAspectFill
        self.view.addSubview(startingBackGroundView)*/
        
        // Try to load an image in the Documents directory called background.png.
        //  If this is the first time the app is opened or if the file got moved,
        //  save the default image to Documents and try again
        
        /*let defaultImage = UIImage(named: "viewControllerBackgroundBlurred")
        var backgoundImage: UIImage
        guard var image = loadBackgroundImage(named: "background.png") else {
            backgoundImage = defaultImage!
            saveImage(image: backgoundImage)
            return
        }*/
        
        let backgroundImage: UIImage
        if let image = loadBackgroundImage(named: "background.png") {
            backgroundImage = image
        } else {
            let defaultImage = UIImage(named: "viewControllerBackgroundBlurred")
            let _ = saveImage(image: defaultImage!)
            backgroundImage = defaultImage!
        }
        
        let backgroundImageView = UIImageView(image: backgroundImage)//"UIImage(named: viewControllerBackgroundBlurred"))//
        backgroundImageView.frame = self.view.frame
        backgroundImageView.contentMode = .scaleAspectFill
        
        let translucentView = UIView(frame: self.view.frame)
        translucentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        let backgroundView = UIView()//frame: self.view.frame)
        //backgroundView.backgroundColor = UIColor.red
        if showWhiteView {backgroundView.addSubview(translucentView)}
        backgroundView.addSubview(backgroundImageView)
        backgroundView.sendSubview(toBack: backgroundImageView)
        backgroundView.tag = -1
        self.view.addSubview(backgroundView)
        
        // Set constraints to the whole view
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        backgroundView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        backgroundView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        if showWhiteView {
            translucentView.translatesAutoresizingMaskIntoConstraints = false
            translucentView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            translucentView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            translucentView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            translucentView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        }
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        backgroundImageView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        backgroundImageView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        /*let backgroundImageView = UIImageView(image: UIImage(named: "viewControllerBackgroundBlurred"))
        backgroundImageView.frame = self.view.frame
        backgroundImageView.contentMode = .scaleAspectFill
        
        let translucentView = UIView(frame: self.view.frame)
        translucentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        let backgroundView = UIView(frame: self.view.frame)
        backgroundView.addSubview(translucentView)
        backgroundView.addSubview(backgroundImageView)
        backgroundView.sendSubview(toBack: backgroundImageView)
        backgroundView.tag = -1
        self.view.addSubview(backgroundView)*/
    }
    
    func loadBackgroundImage(named: String) -> UIImage? {
        if let documentsDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: documentsDirectory.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    
    func saveImage(image: UIImage) -> Bool {
        guard let data = UIImageJPEGRepresentation(image, 1) ?? UIImagePNGRepresentation(image) else {
            return false
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        do {
            try data.write(to: directory.appendingPathComponent("background.png")!)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    func getVisibleFrame() -> CGRect {
        let frame = self.view.frame// frame is actually the size of the device even though preferredContentSize is smaller
        let contentSize = self.preferredContentSize
        let controllerMinX = frame.minX + frame.width/2 - contentSize.width/2
        let controllerMinY = frame.minY + frame.height/2 - contentSize.height/2
        let controllerFrame = CGRect(x: controllerMinX, y: controllerMinY, width: contentSize.width, height: contentSize.height)
        
        return controllerFrame
    }
    
    
    func getTopMostController() -> UIViewController {
        var topController = UIApplication.shared.keyWindow?.rootViewController
        while topController?.presentedViewController != nil {
            topController = topController?.presentedViewController
        }
        
        return topController!
    }
    
    func loadUserData() -> UserData? {
        let userData = NSKeyedUnarchiver.unarchiveObject(withFile: userDataPath) as? UserData
        //if userData != nil { print("User data successfully loaded: \(userData!.activeDatabase)") }
        
        return userData
    }
    
    
    func getCleanedDeviceName() -> String? {
        let deviceName = UIDevice.current.name
        var cleanedDeviceName: String?
        if let regex = try? NSRegularExpression(pattern: "[^a-zA-Z0-9]", options: .caseInsensitive) {
            cleanedDeviceName = regex.stringByReplacingMatches(in: deviceName, options: [], range: NSRange(location: 0, length:  deviceName.count), withTemplate: "_")
        }
        
        return cleanedDeviceName
    }
    
    // Get the datestamp for the dbPath
    func getFileNameTag() -> String {
        let formatter = DateFormatter()
        let now = Date()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        let dateString = formatter.string(from: now).replacingOccurrences(of: "/", with: "-")//.replacingOccurrences(of: "1", with: "2")
        
        return "\(dateString)_\(getCleanedDeviceName() ?? UIDevice.current.name)"
    }
    
    
    @objc func checkBoxTapped(sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseInOut, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            
        }) { (success) in
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
                sender.isSelected = !sender.isSelected
                sender.transform = .identity
            }, completion: nil)
        }
    }
    

    
    // Get the current screen size
    func getCurrentScreenFrame() -> CGRect {
        let screenSize = UIScreen.main.bounds // This is actually the screen size before rotation
        let isLandscape = UIDevice.current.orientation.isLandscape
        let currentScreenFrame: CGRect = {
            if isLandscape {
                return CGRect(x: 0, y: 0, width: max(screenSize.width, screenSize.height), height: min(screenSize.width, screenSize.height))
            } else {
                return CGRect(x: 0, y: 0, width: min(screenSize.width, screenSize.height), height: max(screenSize.width, screenSize.height))
            }
        }()
        
        return currentScreenFrame
    }
    

    func getCurrentDbPath() -> String {
        if let userData = loadUserData() {
            // Check if the active path's exists
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(userData.activeDatabase).path
        } else {
            // Use global path
            return dbPath
        }
    }
    
    
    func currentDbExists() -> Bool {
        let currentDbPath = getCurrentDbPath()
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: currentDbPath)
    }
    

    func showShiftInfoForm() {
        let shiftViewController = ShiftInfoViewController()
        shiftViewController.modalPresentationStyle = .formSheet
        UIViewController.formSheetSize = CGSize(width: min(self.view.frame.width, 400), height: min(self.view.frame.height, 600)) // Set this because it affects the bounds of the blurEffectView
        shiftViewController.preferredContentSize = UIViewController.formSheetSize//CGSize.init(width: 600, height: 600)
        
        // Add blurred background from current view
        //let popoverFrame = shiftViewController.getVisibleFrame()
        let backgroundView = self.blurredSnapshotView//getBlurredSnapshot(frame: formSheetFrame)
        shiftViewController.view.addSubview(backgroundView)
        shiftViewController.view.sendSubview(toBack: backgroundView)
        
        present(shiftViewController, animated: true, completion: nil)
    }
    
    // Either show the shift info form or send an alert askin the user if they want to start a new shift.
    //  This gets called when the app gets back the focus after being paused or the device was sleeping and at startup.
    func showNewShiftAlert() {
        
        // If userData doesn't exist, just show the shift info form (this is likely because this is the first time the app is being opened after install)
        guard let userData = loadUserData() else {
            showShiftInfoForm()
            return
        }
        
        let tag = getFileNameTag()

        // If the user has the shift info form open, close it. This way, if it's opened again, the proper loadData() code will run.
        //  Also, since the controller is shown modally as a .formsheet, another shiftinfo form will just be opened on top of the existing one
        var currentViewController = getTopMostController()
        let controllerDescription = String(describing: currentViewController)
        let currentControllerClassName = controllerDescription.contains("UIAlertController") ?
            "\(controllerDescription.split(separator: ":")[0])".replacingOccurrences(of: "<", with: "") :
            "\(controllerDescription.split(separator: ".")[1].split(separator: ":")[0])"
        if currentControllerClassName == "ShiftInfoViewController" {
            let presentedController = currentViewController
            currentViewController = currentViewController.presentingViewController!
            presentedController.dismiss(animated: false, completion: nil)
        }
        
        // If the current date (really the filenam tag, which includes the device name now) is different from the date the user data was created, that means this should be a new shift
        //  Also, don't show this form on top of a DB browser, G Drive Upload, or a QR Scanner controller because the shiftinfo form doesn't load properly. Also, the scanner controller
        //  and the G Drive upload controllers send their own alerts, which cause the app to lose and regain focus. This means that the code gets called when this happens, which shouldn't happen.
        //  Lastly, if the new shift alert is already open, don't try to open it again
        if tag != userData.creationDate && currentViewController.modalPresentationStyle != .formSheet && currentControllerClassName != "ScannerViewController" && currentViewController.title != "New shift?" {//currentControllerClassName != "UIAlertController" {
            let alertTitle = "New shift?"
            let alertMessage = "It looks like this is a new day (full of promise and excitement!). All observations should, therefore, be recorded as a new shift. Would you like to start a new shift now? If you press \"No\", you can press the shift info button later to start a new shift."
            let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Yes, start a new one", style: .cancel, handler: {handler in
                try? FileManager.default.removeItem(atPath: userDataPath)
                currentViewController.showShiftInfoForm()
            }))
            alertController.addAction(UIAlertAction(title: "No, keep using the same one", style: .default, handler: nil))
            currentViewController.present(alertController, animated: true, completion: nil)
        } else {
            showShiftInfoForm()
        }
    }
    
    
    func showDbNotExistsAlert() {
        // If the current DB does not exist, alert the user and force them to create a new DB
        let currentDbName = getCurrentDbPath().split(separator: "/").last ?? ""
        let alertTitle = "No database file found"
        let alertMessage = "The database named \(currentDbName) that you are trying to access does not exist or could not be found, and you can't perform the current operation without a valid file. Perhaps the file was deleted? Press OK to create a new database, then re-try what you were trying to do."
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {handler in
            //alertController.dismiss(animated: false, completion: nil)
            self.showShiftInfoForm()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    
    func presentLoadBackupAlert(presentCompletion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: "Invalid data file", message: "The data in this file are not in the correct format or might have gotten corrupted. Would you like to load the backup file (no data will be lost)? If you press \"No\", you will not be able to record an observaton for this vehicle type", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Yes, load the backup file", style: .cancel, handler: {handler in
            self.loadBackupDb()
            db = try? Connection(dbPath)
            self.showGenericAlert(message: "You should now be able to continue doing what you were before.", title: "Backup successfully loaded", takeScreenshot: false, presentCompletion: presentCompletion)
        }))
        alertController.addAction(UIAlertAction(title: "No", style: .default, handler: nil))//{action in self.dismiss(animated: true, completion: nil)}))
        present(alertController, animated: true, completion: nil)
    }
    
    
    
    // Show a generic warning.info message
    func showGenericAlert(message: String = "An unknown error has occurred", title: String = "Error", takeScreenshot: Bool = true, presentCompletion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        
        // Code block for completion if takeScreenshot is true
        let takeScreenshotCompletion = {
            if takeScreenshot {
                let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
                let fileName = "error_screenshot \(Date()).png"
                let screenshotDir = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("errors")
                let fileManager = FileManager.default
                var isDir: ObjCBool = false
                if !fileManager.fileExists(atPath: screenshotDir.path, isDirectory:&isDir) {
                    try? fileManager.createDirectory(at: screenshotDir, withIntermediateDirectories: true, attributes: nil)
                }
                let imgURL = fileManager.fileExists(atPath: screenshotDir.path, isDirectory:&isDir) ? screenshotDir.appendingPathComponent(fileName) : URL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName)
                let screenshot = alertController.view.takeSnapshot()
                try? UIImagePNGRepresentation(screenshot)?.write(to: imgURL)
            }
        }
        // run in separate process so that it present works in viewDidLoad
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: takeScreenshot ? takeScreenshotCompletion : presentCompletion)
        }
    }
    
    
    func dbHasData(path: String, tableName: String? = nil, excludeShiftInfo: Bool = true) -> Bool {
        // Try to connect to the database
        if let thisDB = try? Connection(path) {
            // Try to run a query to get all table names that would have data
            var tableSQL = "SELECT name FROM sqlite_master WHERE name NOT LIKE('sqlite%')"
            if let table = tableName {
                tableSQL += " AND name LIKE('\(table)')"
            }
            if excludeShiftInfo {
                tableSQL += " AND name NOT LIKE('sessions')"
            }
            if let statement = try? thisDB.prepare(tableSQL) {
                // Loop through each row (table name)
                for row in statement {
                    // If the first column returns something other than nil && you can get a count from it && the count is greater than 0, return true
                    if let tableName = row[0], let count = try? thisDB.scalar("SELECT count(*) FROM \(tableName)") as? Int64, Int(count ?? 0) > 0 {
                        return true
                    }
                }
            }
        }
        
        // If we got here, none of the tables had data
        return false
    }
    
    
    func backupCurrentDb() {
        
        let fileManager = FileManager.default
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let backupDir = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("backup")
        var isDir: ObjCBool = false
        if !fileManager.fileExists(atPath: backupDir.path, isDirectory: &isDir) {
            try? fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true, attributes: nil)
        }
        let currentDbURL = URL(fileURLWithPath: getCurrentDbPath())
        let backupDbURL = backupDir.appendingPathComponent(currentDbURL.lastPathComponent)
        
        if fileManager.fileExists(atPath: backupDbURL.path) {
            do {
                try fileManager.removeItem(at: backupDbURL)
            } catch {
                showGenericAlert(message: "A problem occurred while trying to delete the current data backup: \(error.localizedDescription)", title: "Data backup failed", takeScreenshot: true)
                return
            }
        }
        do {
            try fileManager.copyItem(at: currentDbURL, to: backupDbURL)
        } catch {
            showGenericAlert(message: "A problem occurred while backing up the app data to \(backupDbURL): \(error.localizedDescription)", title: "Data backup failed", takeScreenshot: true)
        }
        
    }
    
    
    func loadBackupDb() {
        let currentDbURL =  URL(fileURLWithPath: getCurrentDbPath())
        let currentDbName = currentDbURL.lastPathComponent
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let backupDir = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("backup")
        let backupDbURL = backupDir.appendingPathComponent(currentDbName)
        let fileManager = FileManager.default
        
        // Create a directory for currupted files if one doesn't already exist
        //  Don't try to catch any of the errors because this stuff doesn't matter that much and it's mostly not worth warning the user about or trying to capture the error
        let corruptFileDir = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("corrupt_files")
        var isDir: ObjCBool = false
        if !fileManager.fileExists(atPath: corruptFileDir.path, isDirectory: &isDir) {
            try? fileManager.createDirectory(at: corruptFileDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let corruptedDbName = currentDbName.replacingOccurrences(of: ".db", with: "_corrupted.db")
        let corruptDbURL = corruptFileDir.appendingPathComponent(corruptedDbName)
        // First, if there's already a version of this file in the "corrupted" dir, delete it
        if fileManager.fileExists(atPath: corruptDbURL.path) {
            try? fileManager.removeItem(at: corruptDbURL)//fileManager.replaceItemAt(corruptDbURL, withItemAt: backupDbURL, backupItemName: corruptedDbName, options: [])
        }
        
        // Try to move the currentDB to the corrupted dir. If that fails, just delete it
        do {
            try fileManager.moveItem(at: currentDbURL, to: corruptDbURL)
        } catch {
            try? fileManager.removeItem(at: currentDbURL)
        }
        
        // Now try to copy the backup to the current DB path
        do {
            try fileManager.copyItem(atPath: backupDbURL.path, toPath: currentDbURL.path)
        } catch {
            showGenericAlert(message: "A problem occurred while trying to replace the current data with the backup: \(error.localizedDescription)", title: "Failed to load data backup", takeScreenshot: true)
            return
        }
        
    }
    
    /*func dbToCSV(dbConnection: Connection?) {
        if let db = dbConnection {
            // Try to run a query to get all table names that would have data
            let tableSQL = "SELECT name FROM sqlite_master WHERE name NOT LIKE('sqlite%') AND name NOT LIKE('sessions');"
            if let statement = try? db.prepare(tableSQL) {
                // Loop through each row (table name)
                for row in statement {
                    // If the first column returns something other than nil && you can get a count from it && the count is greater than 0, return true
                    guard let tableName = row[0] else {
                        return
                    }
                    
                    var rows: [Row]
                    let thisTable = Table("\(tableName)")
                    do {
                        let rows = Array(try db.prepare(thisTable))
                        for row in rows {
                            for (index, name) in
                        }
                    } catch {
                        showGenericAlert(message: "Could not save \(tableName) because \(error.localizedDescription)", title: "Backup data error", takeScreenshot: true)
                    }
                }
            }
        }
        
    }*/
    
    
}


extension UIImageView {
    
    func blurEffect(radius: Int) -> UIImageView {
        let context = CIContext(options: nil)
        
        let currentFilter = CIFilter(name: "CIGaussianBlur")
        let beginImage = CIImage(image: self.image!)
        currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter!.setValue(radius, forKey: kCIInputRadiusKey)
        
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
        cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")
        
        let output = cropFilter!.outputImage
        let cgimg = context.createCGImage(output!, from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        
        return UIImageView(image: processedImage)
    }
}


extension UIView {
    
    func takeSnapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
}


extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}
