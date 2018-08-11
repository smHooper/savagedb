//
//  ArchivePopoverViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 7/13/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import SQLite

class ArchivePopoverViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: - Properties
    var db: Connection!
    let sessionsTable = Table("sessions")
    let idColumn = Expression<Int64>("id")
    let observerNameColumn = Expression<String>("observerName")
    let dateColumn = Expression<String>("date")
    let openTimeColumn = Expression<String>("openTime")
    let closeTimeColumn = Expression<String>("closeTime")
    let documentInteractionController = UIDocumentInteractionController()
    
    var session: Session!
    var fileName: String!
    let borderSpacing: CGFloat = 12.0
    
    //MARK: - Layout
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
        // Open connection to the DB
        do {
            db = try Connection(dbPath)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // Get session data for making new file name
        loadSession()
        
        // Set up the view
        setUpLayout()
        
        // Add gesture recognizer to dismiss keyboard
        hideKeyboardWhenTappedAround()
        
        // Maybe add another gesture recognizer to dismiss the whole view when tapped outside of its visible bounds. This might have to happen in BaseTableView
        
    }
    
    // Helper function to get the actual visible frame because self.view.frame actually returns a frame bordering the whole device
    func getVisibleFrame() -> CGRect {
        let frame = self.view.frame// frame is actually the size of the device even though preferredContentSize is smaller
        let contentSize = self.preferredContentSize
        let controllerMinX = frame.minX + frame.width/2 - contentSize.width/2
        let controllerMinY = frame.minY + frame.height/2 - contentSize.height/2
        let controllerFrame = CGRect(x: controllerMinX, y: controllerMinY, width: contentSize.width, height: contentSize.height)
        
        return controllerFrame
    }
    
    // Set up subviews
    func setUpLayout() {

        let controllerFrame = getVisibleFrame()
        
        // Add title message
        let titleMessage = "Are you sure you want to archive your data?"
        let messageViewWidth = controllerFrame.width - self.borderSpacing * CGFloat(2)
        let titleFrame = CGRect(x: controllerFrame.minX + self.borderSpacing, y: controllerFrame.minY + self.borderSpacing, width: controllerFrame.width - self.borderSpacing * CGFloat(2), height: CGFloat(40))
        let titleView = UITextView(frame: titleFrame)
        titleView.font = UIFont.boldSystemFont(ofSize: 20)
        self.view.addSubview(titleView)
        let titleViewHeight = titleMessage.height(withConstrainedWidth: messageViewWidth, font: titleView.font!) + titleView.textContainerInset.top + titleView.textContainerInset.bottom
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        titleView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.borderSpacing).isActive = true
        titleView.widthAnchor.constraint(equalToConstant: messageViewWidth).isActive = true
        titleView.heightAnchor.constraint(equalToConstant: CGFloat(titleViewHeight)).isActive = true
        titleView.text = titleMessage
        titleView.isEditable = false
        titleView.backgroundColor = UIColor.clear
        titleView.textAlignment = .center
        
        // Add detailed message
        let message = "If you press Archive, your data will be saved but you won't be able to view or edit your observations from this device."
        let messageFrame = CGRect(x: controllerFrame.minX + self.borderSpacing, y: controllerFrame.minY + self.borderSpacing, width: controllerFrame.width - self.borderSpacing * CGFloat(2), height: CGFloat(40))
        let messageView = UITextView(frame: messageFrame)
        messageView.font = UIFont.systemFont(ofSize: 16)
        self.view.addSubview(messageView)
        let messageViewHeight = message.height(withConstrainedWidth: messageViewWidth - 20, font: messageView.font!) + (messageView.textContainerInset.top + messageView.textContainerInset.bottom)
        print("messageView.textContainerInset.top: \(messageView.textContainerInset.top) \nmessageView.textContainerInset.bottom: \(messageView.textContainerInset.bottom)")
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        messageView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: self.borderSpacing).isActive = true
        messageView.widthAnchor.constraint(equalToConstant: messageViewWidth).isActive = true
        messageView.heightAnchor.constraint(equalToConstant: CGFloat(messageViewHeight)).isActive = true
        messageView.text = message
        messageView.isEditable = false
        messageView.backgroundColor = UIColor.clear
        
        // Add a lable
        let label = UILabel()
        label.text = "File name"
        self.view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: self.borderSpacing).isActive = true
        label.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: self.borderSpacing * CGFloat(2)).isActive = true
        
        // Add a text field for the file name
        // *******Change this so fileName is just the filename. Then maybe set dbPath to "" or something **********
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let now = Date()
        let currentTimeString = formatter.string(from: now).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "-")
        let dateString = "\(session.date.replacingOccurrences(of: "/", with: "-"))"
        let fileNameTag = "\(session.observerName.replacingOccurrences(of: " ", with: "_"))_\(dateString)_\(currentTimeString)"
        self.fileName = "savageChecker_\(fileNameTag).db"
        let fileNameTextField = UITextField()
        fileNameTextField.text = fileName
        self.view.addSubview(fileNameTextField)
        fileNameTextField.translatesAutoresizingMaskIntoConstraints = false
        fileNameTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        fileNameTextField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: self.borderSpacing).isActive = true
        fileNameTextField.widthAnchor.constraint(equalToConstant: messageView.frame.width).isActive = true
        fileNameTextField.frame.size.height = 28.5
        fileNameTextField.borderStyle = .roundedRect
        fileNameTextField.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        fileNameTextField.autocorrectionType = .no
        fileNameTextField.autocapitalizationType = .none
        fileNameTextField.delegate = self
        
        // Add buttons
        let archiveButton = UIButton(type: .system)
        archiveButton.setTitle("Archive", for: .normal)
        archiveButton.titleLabel!.font = UIFont.systemFont(ofSize: 22)
        archiveButton.addTarget(self, action: #selector(archiveButtonPressed), for: .touchUpInside)
        self.view.addSubview(archiveButton)
        archiveButton.translatesAutoresizingMaskIntoConstraints = false
        archiveButton.centerXAnchor.constraint(equalTo: messageView.centerXAnchor, constant: -controllerFrame.width/4).isActive = true
        archiveButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -self.borderSpacing).isActive = true//self.view.bottomAnchor, constant: -(frame.maxY - controllerFrame.maxY - self.borderSpacing)).isActive = true
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel!.font = UIFont.systemFont(ofSize: 22)
        cancelButton.addTarget(self, action: #selector(dismissController), for: .touchUpInside)
        self.view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.centerXAnchor.constraint(equalTo: messageView.centerXAnchor, constant: controllerFrame.width/4).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -self.borderSpacing).isActive = true//self.view.bottomAnchor, constant: -(frame.maxY - controllerFrame.maxY - self.borderSpacing)).isActive = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Navigation
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    
    func saveFile(url: URL) {
        
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentOptionsMenu(from: view.frame, in: view, animated: true)
    }
    
    
    @objc func archiveButtonPressed() {
        // Shouldn't need to check if the file alread exists because time stamp in filename should prevent that
        let fileManager = FileManager.default
        let dbURL = URL(fileURLWithPath: dbPath).absoluteURL
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let outputURL = URL(fileURLWithPath: documentsDirectory).appendingPathComponent(self.fileName)
        
        
        if fileManager.fileExists(atPath: outputURL.absoluteString) {
            print("File already exists")
        } else {
            do {
                try fileManager.copyItem(at: dbURL, to: outputURL)//(atPath: (dbURL.absoluteString)!, toPath: outputURL!)
            } catch {
                print(error)
            }
        }
        
        // Delete all records from the db
        //  First get names of all tables in the DB
        let tableQuery: Statement
        do {
            tableQuery = try db.prepare("SELECT name FROM sqlite_master WHERE name NOT LIKE('sqlite%');")
        } catch {
            fatalError("Could not fetch all tables because \(error.localizedDescription)")
        }
        //  Loop through all tables and delete all records
        for row in tableQuery {
            let tableName = "\(row[0]!)"
            let table = Table(tableName)
            do {
                try db.run(table.delete()) // Deletes all rows in table
            } catch {
                print("Could not delete records from \(tableName) because \(error.localizedDescription)")
            }
        }
        
        // Prepare the session controller by clearing all fields and disabling the navigation button
        let presentingController = self.presentingViewController?.presentingViewController as! SessionViewController
        presentingController.dropDownTextFields[0]!.text = ""
        /*for (_, textField) in presentingController.textFields {
            textField.text = ""
        }*/
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        presentingController.textFields[1]?.text = formatter.string(from: now)
        presentingController.textFields[2]?.text = "6:30 AM"
        presentingController.textFields[3]?.text = "9:30 PM"
        presentingController.viewVehiclesButton.isEnabled = false
        
        // Add an activity indicator and show it for a couple seconds. Otherwise, the transition is too abrupt
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.color = UIColor.gray
        activityIndicator.center = self.view.center
        let translucentWhiteView = UIView(frame: self.view.frame)
        translucentWhiteView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        self.view.addSubview(translucentWhiteView)
        self.view.addSubview(activityIndicator)
        
        let delay = 2.0
        activityIndicator.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            translucentWhiteView.removeFromSuperview()
            presentingController.dismiss(animated: true, completion: nil)
        }
        
    }
    
    //MARK: - UITextFieldDelgate methods
    // Make sure the file ends with the extension .db
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("textField editing did end")
        guard let text = textField.text else {
            return
        }
        guard let fileExtension = text.split(separator: ".").last else {
            return
        }
        print("appending extension")
        if !(fileExtension == "db") {
            textField.text = "\(text).db"
        }
        self.fileName = textField.text!
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        dismissKeyboard()
        return true
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    //MARK: Data model methods
    func loadSession() {
        // ************* check that the table exists first **********************
        var rows = [Row]()
        do {
            rows = Array(try db.prepare(sessionsTable))
        } catch {
            fatalError(error.localizedDescription)
        }
        if rows.count > 1 {
            fatalError("Multiple sessions found")
        }
        for row in rows{
            self.session = Session(id: Int(row[idColumn]), observerName: row[observerNameColumn], openTime:row[openTimeColumn], closeTime: row[closeTimeColumn], givenDate: row[dateColumn])
            //print("Session date: \(row[dateColumn])")
        }
        //return session
    }
    

}
