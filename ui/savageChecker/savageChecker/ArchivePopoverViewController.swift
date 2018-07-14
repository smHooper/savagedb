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
    
    let borderSpacing: CGFloat = 8.0
    
    //MARK: - Layout
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Open connection to the DB
        do {
            db = try Connection(dbPath)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        loadSession()
        
        setUpLayout()
        
        // Do any additional setup after loading the view.
    }

    func setUpLayout() {
        let controllerFrame = self.view.frame
        
        // Set up the message
        let message = "Are you sure you want to archive the data? If you click Save, you won't be able to view or edit it."
        let messageFrame = CGRect(x: controllerFrame.minX + self.borderSpacing, y: controllerFrame.minY + self.borderSpacing, width: controllerFrame.width - self.borderSpacing * CGFloat(2), height: CGFloat(40))
        //let messageView = UITextView(frame: messageFrame)
        let messageView = UITextView()
        self.view.addSubview(messageView)
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        messageView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.borderSpacing).isActive = true
        messageView.widthAnchor.constraint(equalToConstant: self.view.frame.width - self.borderSpacing * CGFloat(2)).isActive = true
        messageView.heightAnchor.constraint(equalToConstant: CGFloat(60)).isActive = true
        messageView.font = UIFont.systemFont(ofSize: 14)
        messageView.text = message
        
        let label = UILabel()
        label.text = "File name"
        self.view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: self.borderSpacing).isActive = true
        label.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: self.borderSpacing * CGFloat(3)).isActive = true
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let now = Date()
        let currentTime = formatter.string(from: now).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "_")
        let fileNameTag = "\(session.observerName.replacingOccurrences(of: " ", with: "_"))_\(session.date.replacingOccurrences(of: " ", with: "_"))_\(currentTime))"
        let fileName = "savageChecker_\(fileNameTag))"
        let fileNameField = UITextField()
        fileNameField.text = fileName
        self.view.addSubview(fileNameField)
        fileNameField.translatesAutoresizingMaskIntoConstraints = false
        fileNameField.leftAnchor.constraint(equalTo: label.leftAnchor).isActive = true
        fileNameField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: self.borderSpacing).isActive = true
        fileNameField.widthAnchor.constraint(equalToConstant: messageView.frame.width).isActive = true
        fileNameField.frame.size.height = 28.5
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
