//
//  BaseTableViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 6/3/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//
import UIKit
import SQLite
import os.log
import GoogleSignIn

class BaseTableViewController: UITabBarController, UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate, GIDSignInUIDelegate {//UITabBarDelegate {
    
    //MARK: - Properties
    //MARK: General
    var tableView: UITableView!
    private var navigationBar: CustomNavigationBar!
    private let navigationButtonSize: CGFloat = 30
    private var backButton: UIBarButtonItem!
    private var editBarButton: UIBarButtonItem!
    //private var tabBar: UITabBar!
    var presentTransition: UIViewControllerAnimatedTransitioning?
    var dismissTransition: UIViewControllerAnimatedTransitioning?
    var dismiss = false
    //var blurEffectView: UIVisualEffectView!
    var isEditingTable = false // Need to track whether the table is editing because tableView.isEditing resets to false as soon as edit button is pressed
    let documentInteractionController = UIDocumentInteractionController()
    var currentScreenFrame = UIScreen.main.bounds // Annoyingly, when 'requires full screen' is checked, the screen size doesn't update until after willTransitionTo() is called. So I'll have to calculate it manually
    
    
    let icons = ["Bus": (normal: "busIcon", selected: "shuttleBusImg", tableName: "buses", dataClassName: "BusObservation"),
                 "Lodge Bus": (normal: "lodgeBusIcon", selected: "shuttleBusImg", tableName: "buses", dataClassName: "BusObservation"),
                 "NPS Vehicle": (normal: "npsVehicleIcon", selected: "shuttleBusImg", tableName: "nps_vehicles", dataClassName: "NPSVehicleObservation"),
                 "NPS Approved": (normal: "npsApprovedIcon", selected: "shuttleBusImg", tableName: "nps_approved", dataClassName: "NPSApprovedObservation"),
                 "NPS Contractor": (normal: "npsContractorIcon", selected: "shuttleBusImg", tableName: "nps_contractors", dataClassName: "NPSContractorObservation"),
                 "Employee": (normal: "employeeIcon", selected: "shuttleBusImg", tableName: "employee_vehicles", dataClassName: "EmployeeObservation"),
                 "Right of Way": (normal: "rightOfWayIcon", selected: "shuttleBusImg", tableName: "inholders", dataClassName: "RightOfWayObservation"),
                 "Tek Camper": (normal: "tekCamperIcon", selected: "shuttleBusImg", tableName: "tek_campers", dataClassName: "TeklanikaCamperObservation"),
                 "Bicycle": (normal: "cyclistIcon", selected: "shuttleBusImg", tableName: "cyclists", dataClassName: "Observation"),
                 "Photographer": (normal: "photographerIcon", selected: "shuttleBusImg", tableName: "photographers", dataClassName: "PhotographerObservation"),
                 "Accessibility": (normal: "accessibilityIcon", selected: "shuttleBusImg", tableName: "accessibility", dataClassName: "AccessibilityObservation"),
                 "Subsistence": (normal: "subsistenceIcon", selected: "shuttleBusImg", tableName: "subsistence", dataClassName: "Observation"),
                 "Road Lottery": (normal: "roadLotteryIcon", selected: "shuttleBusImg", tableName: "road_lottery", dataClassName: "Observation"),
                 "Other": (normal: "otherIcon", selected: "shuttleBusImg", tableName: "other_vehicles", dataClassName: "Observation")]
    
    //MARK: ToolBar properties
    let toolBar = UIToolbar()
    
    let barButtonIcons = [(label: "All", normal: "allTableIcon", selected: "shuttleBusImg", tableName: "buses", dataClassName: "BusObservation"),
                          (label: "Bus", normal: "busIcon", selected: "shuttleBusImg", tableName: "buses", dataClassName: "BusObservation"),
                          (label: "Lodge Bus", normal: "lodgeBusIcon", selected: "shuttleBusImg", tableName: "buses", dataClassName: "BusObservation"),
                          (label: "NPS Vehicle", normal: "npsVehicleIcon", selected: "shuttleBusImg", tableName: "nps_vehicles", dataClassName: "NPSVehicleObservation"),
                          (label: "NPS Approved", normal: "npsApprovedIcon", selected: "shuttleBusImg", tableName: "nps_approved", dataClassName: "NPSApprovedObservation"),
                          (label: "NPS Contractor", normal: "npsContractorIcon", selected: "shuttleBusImg", tableName: "nps_contractors", dataClassName: "NPSContractorObservation"),
                          (label: "Employee", normal: "employeeIcon", selected: "shuttleBusImg", tableName: "employee_vehicles", dataClassName: "EmployeeObservation"),
                          (label: "Right of Way", normal: "rightOfWayIcon", selected: "shuttleBusImg", tableName: "inholders", dataClassName: "RightOfWayObservation"),
                          (label: "Tek Camper", normal: "tekCamperIcon", selected: "shuttleBusImg", tableName: "tek_campers", dataClassName: "TeklanikaCamperObservation"),
                          (label: "Bicycle", normal: "cyclistIcon", selected: "shuttleBusImg", tableName: "cyclists", dataClassName: "Observation"),
                          (label: "Photographer", normal: "photographerIcon", selected: "shuttleBusImg", tableName: "photographers", dataClassName: "PhotographerObservation"),
                          (label: "Accessibility", normal: "accessibilityIcon", selected: "shuttleBusImg", tableName: "accessibility", dataClassName: "AccessibilityObservation"),
                          (label: "Subsistence", normal: "subsistenceIcon", selected: "shuttleBusImg", tableName: "subsistence", dataClassName: "Observation"),
                          (label: "Road Lottery", normal: "roadLotteryIcon", selected: "shuttleBusImg", tableName: "road_lottery", dataClassName: "Observation"),
                          (label: "Other", normal: "otherIcon", selected: "shuttleBusImg", tableName: "other_vehicles", dataClassName: "Observation")]
    
    let barButtonSize: CGFloat = 65
    let barButtonWidth: CGFloat = 150
    let barHeight: CGFloat = 140
    var nBarGroups = 1
    var currentBarGroup = 0
    var barButtons = [UIBarButtonItem]()
    var selectedToolBarButton = 0
    var leftToolBarButton = UIBarButtonItem()
    var rightToolBarButton = UIBarButtonItem()
    var barGroupIndicators = [UIImageView]()
    //var observationIcons = [String: String]() // For storing icon IDs asociated with each
    
    //MARK: properties for ordering and displaying cells
    struct ObservationCell {
        let observationType: String
        let iconName: String
        let observation: Observation
        let label2: String
        let label3: String
    }
    var observationCells = [Int: ObservationCell]()
    var cellOrder = [Int]()
    let cellLabelColumns = ["Bus":            (label2: "bus_type",         label3: "destination"), //Each label is the column name in the DB the label is derived from and the icon name (with "Icon" at the end)
                            "Lodge Bus":      (label2: "bus_type",         label3: "bus_number"),
                            "NPS Vehicle":    (label2: "driver_name",      label3: "work_group"),
                            "NPS Approved":   (label2: "approved_type",    label3: "destination"),
                            "NPS Contractor": (label2: "destination",     label3: "organization"),
                            "Employee":       (label2: "driver_name",      label3: "n_passengers"),
                            "Right of Way":   (label2: "driver_name",      label3: "n_passengers"),
                            "Tek Camper":     (label2: "n_passengers",     label3: ""),
                            "Bicycle":        (label2: "destination",     label3: "n_passengers"),
                            "Photographer":   (label2: "driver_name",      label3: "n_nights"),
                            "Accessibility":  (label2: "driver_name",      label3: "destination"),
                            "Subsistence":    (label2: "driver_name",      label3: "n_passengers"),
                            "Road Lottery":   (label2: "permit_number",    label3: "n_passengers"),
                            "Other":          (label2: "destination",     label3: "n_passengers")]
    
    
    //MARK: db properties
    //var modelObjects = [Any]()
    private var observations = [Observation]()
    var session: Session?
    var db: Connection!
    
    //MARK: observation DB properties
    let idColumn = Expression<Int64>("id")
    let observerNameColumn = Expression<String>("observer_name")
    let dateColumn = Expression<String>("date")
    let timeColumn = Expression<String>("time")
    let driverNameColumn = Expression<String>("driver_name")
    let destinationColumn = Expression<String>("destination")
    let nPassengersColumn = Expression<String>("n_passengers")
    let commentsColumn = Expression<String>("comments")
    
    let observationsTable = Table("observations")
    
    //MARK: session DB properties
    let sessionsTable = Table("sessions")
    let openTimeColumn = Expression<String>("open_time")
    let closeTimeColumn = Expression<String>("close_time")
    

    //MARK: - Layout
    override func viewDidLoad() {
        super.viewDidLoad()
        addBackground()
        
        // Set up nav bar and tab bar
        self.title = "\(self.barButtonIcons[self.selectedToolBarButton].label) Observations"
        setNavigationBar()
        
        // get width and height of View
        let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let navigationBarHeight: CGFloat = self.navigationBar.frame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        
        self.tableView = UITableView(frame: CGRect(x: 0, y: statusBarHeight + navigationBarHeight, width: displayWidth, height: displayHeight - (statusBarHeight + navigationBarHeight + self.barHeight)))
        self.tableView.register(BaseObservationTableViewCell.self, forCellReuseIdentifier: "cell")         // register cell name
        //Auto-set the UITableViewCell's height (requires iOS8+)
        self.tableView.rowHeight = 85//UITableViewAutomaticDimension
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.view.addSubview(tableView)
        self.tableView.backgroundColor = UIColor.clear
        
        // Set up the toolbar for defining what the tableView shows
        // First, make the buttons
        for i in 0..<barButtonIcons.count {
            let button = makeBarButton(buttonTag: i)
            self.barButtons.append(UIBarButtonItem(customView: button))
        }
        // Add buttons for the currently selected group
        setupToolBarLayout()
        
        // Open connection to the DB
        do {
            db = try Connection(dbPath)
        } catch let error {
            os_log("Problem connecting to the database in ObservationTableViewController.viewDidLoad()", log: .default, type: .debug)
            showGenericAlert(message: "Problem connecting to the database at \(dbPath): \(error.localizedDescription)", title: "Database connection error")
        }
        
        self.presentTransition = RightToLeftTransition()
        self.dismissTransition = LeftToRightTransition()
        
        // Google sign-in
        GIDSignIn.sharedInstance().uiDelegate = self
        
        // Uncomment to automatically sign in the user.
        //GIDSignIn.sharedInstance().signInSilently()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Handle rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let navigationBarHeight: CGFloat = self.navigationBar.frame.size.height
        let screenSize = UIScreen.main.bounds // This is actually the screen size before rotation
        self.currentScreenFrame = {
            if UIDevice.current.orientation.isPortrait {
                return CGRect(x: 0, y: 0, width: min(screenSize.width, screenSize.height), height: max(screenSize.width, screenSize.height))
            } else {
                return CGRect(x: 0, y: 0, width: max(screenSize.width, screenSize.height), height: min(screenSize.width, screenSize.height))
            }
        }()
        
        self.tableView.frame = CGRect(x: 0, y: statusBarHeight + navigationBarHeight, width: self.currentScreenFrame.width, height: self.currentScreenFrame.height - (statusBarHeight + navigationBarHeight + self.barHeight))
        
        // Set up tool bar and nav bar. If the rotation happens while AddObs menu is open,
        //  the tool and nav bars will be placed overtop of the blurEffectView, so check to see if this is true first
        if self.getTopMostController() == self {
            setupToolBarLayout()
            setNavigationBar()
        }
        
        // Handle the background image
        for (i, view) in self.view.subviews.enumerated() {
            if view.tag == -1 {
                self.view.subviews[i].subviews[0].frame = UIScreen.main.bounds
                self.view.subviews[i].subviews[1].frame = UIScreen.main.bounds
            }
        }
        
        
    }
    
    func checkCurrentDb() -> Bool {
        // Helper function to verify that the data have not been deleted. If so, show an alert and reload the table
        if !currentDbExists() {
            showDbNotExistsAlert()
            self.observationCells.removeAll() // Make sure the table is blank so the user can't select an observation that doesn't exist
            self.tableView.reloadData()
            return false
        } else {
            return true
        }
    }
    
    // Convenience function to load all tableView data
    func loadData() {
        
        if !checkCurrentDb() { return }
        self.db = try? Connection(dbPath)
        
        if self.db != nil {
            try? loadSession()
            //self.observations = loadObservations()!
            loadObservations()
        } else{
            showGenericAlert(message: "Could not connect to the database at \(dbPath)", title: "Database connection error")
            os_log("could not connect to DB in tableViewController.loadData()", log: .default, type: .debug)
        }
        
        self.tableView.reloadData()//This probably gets called twicce in veiwDidLoad(), but data needs to be reloaded from form view controller when an observation is added or updated

        let range = NSMakeRange(0, self.tableView.numberOfSections)
        let sections = NSIndexSet(indexesIn: range)
        self.tableView.reloadSections(sections as IndexSet, with: .automatic)
        
        // Set scrollable area so you can scroll past toolBar*/
        self.tableView.contentSize.height += self.toolBar.frame.height
    }
    
    
    //MARK: - ToolBar setup
    // Arrange the tool bar for selecting the table display mode
    func setupToolBarLayout(){
        
        self.view.addSubview(self.toolBar)
        self.toolBar.translatesAutoresizingMaskIntoConstraints = false
        self.toolBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.toolBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.toolBar.topAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -self.barHeight).isActive = true
        self.toolBar.heightAnchor.constraint(equalToConstant: self.barHeight).isActive = true
        
        //figure out how many buttons per group
        let barWidth = self.currentScreenFrame.width - (self.barButtonSize * 2) // Make room for back/forward buttons plus space on either side
        let nButtonsPerGroup = floor(barWidth / self.barButtonWidth)
        self.nBarGroups = Int(ceil(CGFloat(self.barButtonIcons.count) / nButtonsPerGroup))
        
        // Adjust the currentBarGroup so that the one that's currently selected is always shown.
        //  Also, if this isn't adjusted when the device is rotated, the currentBarGroup could be > nBarGroups
        //  if going from portrait to landscape
        let previousBarWidth = self.view.frame.width - (self.barButtonSize * 2) // self.view.frame is not updated until after rotation, so this is the width before rotation
        let previousNButtonsPerGroup = floor(previousBarWidth / self.barButtonWidth)
        let previousCenterButtonIndex = floor(CGFloat(previousNButtonsPerGroup * CGFloat(self.currentBarGroup) + nButtonsPerGroup/2) - 1)
        self.currentBarGroup = Int(floor(previousCenterButtonIndex / nButtonsPerGroup))
        
        // Make the left and right buttons
        let leftButton = makeNextBarButton(tag: 0)
        let rightButton = makeNextBarButton(tag: 1)
        self.leftToolBarButton = UIBarButtonItem(customView: leftButton)
        self.rightToolBarButton = UIBarButtonItem(customView: rightButton)
        self.leftToolBarButton.isEnabled = false //Shouldn't be able go left before going right first
        
        // Add buttons to toolbar
        setToolBarButtons()
        
        // Enable/disable the next group buttons depending on self.currentGroup
        self.leftToolBarButton.isEnabled = self.currentBarGroup == 0 ? false : true // Showing first group
        self.rightToolBarButton.isEnabled = self.currentBarGroup == self.nBarGroups - 1 ? false : true // Showing last group
        
        // Draw group indicators
        addBarGroupIndicators()
        
        // Add swipe gesture recognizers
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeftOnToolBar))
        swipeLeftGesture.direction = .left
        swipeLeftGesture.cancelsTouchesInView = false
        self.toolBar.addGestureRecognizer(swipeLeftGesture)
        
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeRightOnToolBar))
        swipeRightGesture.direction = .right
        swipeRightGesture.cancelsTouchesInView = false
        self.toolBar.addGestureRecognizer(swipeRightGesture)
        
    }
    
    
    func setToolBarButtons() {
        
        let nButtonsPerGroup = self.barButtonIcons.count / self.nBarGroups + 1
        let leftButtonId = nButtonsPerGroup * self.currentBarGroup
        let rightButtonId = min(leftButtonId + nButtonsPerGroup, self.barButtonIcons.count) - 1
        let widthOfAllButtons = max(self.barButtonSize, self.barButtonWidth) * CGFloat(nButtonsPerGroup + 2)
        let fixedSpaceWidth = (self.currentScreenFrame.width - widthOfAllButtons) / CGFloat(nButtonsPerGroup + 1)
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: self, action: nil)
        fixedSpace.width = fixedSpaceWidth
        var barItems = [flexSpace, self.leftToolBarButton, flexSpace]//UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)]
        for i in leftButtonId..<rightButtonId {
            barItems += [self.barButtons[i], fixedSpace]//UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)] //self.barButtons[leftButtonId..<rightButtonId]
        }
        barItems += [self.barButtons[rightButtonId], flexSpace, self.rightToolBarButton, flexSpace]//[UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil), self.rightToolBarButton]
        self.toolBar.setItems(barItems, animated: true)
        
    }
    
    
    func addBarGroupIndicators() {
        // Clear all indicators so the transparent one isn't covered by an opaque one
        for i in 0..<self.barGroupIndicators.count {
            self.barGroupIndicators[i].removeFromSuperview()
        }
        self.barGroupIndicators.removeAll()
        
        let indicatorYSpacing: CGFloat = self.barHeight / 10
        let indicatorXSpacing = indicatorYSpacing * 2
        //let indicatorTop = self.toolBar.frame.minY + indicatorYSpacing
        let indicatorSize: CGFloat = 7
        let indicatorWidth = CGFloat(indicatorSize * CGFloat(self.nBarGroups)) + (indicatorXSpacing * CGFloat(self.nBarGroups - 1))
        //let indicatorMinX = self.view.frame.width / 2 - indicatorWidth / 2
        for i in 0..<self.nBarGroups {
            var indicator = UIImageView()
            if i == self.currentBarGroup {
                indicator = UIImageView(image: UIImage(named: "selectedCircle"))
            } else {
                indicator = UIImageView(image: UIImage(named: "unselectedCircle"))
            }
            //let thisMinX = indicatorMinX + (indicatorXSpacing + CGFloat(indicatorSize)) * CGFloat(i)
            //indicator.frame = CGRect(x: thisMinX, y: indicatorTop, width: indicatorSize, height: indicatorSize)
            let indicatorOffset = (indicatorXSpacing + CGFloat(indicatorSize)) * CGFloat(i)
            self.barGroupIndicators.append(indicator)
            self.view.addSubview(self.barGroupIndicators[i])
            self.barGroupIndicators[i].translatesAutoresizingMaskIntoConstraints = false
            self.barGroupIndicators[i].leftAnchor.constraint(equalTo: self.view.centerXAnchor, constant: indicatorOffset - indicatorWidth / 2).isActive = true
            self.barGroupIndicators[i].topAnchor.constraint(equalTo: self.toolBar.topAnchor, constant: indicatorYSpacing).isActive = true
            self.barGroupIndicators[i].widthAnchor.constraint(equalToConstant: indicatorSize).isActive = true
            self.barGroupIndicators[i].heightAnchor.constraint(equalToConstant: indicatorSize).isActive = true
            
            indicator.contentMode = .scaleAspectFit

            
        }
    }
    
    func setBarGroupIndicator() {
        
        //print(self.currentBarGroup)
    }
    
    
    func makeBarButton(buttonTag: Int) -> UIButton {
        
        let thisIcon = self.barButtonIcons[buttonTag]
    
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: thisIcon.normal), for: .normal)
        
        // If the button tag matches the currently selected button, make it's background image the selected one
        /*if buttonTag == self.selectedToolBarButton {
            button.setBackgroundImage(image: normalBackGroundImage, for: .normal)
        } else {
            button.setBackgroundImage(image: selectedBackGroundImage, for: .normal)
        }*/
        
        button.frame = CGRect(x: 0.0, y: 0.0, width: self.barButtonWidth, height: self.barButtonSize)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: self.barButtonWidth).isActive = true
        button.heightAnchor.constraint(equalToConstant: self.barButtonSize).isActive = true
        button.imageView?.contentMode = .scaleAspectFit
        button.tag = buttonTag
        button.addTarget(self, action: #selector(handleToolBarButton(sender:)), for: .touchUpInside)
        
        return button
    }
    
    
    // Switch the tableView data when a toolbar button is clicked
    @objc func handleToolBarButton(sender: UIBarButtonItem) {
        
        // Get the tag of the previously selected button so that we can change it's background image
        let previousButtonTag = self.selectedToolBarButton
        
        // Set the background image of the selected button to the selected image
        self.selectedToolBarButton = sender.tag
        //let currentButton = makeBarButton(buttonTag: sender.tag)
        //self.barButtons[sender.tag] = UIBarButtonItem(customView: currentButton)
        
        // Set background image of the previously selected button to the unselected image
        //let previousButton = makeBarButton(buttonTag: previousButtonTag)
        //self.barButtons[previousButtonTag] = UIBarButtonItem(customView: previousButton)
        
        // If the previous query was empty, no need to scroll to the top (throws an error). Otherwise, reset the scroll position to the first row.
        if self.tableView.numberOfRows(inSection: 0) > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)//(indexPath, atScrollPosition: .top, animated: true)
        }
        
        // Reload the table for the newly selected button
        loadData()
        
        // Reset the title of the nav bar. To do this, recreate the whole NavigationBar
        self.title = "\(self.barButtonIcons[sender.tag].label) Observations"
        setNavigationBar()
    }
    
    
    func makeNextBarButton(tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0.0, y: 0.0, width: self.barButtonSize, height: self.barButtonSize)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: self.barButtonSize).isActive = true
        button.heightAnchor.constraint(equalToConstant: self.barButtonSize).isActive = true
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(handleNextButton(sender:)), for: .touchUpInside)
        button.tag = tag
        
        let nextImage = UIImage(named: "backButton")
        if tag == 0 {
            button.setImage(nextImage, for: .normal)
        } else {
            button.setImage(UIImage(cgImage: (nextImage?.cgImage)!, scale: (nextImage?.scale)!, orientation: .upMirrored), for: .normal)
        }
        
        return button
    }
    
    @objc func handleNextButton(sender: UIBarButtonItem) {
        
        self.barGroupIndicators[self.currentBarGroup].image = UIImage(named: "unselectedCircle")
        
        // Sender is the left button
        if sender.tag == 0 {
            self.currentBarGroup -= 1
            if self.currentBarGroup == 0 {
                self.leftToolBarButton.isEnabled = false
            }
            // Make sure the other button is enabled
            self.rightToolBarButton.isEnabled = true
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                for button in self.barButtons {
                    let frame = (button.customView?.frame)!
                    button.customView?.frame = CGRect(x: frame.maxX + self.view.bounds.width, y: frame.minY, width: self.barButtonSize, height: self.barButtonSize)
                }
            }, completion: {_ in self.setToolBarButtons()})
            
        
        // Sender is the right button
        } else {
            self.currentBarGroup += 1
            if self.currentBarGroup == self.nBarGroups - 1 {
                self.rightToolBarButton.isEnabled = false
            }
            // Make sure the other button is enabled
            self.leftToolBarButton.isEnabled = true
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                for button in self.barButtons {
                    let frame = (button.customView?.frame)!
                    button.customView?.frame = CGRect(x: frame.minX - self.view.bounds.width, y: frame.minY, width: self.barButtonSize, height: self.barButtonSize)
                }
            }, completion: {_ in self.setToolBarButtons()})
        }
        
        // Draw group indicators
        self.barGroupIndicators[self.currentBarGroup].image = UIImage(named: "selectedCircle")
        
    }
    
    
    // When user swipes left on toolbar, call the function associated with the right "next" button
    @objc func swipeLeftOnToolBar() {
        if self.rightToolBarButton.isEnabled {
            self.rightToolBarButton.tag = 1
            handleNextButton(sender: self.rightToolBarButton)
        }
    }
    
    
    // When user swipes right on toolbar, call the function associated with the left "next" button
    @objc func swipeRightOnToolBar() {
        if self.leftToolBarButton.isEnabled {
            handleNextButton(sender: self.leftToolBarButton)
        }
    }
    
    
    //MARK: - Navigation
    func setNavigationBar() {
        let screenSize: CGRect = UIScreen.main.bounds
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        self.navigationBar = CustomNavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: screenSize.width, height: navigationBarSize))
        self.view.addSubview(self.navigationBar)
        self.navigationBar.translatesAutoresizingMaskIntoConstraints = false
        self.navigationBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.navigationBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.navigationBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: statusBarHeight).isActive = true
        self.navigationBar.heightAnchor.constraint(equalToConstant: navigationBarSize).isActive = true
        
        let navigationItem = UINavigationItem(title: self.title!)
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage (named: "backButton"), for: .normal)
        backButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        backButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        let backBarButton = UIBarButtonItem(customView: backButton)
        
        // Since this method is called when the view is loaded and when rotated, check to see if the table is being edited
        let editButton: UIButton
        if self.isEditingTable {
            editButton = makeEditButton(imageName: "checkIcon")
            //self.editBarButton.customView = editButton
        } else {
            editButton = makeEditButton(imageName: "deleteIcon")
        }
        self.editBarButton = UIBarButtonItem(customView: editButton)
        
        //let addObservationButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: #selector(addButtonPressed))
        // Add button for adding a new observation
        let addButton = UIButton(type: .custom)
        addButton.setImage(UIImage(named: "addIcon"), for: .normal)
        addButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        addButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        let addObservationButton = UIBarButtonItem(customView: addButton)
        
        let qrButton = UIButton(type: .custom)
        qrButton.setImage(UIImage (named: "scanQRIcon"), for: .normal)
        qrButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        qrButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        qrButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        qrButton.addTarget(self, action: #selector(qrButtonPressed), for: .touchUpInside)
        let qrBarButton = UIBarButtonItem(customView: qrButton)
        //let QRButton = UIBarButtonItem(title: "QR", style: .plain, target: self, action: #selector(qrButtonPressed))
        
        // Add a button for switching the active database file
        let databaseButton = UIButton(type: .custom)
        databaseButton.setImage(UIImage(named: "switchDatabaseIcon"), for: .normal)
        databaseButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        databaseButton.translatesAutoresizingMaskIntoConstraints = false
        databaseButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        databaseButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        databaseButton.addTarget(self, action: #selector(selectDatabaseButtonPressed), for: .touchUpInside)
        let selectDatabaseButton = UIBarButtonItem(customView: databaseButton)
        
        //let googleDriveBarButton = UIBarButtonItem(title: "D", style: .plain, target: self, action: #selector(googleDriveButtonPressed))
        // Add a button for switching the active database file
        let googleDriveButton = UIButton(type: .custom)
        googleDriveButton.setImage(UIImage(named: "googleDriveIcon"), for: .normal)
        googleDriveButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        googleDriveButton.translatesAutoresizingMaskIntoConstraints = false
        googleDriveButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        googleDriveButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        googleDriveButton.addTarget(self, action: #selector(googleDriveButtonPressed), for: .touchUpInside)
        let googleDriveBarButton = UIBarButtonItem(customView: googleDriveButton)
        
        //let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: #selector(archiveButtonPressed(button:)))
        // Add the archive button
        /*let archiveButton = UIButton(type: .custom)
        archiveButton.setImage(UIImage(named: "archiveIcon"), for: .normal)
        archiveButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        archiveButton.translatesAutoresizingMaskIntoConstraints = false
        archiveButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        archiveButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        archiveButton.imageView?.contentMode = .scaleAspectFit
        archiveButton.addTarget(self, action: #selector(archiveButtonPressed), for: .touchUpInside)//button:)), for: .touchUpInside)
        //archiveButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 100, bottom: 0, right: 0)
        let archiveBarButton = UIBarButtonItem(customView: archiveButton)*/
        
        let fixedSpaceLeft = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        let fixedSpaceRight = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        fixedSpaceLeft.width = 50
        fixedSpaceRight.width = 50
        navigationItem.leftBarButtonItems = [backBarButton, fixedSpaceLeft, selectDatabaseButton, fixedSpaceLeft, googleDriveBarButton]
        navigationItem.rightBarButtonItems = [self.editBarButton, fixedSpaceRight, qrBarButton, fixedSpaceRight, addObservationButton]
        self.navigationBar.setItems([navigationItem], animated: false)
        
    }
    
    // Helper function to create edit button
    func makeEditButton(imageName: String) -> UIButton {
        let editButton = UIButton(type: .custom)
        editButton.setImage(UIImage(named: imageName), for: .normal)
        editButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        editButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        editButton.imageView?.contentMode = .scaleAspectFit
        //editButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 100)
        editButton.addTarget(self, action: #selector(handleEditing), for: .touchUpInside)
        
        return editButton
    }
    
    // Set the editing button to the custom trashcan or check icon
    @objc func handleEditing() {
        
        self.tableView.setEditing(self.isEditing, animated: true)
        if !self.isEditingTable {
            self.tableView.isEditing = true
            self.isEditingTable = true
            let editButton = makeEditButton(imageName: "checkIcon")
            self.editBarButton.customView = editButton
            
        } else {
            self.tableView.isEditing = false
            self.isEditingTable = false
            let editButton = makeEditButton(imageName: "deleteIcon")
            self.editBarButton.customView = editButton
        }
        
        // Re-adjust scrollable area to be able to scroll past toolBar
        self.tableView.contentSize.height += self.toolBar.frame.height
    }
    
    
    @objc func qrButtonPressed(){
        let scannerController = ScannerViewController()
        present(scannerController, animated: true)
    }
    
    
    @objc func backButtonPressed(){
        
        // Cancel editing
        if self.isEditingTable {
            self.tableView.isEditing = false
            self.isEditingTable = false
            let editButton = makeEditButton(imageName: "deleteIcon")
            self.editBarButton.customView = editButton
        }
        
        // Reload session info so it reflects the active DB
        if let presentingContoller = self.presentingViewController as? AddObservationViewController {
            presentingContoller.loadData()
        }
        
        self.dismissTransition = LeftToRightTransition()
        dismiss(animated: true, completion: {[weak self] in self?.dismissTransition = nil})
        
    }
    
    func saveFile(url: URL) {
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content, public.database"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentOptionsMenu(from: self.view.frame, in: self.view, animated: true)
    }
    
    func prepareDatabaseBrowserViewController() -> DatabaseBrowserViewController {
        let browserViewController = DatabaseBrowserViewController()
        browserViewController.modalPresentationStyle = .formSheet
        UIViewController.formSheetSize = CGSize(width: min(self.view.frame.width, 600), height: min(self.view.frame.height, 500)) // Set this because it affects the bounds of the blurEffectView
        browserViewController.preferredContentSize = UIViewController.formSheetSize//CGSize(width: min(self.view.frame.width, 600), height: min(self.view.frame.height, 500))//CGSize.init(width: 600, height: 600)
        
        // Add blurred background from current view
        let popoverFrame = browserViewController.getVisibleFrame()
        let backgroundView = self.blurredSnapshotView //getBlurredSnapshot(frame: popoverFrame)
        browserViewController.view.addSubview(backgroundView)
        browserViewController.view.sendSubview(toBack: backgroundView)
        
        return browserViewController
    }
    
    @objc func selectDatabaseButtonPressed() {
        let browserViewController = prepareDatabaseBrowserViewController()
        
        present(browserViewController, animated: true, completion: nil)
    }
    
    
    @objc func googleDriveButtonPressed() {
        
        if Reachability.isConnectedToNetwork() {
            let uploadViewController = GoogleDriveUploadViewController()
            uploadViewController.modalPresentationStyle = .formSheet
            UIViewController.formSheetSize = CGSize(width: min(self.view.frame.width, 600), height: min(self.view.frame.height, 500)) // Set this because it affects the bounds of the blurEffectView
            uploadViewController.preferredContentSize = UIViewController.formSheetSize
            
            // Add blurred background from current view
            let _ = uploadViewController.getVisibleFrame()
            let backgroundView = self.blurredSnapshotView //getBlurredSnapshot(frame: popoverFrame)
            uploadViewController.view.addSubview(backgroundView)
            uploadViewController.view.sendSubview(toBack: backgroundView)
            
            // Configure the dbBrowserController now so that the blurred background is shows the tableView,
            //  not the formsheet G Drive Upload controller
            let dbBrowserViewController = prepareDatabaseBrowserViewController()
            dbBrowserViewController.isLoadingDatabase = false
            uploadViewController.dbBrowserViewController = dbBrowserViewController
            
            present(uploadViewController, animated: true, completion: {GIDSignIn.sharedInstance().signIn()})
        } else {
            // present an alert
            let alertTitle = "No internet connection detected"
            let alertMessage = "You cannot upload to Google Drive without an internet connection. Try again when your internet connection is working."
            let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    // Stop the UIActivityIndicatorView animation that was started when the user
    // pressed the Sign In button
    func signInWillDispatch(signIn: GIDSignIn!, error: Error!) {
        //myActivityIndicator.stopAnimating()
    }
    
    // Present a view that prompts the user to sign in with Google
    func sign(_ signIn: GIDSignIn!,
              present viewController: UIViewController!) {
        self.present(viewController, animated: true, completion: nil)
    }
    
    // Dismiss the "Sign in with Google" view
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: - TableView delegate methods
    // return the number of sections
    func numberOfSections(in tableView: UITableView) -> Int{
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return self.observations.count
        return self.observationCells.count
    }
    

    // Compose each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! BaseObservationTableViewCell
    
        // Fetch the right observation for the data source layout
        let index = self.cellOrder[indexPath.row]
        let observationCell: ObservationCell
        if let thisCell = observationCells[index] {
            observationCell = thisCell
        } else {
            os_log("Index does not match existing observationCell in tableView(:cellForRowAt)", log: .default, type: .debug)
            showGenericAlert(message: "The index \(index) does not match an existing item in the list of observations", title: "Data load error")
            return cell
        }
        let observation = observationCell.observation
        let imageName: String
        if let name = icons[observationCell.observationType]?.normal {
            imageName = name
        } else {
            os_log("observationType does not exist in icons (tableView(:cellForRowAt))", log: .default, type: .debug)
            showGenericAlert(message: "The observationType \(observationCell.observationType) is not recognized in self.observationCells", title: "Data load error")
            return cell
        }
        
        cell.centerLabel.text = observationCell.label2
        if !self.cellLabelColumns.keys.contains(observationCell.observationType) {
            os_log("observationType does not exist in self.cellLabelColumns (tableView(:cellForRowAt))", log: .default, type: .debug)
            showGenericAlert(message: "The observationType \(observationCell.observationType) is not recognized in self.cellLabelColumns", title: "Data load error")
            return cell
        }
        let cellLabels = self.cellLabelColumns[observationCell.observationType]!
        let label2IconName = "\(cellLabels.label2)Icon"
        cell.centerIcon.image = UIImage(named: label2IconName)

        cell.datetimeLabel.text = "\(observation.date) \(observation.time)"
        cell.rightLabel.text = observationCell.label3//observation.nPassengers
        let label3IconName = "\(cellLabels.label3)Icon"
        cell.rightIcon.image = UIImage(named: label3IconName)
        cell.mainIcon.image = UIImage(named: imageName)
        
        // Show the selected cell with a translucent white
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        cell.selectedBackgroundView = backgroundView
        
        return cell
    }
    
    
    // called when the cell is selected.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // If the database has been deleted, alert the user, reload data, and exit
        if !checkCurrentDb() { return }
        
        let index = self.cellOrder[indexPath.row]
        if !self.observationCells.keys.contains(index) {
            os_log("Index does does not exist in (tableView(:didSelectRowAt))", log: .default, type: .debug)
            showGenericAlert(message: "The index \(index) does not exist in the list of observations", title: "Data load error")
            return
        }
        let thisObservation = (self.observationCells[index]?.observation)!
        let observationType = (self.observationCells[index]?.observationType)!
        
        if !observationViewControllers.keys.contains(observationType) {
            os_log("observation type  is not recognized (tableView(:didSelectRowAt))", log: .default, type: .debug)
            showGenericAlert(message: "The observation type \(observationType) is not recognized (tableView(:didSelectRowAt))", title: "Data load error")
            return
        }
        let observationViewController = observationViewControllers[observationType]!.init() //Stored in Constants.swift
        observationViewController.observationId = thisObservation.id
        observationViewController.title = observationType
        observationViewController.isAddingNewObservation = false
        observationViewController.modalPresentationStyle = .custom
        observationViewController.transitioningDelegate = self
        
        // Set the transition. When done transitioning, reset presentTransition to nil
        self.presentTransition = RightToLeftTransition()
        present(observationViewController, animated: true, completion: {[weak self] in self?.presentTransition = nil})
    }
    
    
    // Enable editing
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        // If the database has been deleted, alert the user, reload data, set the table to non-edit mode and exit
        if !checkCurrentDb() {
            if self.isEditingTable {
                self.tableView.isEditing = false
                self.isEditingTable = false
                let editButton = makeEditButton(imageName: "deleteIcon")
                self.editBarButton.customView = editButton
            }
            return
        }
        
        if editingStyle == .delete {
            // Delete the row from the data source
            //let id = observations[indexPath.row].id
            if !self.cellOrder.contains(indexPath.row) {
                os_log("indexPath does does not exist in self.cellOrder - (tableView(:commit:forRowAt))", log: .default, type: .debug)
                showGenericAlert(message: "The indexPath \(indexPath.row) does not exist in the list of observations", title: "Data load error")
                return
            }
            let index = self.cellOrder[indexPath.row]
            
            if !self.observationCells.keys.contains(index) {
                os_log("Index does does not exist in (tableView(:commit:forRowAt))", log: .default, type: .debug)
                showGenericAlert(message: "The index \(index) does not exist in the list of observations", title: "Data load error")
                return
            }
            let thisCell = self.observationCells[index]!
            
            let id = thisCell.observation.id
            let observationType = thisCell.observationType
            let tableName = self.icons[observationType]?.tableName ?? ""
            let table = Table(tableName)
            
            let recordToRemove = table.where(idColumn == id.datatypeValue)
            if let success = try? db.run(recordToRemove.delete()) {
                loadObservations()
                tableView.deleteRows(at: [indexPath], with: .fade)
            } else {
                let alertTitle = "Delete failed"
                let alertMessage = "The delete operation failed for an unknown reason"
                let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alertController, animated: true, completion: nil)
            }

        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    //MARK: - Private Methods
    func loadObservations(){// -> [Observation]?{
        // ************* check that the table exists first **********************
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        
        var observationTypes = [String]()
        var loadedObservations = [Observation]()
        let selectedObservationType = self.barButtonIcons[self.selectedToolBarButton].label
        switch selectedObservationType {
        case "All":
            for observationType in self.icons.keys {
                observationTypes.append(observationType)
            }
        default:
            observationTypes = [selectedObservationType]
            //print("observationType \(selectedObservationType) not understood")
        }
        
        // Clear the data to put in the table
        self.observationCells.removeAll()
        
        // For each table query all records
        var datetimeStamps = [Int: Date]()
        var i = 0
        for label in observationTypes {
            let info = self.icons[label]!
            let table = Table(info.tableName)
            let label2ColumnName = self.cellLabelColumns[label]!.label2
            let label3ColumnName = self.cellLabelColumns[label]!.label3
            let label2Column = Expression<String>(label2ColumnName)
            let label3Column = Expression<String>(label3ColumnName)
            var rows = [Row]()
            
            do {
                rows = Array(try db.prepare(table))
            } catch {
                os_log("Could not load observations", log:.default, type:.debug)
                
                let alertTitle = "Error encountered with \(info.tableName) table"
                let alertMessage = "Data from the \(info.tableName) table could not be loaded. This database is likely not valid or it could have somehow gotten corrupt. Press OK to enter shift info and try repairing the database"
                let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {handler in
                    //alertController.dismiss(animated: false, completion: nil)
                    self.showShiftInfoForm()
                }))
                present(alertController, animated: true, completion: nil)
                return
            }
            
            
            guard let statement = try? db.prepare("PRAGMA table_info(\(info.tableName))") else {
                return
            }
            var columnNames = [String]()
            for row in statement{
                for (index, name) in statement.columnNames.enumerated() {
                    if name == "name" {
                        columnNames.append("\(row[index]!)")
                    }
                }
            }
            for row in rows{
                // Since 'Bus' and 'Lodge Bus' are both stored in the 'buses' table, but they're separate
                //  vehicle types, make sure that they're not double counted when listing observations.
                //  Do so by checking the bus type (center label)
                if (label == "Bus" && (lodges.contains(row[label2Column]) && row[label2Column] != "Other")) || (label == "Lodge Bus" && (!lodges.contains(row[label2Column]) || row[label2Column] == "Other")) {
                    continue
                }
                // Create a generic observation instance
                let observation = Observation(id: Int(row[idColumn]), observerName: row[observerNameColumn], date: row[dateColumn], time: row[timeColumn], driverName: row[driverNameColumn], destination: row[destinationColumn], nPassengers: row[nPassengersColumn], comments: row[commentsColumn])

                // Check if the columns for labels actually exist. If not, set the labels to empty strings
                let label2: String
                if columnNames.contains(label2ColumnName) {
                    label2 = row[label2Column]
                }
                else {
                    label2 = ""
                }
                
                let label3: String
                if columnNames.contains(label3ColumnName) {
                    label3 = row[label3Column]
                }
                else {
                    label3 = ""
                }
                
                let observationCell = ObservationCell(observationType: label, iconName: info.normal, observation: observation!, label2: label2, label3: label3)
                
                // Get the time stamp as an NSDate object so all timestamps can be properly sorted
                let datetimeString = "\((observation?.date)!), \((observation?.time)!)"
                guard let datetime = formatter.date(from: datetimeString) else {
                    showGenericAlert(message: "Could not interpret datetimeString: \(datetimeString)", title: "Data load error")
                    os_log("Could not interpret datettimeString in ObservationTableViewControler.loadObservations()", log: .default, type: .debug)
                    return
                }
                datetimeStamps[i] = datetime
                self.observationCells[i] = observationCell
                loadedObservations.append(observation!)
                i += 1
            }
            
            
        }
        
        // Get the indices sorted by datetime in reverse chronological order so most recent is always on top
        self.cellOrder.removeAll()
        let sortedStamps = datetimeStamps.sorted{$0.value > $1.value}
        for (index, _) in sortedStamps {
            self.cellOrder.append(index)
        }
        
        self.observations = loadedObservations
        
    }
    
    func loadSession() throws { //}-> Session?{
        // ************* check that the table exists first **********************
        let rows = Array(try db.prepare(sessionsTable))
        if rows.count > 1 {
            //fatalError("Multiple sessions found")
            os_log("Multiple sessions found", log: OSLog.default, type: .debug)
        }
        for row in rows{
            self.session = Session(id: Int(row[idColumn]), observerName: row[observerNameColumn], openTime:row[openTimeColumn], closeTime: row[closeTimeColumn], givenDate: row[dateColumn])
        }
    }
    
}
