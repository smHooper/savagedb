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
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"]]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textFieldIds = [(label: "Observer name", placeholder: "Select or enter the observer's name", type: "dropDown"),
                             (label: "Date",          placeholder: "Select the observation date", type: "date"),
                             (label: "Open time",     placeholder: "Select the check station openning time", type: "time"),
                             (label: "Close time",    placeholder: "Select the check station closing time", type: "time")]
        self.dropDownMenuOptions = ["Observer name": ["Sam Hooper", "Jen Johnston", "Alex", "Sara", "Jack", "Rachel", "Judy", "Other"]]
    }
    
    //MARK: - Layout
    override func viewDidLoad() {
        
        /*let startingBackGroundView = UIImageView(image: UIImage(named: "viewControllerBackground"))
        startingBackGroundView.frame = self.view.frame
        startingBackGroundView.contentMode = .scaleAspectFill
        self.view.addSubview(startingBackGroundView)
        
        let backgroundImageView = UIImageView(image: UIImage(named: "viewControllerBackgroundBlurred"))
        backgroundImageView.frame = self.view.frame
        backgroundImageView.contentMode = .scaleAspectFill
        let translucentView = UIView(frame: self.view.frame)
        translucentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        let backgroundView = UIView(frame: self.view.frame)
        backgroundView.addSubview(translucentView)
        backgroundView.addSubview(backgroundImageView)
        backgroundView.sendSubview(toBack: backgroundImageView)
        backgroundView.tag = -1
        
        UIView.animate(withDuration: 2, animations: {self.view.addSubview(backgroundView)}, completion: {(finished: Bool) in self.view.sendSubview(toBack: backgroundView)})
        //self.view.addSubview(backgroundView)
        //self.view.sendSubview(toBack: backgroundView)
        startingBackGroundView.removeFromSuperview()*/
        
        
        
        super.viewDidLoad()
        
        // The user is opening the app again after closing it or returning from another scene
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
        
        
            // The user has opened the app for the first time since data were cleared
        else {
            // date defaults to today
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            self.textFields[1]?.text = formatter.string(from: now)
            
            // Disable navigation to vehicle list until all fields are filled
            self.viewVehiclesButton.isEnabled = false
        }
        
    }
    
    
    /*override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        for (i, view) in self.view.subviews.enumerated() {
            if view.tag == -1 {
                self.view.subviews[i].subviews[0].frame = UIScreen.main.bounds
                self.view.subviews[i].subviews[1].frame = UIScreen.main.bounds
            }
        }
    }*/
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - TabBarControllerDelegate methods
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("Selected \(type(of: viewController))")
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
        
        let vehicleTableViewContoller = BaseTableViewController()//BusTableViewController()//
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
            } else {
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
    
    //MARK: Private methods
    private func loadSession() -> Session? {
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
        return self.session
    }

}
