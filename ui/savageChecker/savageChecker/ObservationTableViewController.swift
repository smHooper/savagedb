//
//  ObservationTableViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import SQLite3
import SQLite
import os.log

class ObservationTableViewController: UITableViewController {
    
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
        
        // Open connection to the DB
        do {
            db = try Connection(dbPath)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
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
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return observations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "ObservationTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ObservationTableViewCell else {
            fatalError("The dequeued cell is not an instance of ObservationTableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        let observation = observations[indexPath.row]
        
        
        cell.driverLabel.text = observation.driverName
        cell.destinationLabel.text = observation.destination
        cell.datetimeLabel.text = "\(observation.date) \(observation.time)"
        
        return cell
    }
    
    
    //MARK: Actions
    @IBAction func unwindToObservationList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? ObservationViewController, let observation = sourceViewController.observation{
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing observation
                observations[selectedIndexPath.row] = observation
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                // Add new observation
                let newIndexPath = IndexPath(row: observations.count, section: 0)
                observations.append(observation)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            // Save observations
            //saveObservations()
        }
    }
    
    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showVehicleTable"{
            guard let sourceViewController = segue.source as? SessionViewController else {
                os_log("The destination controller isn't a SessionViewController", log: OSLog.default, type: .debug)
                return
            }
            
            self.session = sourceViewController.session
        }
        print(segue.identifier ?? "couldn't unwrap")
    }*/
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation
    
    // Prep observation view with info from session
    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? ""){
        
        
        case "addObservation": // This should never be true
            guard let observationViewController = segue.destination.childViewControllers.first! as? ObservationViewController else {
                fatalError("Unexpected sender: \(segue.destination.childViewControllers)")
            }
            
            observationViewController.observation = Observation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: "", driverName: "", destination: "", nPassengers: "")
            
            // Let the view controller know to insert a new row in the DB
            observationViewController.isAddingNewObservation = true
            os_log("Adding new vehicle obs", log: OSLog.default, type: .debug)
        
        case "showObservationDetail":
            guard let observationViewController = segue.destination as? ObservationViewController else {
                fatalError("Unexpected sender: \(segue.destination)")
            }
            guard let selectedObservationCell = sender as? ObservationTableViewCell else {
                fatalError("Unexpected sener: \(sender!)")
            }
            guard let indexPath = tableView.indexPath(for: selectedObservationCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedObservation = observations[indexPath.row]
            observationViewController.observation = selectedObservation
            // Let the view controller know to update an existing row in the DB
            observationViewController.isAddingNewObservation = false
        default:
            fatalError("Unexpeced Segue Identifier: \(segue.identifier!)")
        }
        
    }*/
    
    
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
    /*private func loadSession() -> Session? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Session.ArchiveURL.path) as? Session
    }*/

}
