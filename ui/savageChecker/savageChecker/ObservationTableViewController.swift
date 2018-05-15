//
//  ObservationTableViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit

class ObservationTableViewController: UITableViewController {
    
    //MARK: Properties
    var observations = [Observation]()
    var session: Session?
    var sessionController: SessionViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.session = Session(observerName: "Hooper", openTime: "7:00 AM", closeTime: "7:00 PM", givenDate: "May 14 2018")
        loadSampleObservations()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
            // Add new observation
            let newIndexPath = IndexPath(row: observations.count, section: 0)
            observations.append(observation)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    //MARK: Private Methods
    
    private func loadSampleObservations() {
        let session = Session(observerName: "Joe", openTime: "7:00 AM", closeTime: "7:00 PM", givenDate: "May 14 2017")
        guard let obs1 = Observation(session: session!, time: "12:00 PM", driverName: "Hooper", destination: "Eielson") else {
            fatalError("Unable to instantiate obs1")
        }
        guard let obs2 = Observation(session: session!, time: "12:30 PM", driverName: "Johnston", destination: "Eielson") else {
            fatalError("Unable to instantiate obs1")
        }
        
        observations += [obs1, obs2]
    }

}
