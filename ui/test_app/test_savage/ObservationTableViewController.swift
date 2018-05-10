//
//  ObservationTableViewController.swift
//  test_savage
//
//  Created by Sam Hooper on 5/8/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import os.log

class ObservationTableViewController: UITableViewController {
    
    //MARK: Proporties
    var observations = [Observation]()
    
    //MARK: Actions
    @IBAction func unwindToObservationList(sender: UIStoryboardSegue) {
        
        if let sourceViewController = sender.source as? ObservationViewController, let observation  = sourceViewController.observation{
            
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing observation
                observations[selectedIndexPath.row] = observation
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                //Add a new observation
                let newIndexPath = IndexPath(row: observations.count, section:0)
                observations.append(observation)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            
            // Save observations
            saveObservations()
        }
    }
    
    //MARK: Private methods
    private func loadSampleObservations(){
        let image1 = UIImage(named: "observation1")
        let image2 = UIImage(named: "observation2")
        let image3 = UIImage(named: "Observation3")
        
        guard let observation1 = Observation(name: "Bus", image: image1, rating: 4) else {
            fatalError("Unable to instatiate obersvation1")
        }
        guard let observation2 = Observation(name: "Right of way", image: image2, rating: 5) else {
            fatalError("Unable to instatiate obersvation2")
        }
        guard let observation3 = Observation(name: "NPS Approved", image: image3, rating: 3) else {
            fatalError("Unable to instatiate obersvation3")
        }
        
        observations += [observation1, observation2, observation3]
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button item provided by the table view controller
        navigationItem.leftBarButtonItem = editButtonItem
        
        //  Load any saved observations if there are any, otherwise load the sample data
        if let savedObservations = loadObservations() {
            observations += savedObservations
        } else {
            //Load the sample data
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
        
        // Table view cells are reused and should be dequeued using a cell identifier
        let cellIdentifier = "ObservationTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ObservationTableViewCell else {
            fatalError("The deququed cell is not an instance of ObservationTableViewCell")
        }
        
        // Get the appropriate observation for this cell
        let observation = observations[indexPath.row]
        
        cell.observationLabel.text = observation.name
        cell.photoImageView.image = observation.image
        cell.ratingControl.rating = observation.rating
        
        return cell
    }
    

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }


    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            observations.remove(at: indexPath.row)
            saveObservations() // Save changes
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

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "AddItem":
            os_log("Adding a new meal", log: OSLog.default, type: .debug)
        case "ShowDetail":
            guard let observationDetailViewController = segue.destination as? ObservationViewController else {
                fatalError("Unexpected destination: \(String(describing: sender))")
            }
            guard let selectedObservationCell = sender as? ObservationTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            guard let indexPath = tableView.indexPath(for: selectedObservationCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedObservation = observations[indexPath.row]
            observationDetailViewController.observation = selectedObservation
        default:
            fatalError("Unexpected Segue Identifier: \(String(describing: segue.identifier))")
        }
        
    }
    
    //MARK: Private methods
    private func saveObservations() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(observations, toFile: Observation.ArchiveURL.path)
        
        if isSuccessfulSave {
            os_log("Observations successfully saved", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save observations...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadObservations() -> [Observation]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Observation.ArchiveURL.path) as? [Observation]
    }

}
