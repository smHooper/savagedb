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
    
    //MARK: - Properties
    //MARK: General
    var tableView: UITableView!
    private var navigationBar: CustomNavigationBar!
    private var backButton: UIBarButtonItem!
    private var editBarButton: UIBarButtonItem!
    var presentTransition: UIViewControllerAnimatedTransitioning?
    var dismissTransition: UIViewControllerAnimatedTransitioning?
    var dismiss = false
    var blurEffectView: UIVisualEffectView!
    var isEditingTable = false // Need to track whether the table is editing because tableView.isEditing resets to false as soon as edit button is pressed
    
    //MARK: db properties
    var observations = [Observation]()
    var session: Session?
    var db: Connection!
    
    //MARK: observation DB properties
    let idColumn = Expression<Int64>("id")
    let observerNameColumn = Expression<String>("observerName")
    let dateColumn = Expression<String>("date")
    let timeColumn = Expression<String>("time")
    let driverNameColumn = Expression<String>("driverName")
    let destinationColumn = Expression<String>("destination")
    let nPassengersColumn = Expression<String>("nPassengers")
    let commentsColumn = Expression<String>("comments")
    
    let observationsTable = Table("observations")
    
    //MARK: session DB properties
    let sessionsTable = Table("sessions")
    let openTimeColumn = Expression<String>("openTime")
    let closeTimeColumn = Expression<String>("closeTime")
    
    
    
    
    //MARK: - Layout
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
        
        self.presentTransition = RightToLeftTransition()
        self.dismissTransition = LeftToRightTransition()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //MARK: - Navigation
    func setNavigationBar() {
        let screenSize: CGRect = UIScreen.main.bounds
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        self.navigationBar = CustomNavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: screenSize.width, height: 44))
        
        let navItem = UINavigationItem(title: "Vehicles")
        //let backButton = UIBarButtonItem(title: "\u{2039}", style:.plain, target: nil, action: #selector(backButtonPressed))
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage (named: "backButton"), for: .normal)
        //backButton.setTitle("Shift info", for: .normal)
        backButton.frame = CGRect(x: 0.0, y: 0.0, width: 35.0, height: 35.0)
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        let backBarButton = UIBarButtonItem(customView: backButton)
        
        let editButton = UIButton(type: .custom)
        //self.editBarButton = UIBarButtonItem(image: UIImage(named: "deleteIcon"), style: .plain, target: self, action: #selector(handleEditing(sender:)))
        self.editBarButton = self.editButtonItem
        self.editButtonItem.action = #selector(handleEditing(sender:))
        //print("Edit button frame: \((self.editBarButton.customView?.frame)!)")
        
        
        let addObservationButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: #selector(addButtonPressed))
        navItem.leftBarButtonItem = backBarButton
        navItem.rightBarButtonItems = [addObservationButton, self.editBarButton]
        self.navigationBar.setItems([navItem], animated: false)
        
        self.view.addSubview(self.navigationBar)
    }
    
    @objc func handleEditing(sender: UIBarButtonItem) {
        
        self.tableView.setEditing(self.isEditing, animated: true)
        if !self.isEditingTable {
            self.tableView.isEditing = true
            self.isEditingTable = true
            sender.title = "Done"
            sender.style = .done
            // **** Add alert that deletes are permanent *******
            //self.editBarButton.image = UIImage(named: "blueCheck")
            
        } else {
            self.tableView.isEditing = false
            self.isEditingTable = false
            sender.title = "Edit"
            sender.style = .plain
            //self.editBarButton.image = UIImage(named: "deleteIcon")
            
            /*let buttonView = UIImageView(image: UIImage(named: "deleteIcon"))
            buttonView.frame = (self.editBarButton.customView?.frame)!
            buttonView.contentMode = .scaleAspectFit
            self.editBarButton.customView = buttonView*/
        }
    }
    
    
    @objc func backButtonPressed(){
        /*let sessionController = SessionViewController()
        sessionController.modalPresentationStyle = .custom
        sessionController.transitioningDelegate = self
        self.dismiss = false
        let currentTag = self.view.tag
        self.view.tag = -1 //Set this so
        present(sessionController, animated: true, completion: {[weak self] in self?.view.tag = currentTag})*/
        print("back button pressed")
        self.dismissTransition = LeftToRightTransition()
        dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
    }
    
    @objc func addButtonPressed(){
        //only apply the blur if the user hasn't disabled transparency effects
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            view.backgroundColor = .clear
            
            let blurEffect = UIBlurEffect(style: .regular)
            self.blurEffectView = UIVisualEffectView(effect: blurEffect)
            
            //always fill the view
            self.blurEffectView.frame = self.view.bounds
            self.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            view.addSubview(self.blurEffectView) //if you have more UIViews, use an insertSubview API to place it where needed
        } else {
            // ************ Might need to make a dummy blur effect so that removeFromSuperview() in AddObservationMenu transition doesn't choke
            view.backgroundColor = .black
        }
        let menuController = AddObservationViewController()
        menuController.modalPresentationStyle = .overCurrentContext
        menuController.modalTransitionStyle = .coverVertical
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
        
        let observationViewController = BaseObservationViewController()
        observationViewController.observation = observations[indexPath.row]
        observationViewController.isAddingNewObservation = false
        
        observationViewController.modalPresentationStyle = .custom
        observationViewController.transitioningDelegate = self
        
        // Set the transition. When done transitioning, reset presentTransition to nil
        self.presentTransition = RightToLeftTransition()
        present(observationViewController, animated: true, completion: {[weak self] in self?.presentTransition = nil})
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
    func loadObservations() -> [Observation]?{
        // ************* check that the table exists first **********************
        let rows: [Row]
        do {
            rows = try Array(try db.prepare(observationsTable))
        } catch {
            fatalError("Could not load observations: \(error.localizedDescription)")
        }
        var loadedObservations = [Observation]()
        for row in rows{
            //let session = Session(observerName: row[observerNameColumn], openTime: " ", closeTime: " ", givenDate: row[dateColumn])
            let observation = Observation(id: Int(row[idColumn]), observerName: row[observerNameColumn], date: row[dateColumn], time: row[timeColumn], driverName: row[driverNameColumn], destination: row[destinationColumn], nPassengers: row[nPassengersColumn], comments: row[commentsColumn])
            loadedObservations.append(observation!)
        }
        
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
    }
    
}
