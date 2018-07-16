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
    
    var session: Session!
    
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
        
        // Set up the message
        let message = "Are you sure you want to archive your data? If you press Archive, your data will be saved but you won't be able to view or edit your observations from this device."
        let messageFrame = CGRect(x: controllerFrame.minX + self.borderSpacing, y: controllerFrame.minY + self.borderSpacing, width: controllerFrame.width - self.borderSpacing * CGFloat(2), height: CGFloat(40))
        let messageView = UITextView(frame: messageFrame)
        messageView.font = UIFont.systemFont(ofSize: 18)
        self.view.addSubview(messageView)
        let messageViewWidth = controllerFrame.width - self.borderSpacing * CGFloat(2)
        let messageViewHeight = message.height(withConstrainedWidth: messageViewWidth, font: messageView.font!) + messageView.textContainerInset.top + messageView.textContainerInset.bottom
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        messageView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.borderSpacing).isActive = true
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
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let now = Date()
        let currentTimeString = formatter.string(from: now).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "-")
        let dateString = "\(session.date.replacingOccurrences(of: "/", with: "-"))"
        let fileNameTag = "\(session.observerName.replacingOccurrences(of: " ", with: "_"))_\(dateString)_\(currentTimeString)"
        let fileName = "savageChecker_\(fileNameTag).db"
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
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Archive", for: .normal)
        saveButton.titleLabel!.font = UIFont.systemFont(ofSize: 22)
        saveButton.addTarget(self, action: #selector(dismissController), for: .touchUpInside)
        self.view.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.centerXAnchor.constraint(equalTo: messageView.centerXAnchor, constant: -controllerFrame.width/4).isActive = true
        saveButton.bottomAnchor.constraint(equalTo: messageView.topAnchor, constant: controllerFrame.height - self.borderSpacing * 3).isActive = true//self.view.bottomAnchor, constant: -(frame.maxY - controllerFrame.maxY - self.borderSpacing)).isActive = true
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel!.font = UIFont.systemFont(ofSize: 22)
        cancelButton.addTarget(self, action: #selector(dismissController), for: .touchUpInside)
        self.view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.centerXAnchor.constraint(equalTo: messageView.centerXAnchor, constant: controllerFrame.width/4).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: messageView.topAnchor, constant: controllerFrame.height - self.borderSpacing * 3).isActive = true//self.view.bottomAnchor, constant: -(frame.maxY - controllerFrame.maxY - self.borderSpacing)).isActive = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Navigation
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
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
