//
//  BaseTableViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 6/3/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import SQLite


class BaseTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var tableView: UITableView!
    private var navigationBar: CustomNavigationBar!
    private var backButton: UIBarButtonItem!
    
    //MARK: Properties
    var observations = [Observation]()
    var session: Session?
    @IBOutlet weak var addNewObservation: UIBarButtonItem!
    
    var db: Connection!// SQLiteDatabase!
    
    // observation DB properties
    let idColumn = Expression<Int64>("id")
    let observerNameColumn = Expression<String>("observerName")
    let dateColumn = Expression<String>("date")
    let timeColumn = Expression<String>("time")
    let driverNameColumn = Expression<String>("driverName")
    let destinationColumn = Expression<String>("destination")
    let nPassengersColumn = Expression<String>("nPassengers")
    let commentsColumn = Expression<String>("comments")
    
    // session DB properties
    let sessionsTable = Table("sessions")
    let openTimeColumn = Expression<String>("openTime")
    let closeTimeColumn = Expression<String>("closeTime")
    
    let observationsTable = Table("observations")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNavigationBar()
        
        // get width and height of View
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let navigationBarHeight: CGFloat = self.navigationBar.frame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        
        tableView = UITableView(frame: CGRect(x: 0, y: barHeight + navigationBarHeight, width: displayWidth, height: displayHeight - (barHeight+navigationBarHeight)))
        tableView.register(BaseObservationTableViewCell.self, forCellReuseIdentifier: "cell")         // register cell name
        //Auto-set the UITableViewCells height (requires iOS8+)
        tableView.rowHeight = 90//UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 90
        tableView.dataSource = self
        tableView.delegate = self
        self.view.addSubview(tableView)
        
        // Open connection to the DB
        do {
            db = try Connection(dbPath)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        // Load the session. This is stored as a file using NSCoding.
        //self.session = loadSession()
        
        do {
            print("trying to load observations")
            try loadSession()
            if let savedObservations = try loadObservations(){
                observations += savedObservations
            } else {
                // Change this method here so sample obs are only loaded the first time
                //loadSampleObservations()
            }
        } catch let error{
            fatalError(error.localizedDescription)
        }
        

        

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //MARK: Navigation
    func setNavigationBar() {
        let screenSize: CGRect = UIScreen.main.bounds
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        self.navigationBar = CustomNavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: screenSize.width, height: 44))
        
        let navItem = UINavigationItem(title: "Vehicle List")
        let backButton = UIBarButtonItem(barButtonSystemItem: .rewind, target: nil, action: #selector(moveToSessionForm))//UIBarButtonItem(title: "Save", style: .plain, target: nil, action: #selector(save))
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: #selector(moveToNewObseverationMenu))
        navItem.leftBarButtonItem = backButton
        navItem.rightBarButtonItem = addButton
        self.navigationBar.setItems([navItem], animated: false)
        
        self.view.addSubview(self.navigationBar)
    }
    
    @objc func moveToSessionForm(){
        // Prep the view controller
        let sessionController = SessionViewController()
        sessionController.session = self.session
        print("moving back to session")
        
        //present(sessionController, animated: true, completion: nil)
        self.dismiss(animated: true, completion: nil)
        //self.navigationController?.popViewController(animated: true)
    }
    
    @objc func moveToNewObseverationMenu(){
        let menuController = AddObservationViewController()
        present(menuController, animated: true, completion: nil)
    }
    
    
    //MARK: TableView methods
    // return the number of sections
    func numberOfSections(in tableView: UITableView) -> Int{
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return observations.count
    }
    
    
    // called when the cell is selected.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected: \(indexPath.row)")
    }
    

    // Compose each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! BaseObservationTableViewCell
        //let cellIdentifier = "cell"
        
        /*guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ObservationTableViewCell else {
            fatalError("The dequeued cell is not an instance of ObservationTableViewCell.")
        }*/
        
        // Fetches the appropriate meal for the data source layout.
        let observation = observations[indexPath.row]
        
        
        cell.driverLabel.text = observation.driverName
        cell.destinationLabel.text = observation.destination
        cell.datetimeLabel.text = "\(observation.date) \(observation.time)"

        return cell
    }
    
    // Editing
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let id = observations[indexPath.row].id
            print("Deleting \(id)")
            observations.remove(at: indexPath.row)
            let recordToRemove = observationsTable.where(idColumn == id.datatypeValue)
            do {
                try db.run(recordToRemove.delete())
            } catch let error{
                print(error.localizedDescription)
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    //MARK: Private Methods
    private func loadObservations() throws -> [Observation]?{
        // ************* check that the table exists first **********************
        let rows = Array(try db.prepare(observationsTable))
        var loadedObservations = [Observation]()
        for row in rows{
            //let session = Session(observerName: row[observerNameColumn], openTime: " ", closeTime: " ", givenDate: row[dateColumn])
            let observation = Observation(id: Int(row[idColumn]), observerName: row[observerNameColumn], date: row[dateColumn], time: row[timeColumn], driverName: row[driverNameColumn], destination: row[destinationColumn], nPassengers: row[nPassengersColumn], comments: row[commentsColumn])
            loadedObservations.append(observation!)
        }
        
        print("loaded all observations")
        return loadedObservations
        
    }
    
    private func loadSession() throws { //}-> Session?{
        // ************* check that the table exists first **********************
        let rows = Array(try db.prepare(sessionsTable))
        if rows.count > 1 {
            fatalError("Multiple sessions found")
        }
        for row in rows{
            self.session = Session(id: Int(row[idColumn]), observerName: row[observerNameColumn], openTime:row[openTimeColumn], closeTime: row[closeTimeColumn], givenDate: row[dateColumn])
        }
        print("loaded all session")
    }
    
}
