//
//  AddObservationViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/29/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import os.log
import SQLite

class AddObservationViewController: UIViewController {
    
    let minSpacing = 50.0
    let menuPadding = 50.0
    var buttons = [VehicleButtonControl]()
    
    var icons: DictionaryLiteral = ["Bus": "busIcon",
                                    "NPS Vehicle": "busIcon",
                                    "NPS Approved": "busIcon",
                                    "NPS Contractor": "busIcon",
                                    "Employee": "busIcon",
                                    "Right of Way": "busIcon",
                                    "Tek Camper": "busIcon",
                                    "Bicycle": "busIcon",
                                    "Propho": "busIcon",
                                    "Accessibility": "busIcon",
                                    "Hunting": "busIcon",
                                    "Road lottery": "busIcon",
                                    "Other": "busIcon"]//*/
    
    /*let icons = [
        (labelText: "JV Bus", iconName: "busIcon", function: "a"),
        (labelText: "Lodge Bus", iconName: "busIcon", function: "a"),
        (labelText: "NPS Vehicle", iconName: "busIcon", function: "a"),
        (labelText: "NPS Approved", iconName: "busIcon", function: "a"),
        (labelText: "NPS Contractor", iconName: "busIcon", function: "a"),
        (labelText: "Employee", iconName: "busIcon", function: "a"),
        (labelText: "Right of Way", iconName: "busIcon", function: "a"),
        (labelText: "Tek Camper", iconName: "busIcon", function: "a"),
        (labelText: "Bicycle", iconName: "busIcon", function: "a"),
        (labelText: "Propho", iconName: "busIcon", function: "a"),
        (labelText: "Accessibility", iconName: "busIcon", function: "a"),
        (labelText: "Hunting", iconName: "busIcon", function: "a"),
        (labelText: "Road lottery", iconName: "busIcon", function: "a"),
        (labelText: "Other", iconName: "busIcon", function: "a")
    ]*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add make buttons to arrange
        for (offset: index, (key: labelText, value: iconName)) in self.icons.enumerated() {
            let thisButton = VehicleButtonControl()
            thisButton.setupButtonLayout(imageName: iconName, labelText: labelText)
            thisButton.tag = index
            thisButton.button.addTarget(self, action: #selector(AddObservationViewController.moveToObservationViewController(button:)), for: .touchUpInside)
            buttons.append(thisButton)
        }
        
        // Arrange them
        setupMenuLayout()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Redo the layout when rotated
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupMenuLayout()
        self.view.backgroundColor = UIColor.white
    }
    
    
    //MARK: Private methods
    private func setupMenuLayout(){
        
        // Figure out how many buttons fit in one row
        let viewWidth = self.view.frame.width
        let menuWidth = Double(viewWidth) - menuPadding * 2
        let nPerRow = floor((menuWidth + self.minSpacing) / (VehicleButtonControl.width + self.minSpacing))
        let nRows = Int(ceil(Double(buttons.count) / nPerRow))
        //let menuWidth = nRows * VehicleButtonControl.width + ((nRows - 1) * self.minSpacing)
        
        // Figure out if there are too many rows to fit in the window. If so, put all of the buttons in a scrollview
        let viewHeight = self.view.frame.height
        let menuHeight = Double(viewHeight) - menuPadding * 2//nRows * (VehicleButtonControl.height + self.minSpacing) + self.minSpacing
        if Double(viewHeight) < menuHeight {
            // Put it in a scrollview
        }
        
        // Set up the container
        let container = UIView()
        self.view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        container.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        container.widthAnchor.constraint(equalToConstant: CGFloat(menuWidth)).isActive = true
        container.heightAnchor.constraint(equalToConstant:CGFloat(menuHeight)).isActive = true
        
        // Loop through each row, making a horizontal stack view for each
        var lastBottomAnchor = container.topAnchor
        let menuLeftAnchor = container.leftAnchor
        let menuRightAnchor = container.rightAnchor
        for rowIndex in 0..<nRows {
            let stack = UIStackView()
            let startIndex = rowIndex * Int(nPerRow)
            let endIndex = min(startIndex + Int(nPerRow), self.buttons.count)
            let theseButtons = self.buttons[startIndex ..< endIndex]
            for button in theseButtons {
                stack.addArrangedSubview(button)
            }
            // Lay out the stackview
            stack.spacing = CGFloat(self.minSpacing)
            stack.axis = .horizontal
            stack.alignment = .fill
            stack.distribution = .fillEqually
            container.addSubview(stack)
            
            // Set up constraints for the stack view
            stack.translatesAutoresizingMaskIntoConstraints = false
            if rowIndex == 0 {
                stack.topAnchor.constraint(equalTo: lastBottomAnchor).isActive = true
            } else {
                stack.topAnchor.constraint(lessThanOrEqualTo: lastBottomAnchor, constant: CGFloat(self.minSpacing)).isActive = true
            }
            // Figure out how to handle when the (last) row is not full
            stack.leftAnchor.constraint(equalTo: menuLeftAnchor).isActive = true
            stack.rightAnchor.constraint(equalTo: menuRightAnchor).isActive = true
            lastBottomAnchor = stack.bottomAnchor
        }
    }

    
    // MARK: - Navigation
    
    @objc func moveToObservationViewController(button: UIButton){
        let session = loadSession()
        let labelText = icons[button.tag].key
        switch (labelText){
        case "Bus":
                let viewController = BaseObservationViewController()
                viewController.isAddingNewObservation = true
                viewController.observation = Observation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: "", driverName: "", destination: "", nPassengers: "")
                present(viewController, animated: true, completion: nil)
        default:
            fatalError("Didn't understand which controller to move to")
            }
        }
    
    // Prep observation view with info from session
    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? ""){
            
        case "addObservation":
            guard let observationViewController = segue.destination.childViewControllers.first! as? ObservationViewController else {
                fatalError("Unexpected sender: \(segue.destination.childViewControllers)")
            }
            let session = loadSession()
            observationViewController.observation = Observation(id: -1, observerName: (session?.observerName)!, date: (session?.date)!, time: "", driverName: "", destination: "", nPassengers: "")
            
            // Let the view controller know to insert a new row in the DB
            observationViewController.isAddingNewObservation = true
            os_log("Adding new vehicle obs", log: OSLog.default, type: .debug)
            
        /*case "showObservationDetail":
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
             */
        default:
            fatalError("Unexpeced Segue Identifier: \(segue.identifier!)")
        }
        
    }*/
    
    // MARK: Private methods
    private func loadSession() -> Session? {
        // ************* check that the table exists first **********************
        var rows = [Row]()
        let db: Connection!
        let sessionsTable = Table("sessions")
        let idColumn = Expression<Int64>("id")
        let observerNameColumn = Expression<String>("observerName")
        let dateColumn = Expression<String>("date")
        let openTimeColumn = Expression<String>("openTime")
        let closeTimeColumn = Expression<String>("closeTime")
        do {
            db = try Connection(dbPath)
            rows = Array(try db.prepare(sessionsTable))
        } catch {
            fatalError(error.localizedDescription)
        }
        if rows.count > 1 {
            fatalError("Multiple sessions found")
        }
        var session: Session?
        for row in rows{
            session = Session(id: Int(row[idColumn]), observerName: row[observerNameColumn], openTime:row[openTimeColumn], closeTime: row[closeTimeColumn], givenDate: row[dateColumn])
        }
        print("loaded all session. Observername: \(session?.observerName)")
        return session
    }

}



