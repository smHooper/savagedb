//
//  ArchivePopoverViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 7/13/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import SQLite
import os.log

class ArchivePopoverViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: - Properties
    var db: Connection!
    let sessionsTable = Table("sessions")
    let idColumn = Expression<Int64>("id")
    let observerNameColumn = Expression<String>("observer_name")
    let dateColumn = Expression<String>("date")
    let openTimeColumn = Expression<String>("open_time")
    let closeTimeColumn = Expression<String>("close_time")
    let documentInteractionController = UIDocumentInteractionController()
    
    var session: Session!
    var fileName: String!
    let borderSpacing: CGFloat = 12.0
    
    //MARK: - Layout
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.view.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
        //addBackground()
        
        // Open connection to the DB
        do {
            db = try Connection(dbPath)
        } catch let error {
            print(error.localizedDescription)
            os_log("Error connecting to DB in ArchivePopoverViewController.viewDidLoad()", log: OSLog.default, type: .debug)
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
    /*func getVisibleFrame() -> CGRect {
        let frame = self.view.frame// frame is actually the size of the device even though preferredContentSize is smaller
        let contentSize = self.preferredContentSize
        let controllerMinX = frame.minX + frame.width/2 - contentSize.width/2
        let controllerMinY = frame.minY + frame.height/2 - contentSize.height/2
        let controllerFrame = CGRect(x: controllerMinX, y: controllerMinY, width: contentSize.width, height: contentSize.height)
        
        return controllerFrame
    }*/
    
    // Set up subviews
    func setUpLayout() {

        let controllerFrame = getVisibleFrame()
        
        // Add translucent blurred image
        /*for subview in self.view.subviews {
            if subview.tag == -1 {
                subview.frame = controllerFrame
                subview.contentMode = .center
            }
        }*/
        
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
        //  Split the message where the image of 'swtichDatabase' button will be inserted so we have the length before the image
        let messageBeforeAttachment = "If you press Archive, your data will be saved and a blank database will be created. You will have to use the  "
        let messageAfterAttachment = "   button to make changes to your previous observations."
        let message = messageBeforeAttachment + messageAfterAttachment
        
        let messageFrame = CGRect(x: controllerFrame.minX + self.borderSpacing, y: controllerFrame.minY + self.borderSpacing, width: controllerFrame.width - self.borderSpacing * CGFloat(2), height: CGFloat(40))
        let messageView = UITextView(frame: messageFrame)
        messageView.font = UIFont.systemFont(ofSize: 18)
        self.view.addSubview(messageView)
        let messageHeight = message.height(withConstrainedWidth: messageViewWidth - 20, font: messageView.font!)
        let textHeightWithCurrentFont = "A".height(withConstrainedWidth: messageViewWidth - 20, font: messageView.font!)
        let messageViewHeight = messageHeight + (messageView.textContainerInset.top + messageView.textContainerInset.bottom) + textHeightWithCurrentFont
        
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        messageView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: self.borderSpacing).isActive = true
        messageView.widthAnchor.constraint(equalToConstant: messageViewWidth).isActive = true
        messageView.heightAnchor.constraint(equalToConstant: CGFloat(messageViewHeight)).isActive = true
        messageView.isEditable = false
        messageView.backgroundColor = UIColor.clear
        
        // Set the text with an attachment
        let attributedString = NSMutableAttributedString(string: message)
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "switchDatabaseIcon")
        let scale =  attachment.image!.size.height / textHeightWithCurrentFont * 2 //This is counter intuitive. Scale of >1 makes image smaller
        attachment.image = UIImage(cgImage: (UIImage(named: "switchDatabaseIcon")?.cgImage)!, scale: scale, orientation: .up)
        let attributedStringWithImage = NSAttributedString(attachment: attachment)
        attributedString.replaceCharacters(in: NSMakeRange(messageBeforeAttachment.count, 1), with: attributedStringWithImage) // Insert image at end of beforeAttachment string
        attributedString.addAttribute(.font, value: messageView.font!, range: NSMakeRange(0, message.count))//Have set font for attributedString because it overrides messageView.font
        messageView.attributedText = attributedString
        
        // Add a lable
        let label = UILabel()
        label.text = "File name"
        self.view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: self.borderSpacing).isActive = true
        label.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: self.borderSpacing * CGFloat(2)).isActive = true
        
        // Add a text field for the file name
        self.fileName = URL(fileURLWithPath: dbPath).lastPathComponent //"savageChecker_\(fileNameTag).db"
        let fileNameTextField = UITextField()
        fileNameTextField.text = self.fileName
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
        
        // Draw lines to separate buttons from text
        //  Horizontal line
        let lineColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.4)
        let horizontalLine = UIView(frame: CGRect(x:0, y: 0, width: controllerFrame.width, height: 1))
        self.view.addSubview(horizontalLine)
        horizontalLine.backgroundColor = lineColor
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        horizontalLine.centerXAnchor.constraint(equalTo: messageView.centerXAnchor).isActive = true
        horizontalLine.topAnchor.constraint(equalTo: archiveButton.topAnchor, constant: -self.borderSpacing/2).isActive = true
        horizontalLine.widthAnchor.constraint(equalTo: messageView.widthAnchor).isActive = true
        horizontalLine.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        
        //  Vertical line
        let verticalLine = UIView(frame: CGRect(x:0, y: 0, width: 1, height: 1))
        self.view.addSubview(verticalLine)
        verticalLine.backgroundColor = lineColor
        verticalLine.translatesAutoresizingMaskIntoConstraints = false
        verticalLine.centerXAnchor.constraint(equalTo: messageView.centerXAnchor).isActive = true
        verticalLine.topAnchor.constraint(equalTo: archiveButton.topAnchor, constant: -self.borderSpacing/2).isActive = true
        verticalLine.widthAnchor.constraint(equalToConstant: 1.0).isActive = true
        verticalLine.bottomAnchor.constraint(equalTo: archiveButton.bottomAnchor).isActive = true
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
        
        
        /*if fileManager.fileExists(atPath: outputURL.path) {
            print("File already exists")
        } else {
            do {
                try fileManager.copyItem(at: dbURL, to: outputURL)//(atPath: (dbURL.absoluteString)!, toPath: outputURL!)
            } catch {
                print(error)
                os_log("Could not save copy of DB", log: OSLog.default, type: .debug)
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
                os_log("Could not delete row from DB", log: OSLog.default, type: .debug)
            }
        }*/
        
        // Prepare the session controller by clearing all fields and disabling the navigation button
        let presentingController = self.presentingViewController?.presentingViewController as! ShiftInfoViewController
        presentingController.dropDownTextFields[0]!.text = ""
        presentingController.isNewSession = true
        presentingController.session = nil
        /*for (_, textField) in presentingController.textFields {
            textField.text = ""
        }*/
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        presentingController.textFields[1]?.text = formatter.string(from: now)
        presentingController.textFields[2]?.text = "6:30 AM"
        presentingController.textFields[3]?.text = "9:30 PM"
        presentingController.saveButton.isEnabled = false
        
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
        guard let text = textField.text else {
            return
        }
        guard let fileExtension = text.split(separator: ".").last else {
            return
        }

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
            print(error.localizedDescription)
            os_log("Error loading session", log: OSLog.default, type: .debug)
        }
        if rows.count > 1 {
            //fatalError("Multiple sessions found")
            os_log("Multiple sessions found", log: OSLog.default, type: .debug)
        }
        for row in rows{
            self.session = Session(id: Int(row[idColumn]), observerName: row[observerNameColumn], openTime:row[openTimeColumn], closeTime: row[closeTimeColumn], givenDate: row[dateColumn])
            //print("Session date: \(row[dateColumn])")
        }
        //return session
    }
    

}
