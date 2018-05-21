//
//  ObservationTableViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import os.log

class ObservationTableViewController: UITableViewController {
    
    //MARK: Properties
    var observations = [Observation]()
    var session: Session?
    //var sessionController: SessionViewController?
    @IBOutlet weak var addNewObservation: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        // Load the session
        self.session = loadSession()
        print("Session observer from ObsTableView.veiwDidLoad(): \(session?.observerName)")
        
        if let savedObservations = loadObservations(){//savedObservations.count != 0 {
            observations += savedObservations
        } else {
            // Change this method here so sample obs are only loaded the first time
            loadSampleObservations()
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
            saveObservations()
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
            observations.remove(at: indexPath.row)
            saveObservations()
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? ""){
        
        case "addObservation":
            guard let observationViewController = segue.destination.childViewControllers.first! as? ObservationViewController else {
                fatalError("Unexpected sender: \(segue.destination.childViewControllers)")
            }
            
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let time = formatter.string(from: now)
            observationViewController.observation = Observation(session: session!, time: time, driverName: "", destination: "")
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
        default:
            fatalError("Unexpeced Segue Identifier: \(segue.identifier!)")
        }
        
    }
    
    
    //MARK: Private Methods
    private func loadSampleObservations() {
        let session = self.session!//Session(observerName: "Joe", openTime: "7:00 AM", closeTime: "7:00 PM", givenDate: "May 14 2017")
        print(session.date)
        guard let obs1 = Observation(session: session, time: "12:00 PM", driverName: "Hooper", destination: "Eielson") else {
            fatalError("Unable to instantiate obs1")
        }
        guard let obs2 = Observation(session: session, time: "12:30 PM", driverName: "Johnston", destination: "Eielson") else {
            fatalError("Unable to instantiate obs1")
        }
        
        observations += [obs1, obs2]
    }
    
    private func saveObservations() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(observations, toFile: Observation.ArchiveURL.path)
        
        if isSuccessfulSave {
            os_log("Observations successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save observations...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadObservations() -> [Observation]?{
        return NSKeyedUnarchiver.unarchiveObject(withFile: Observation.ArchiveURL.path) as? [Observation]
    }
    
    private func loadSession() -> Session? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Session.ArchiveURL.path) as? Session
    }

}
