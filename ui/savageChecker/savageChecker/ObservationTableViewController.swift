//
//  BaseTableViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 6/3/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//
import UIKit
import SQLite


class BaseTableViewController: UITabBarController, UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate{//UITabBarDelegate {
    
    //MARK: - Properties
    //MARK: General
    var tableView: UITableView!
    private var navigationBar: CustomNavigationBar!
    private var backButton: UIBarButtonItem!
    private var editBarButton: UIBarButtonItem!
    //private var tabBar: UITabBar!
    var presentTransition: UIViewControllerAnimatedTransitioning?
    var dismissTransition: UIViewControllerAnimatedTransitioning?
    var dismiss = false
    var blurEffectView: UIVisualEffectView!
    var isEditingTable = false // Need to track whether the table is editing because tableView.isEditing resets to false as soon as edit button is pressed
    let documentInteractionController = UIDocumentInteractionController()
    
    let observationViewControllers = ["Bus": BusObservationViewController(),
                                      "Lodge Bus": LodgeBusObservationViewController(),
                                      "NPS Vehicle": NPSVehicleObservationViewController(),
                                      "NPS Approved": NPSApprovedObservationViewController(),
                                      "NPS Contractor": NPSContractorObservationViewController(),
                                      "Employee": EmployeeObservationViewController(),
                                      "Right of Way": RightOfWayObservationViewController(),
                                      "Tek Camper": TeklanikaCamperObservationViewController(),
                                      "Bicycle": CyclistObservationViewController(),
                                      "Propho": PhotographerObservationViewController(),
                                      "Accessibility": AccessibilityObservationViewController(),
                                      "Subsistence": SubsistenceObservationViewController(),
                                      "Road Lottery": RoadLotteryObservationViewController(),
                                      "Other": OtherObservationViewController()]
    
    let icons = ["Bus": (normal: "busIcon", selected: "shuttleBusImg", tableName: "buses", dataClassName: "BusObservation"),
                 "Lodge Bus": (normal: "lodgeBusIcon", selected: "shuttleBusImg", tableName: "buses", dataClassName: "BusObservation"),
                 "NPS Vehicle": (normal: "npsVehicleIcon", selected: "shuttleBusImg", tableName: "npsVehicles", dataClassName: "NPSVehicleObservation"),
                 "NPS Approved": (normal: "npsApprovedIcon", selected: "shuttleBusImg", tableName: "npsApproved", dataClassName: "NPSApprovedObservation"),
                 "NPS Contractor": (normal: "npsContractorIcon", selected: "shuttleBusImg", tableName: "npsContractors", dataClassName: "NPSContractorObservation"),
                 "Employee": (normal: "employeeIcon", selected: "shuttleBusImg", tableName: "employees", dataClassName: "EmployeeObservation"),
                 "Right of Way": (normal: "rightOfWayIcon", selected: "shuttleBusImg", tableName: "rightOfWay", dataClassName: "RightOfWayObservation"),
                 "Tek Camper": (normal: "tekCamperIcon", selected: "shuttleBusImg", tableName: "tekCampers", dataClassName: "TeklanikaCamperObservation"),
                 "Bicycle": (normal: "cyclistIcon", selected: "shuttleBusImg", tableName: "cyclists", dataClassName: "Observation"),
                 "Propho": (normal: "photographerIcon", selected: "shuttleBusImg", tableName: "photographers", dataClassName: "PhotographerObservation"),
                 "Accessibility": (normal: "accessibilityIcon", selected: "shuttleBusImg", tableName: "accessibility", dataClassName: "AccessibilityObservation"),
                 "Subsistence": (normal: "subsistenceIcon", selected: "shuttleBusImg", tableName: "subsistenceUsers", dataClassName: "Observation"),
                 "Road Lottery": (normal: "roadLotteryIcon", selected: "shuttleBusImg", tableName: "roadLottery", dataClassName: "Observation"),
                 "Other": (normal: "otherIcon", selected: "shuttleBusImg", tableName: "other", dataClassName: "Observation")]
    
    //MARK: ToolBar properties
    let toolBar = UIToolbar()
    
    let barButtonIcons = [(label: "All", normal: "allTableIcon", selected: "shuttleBusImg", tableName: "buses", dataClassName: "BusObservation"),
                          (label: "Bus", normal: "busIcon", selected: "shuttleBusImg", tableName: "buses", dataClassName: "BusObservation"),
                          (label: "Lodge Bus", normal: "lodgeBusIcon", selected: "shuttleBusImg", tableName: "buses", dataClassName: "BusObservation"),
                          (label: "NPS Vehicle", normal: "npsVehicleIcon", selected: "shuttleBusImg", tableName: "npsVehicles", dataClassName: "NPSVehicleObservation"),
                          (label: "NPS Approved", normal: "npsApprovedIcon", selected: "shuttleBusImg", tableName: "npsApproved", dataClassName: "NPSApprovedObservation"),
                          (label: "NPS Contractor", normal: "npsContractorIcon", selected: "shuttleBusImg", tableName: "npsContractors", dataClassName: "NPSContractorObservation"),
                          (label: "Employee", normal: "employeeIcon", selected: "shuttleBusImg", tableName: "employees", dataClassName: "EmployeeObservation"),
                          (label: "Right of Way", normal: "rightOfWayIcon", selected: "shuttleBusImg", tableName: "rightOfWay", dataClassName: "RightOfWayObservation"),
                          (label: "Tek Camper", normal: "tekCamperIcon", selected: "shuttleBusImg", tableName: "tekCampers", dataClassName: "TeklanikaCamperObservation"),
                          (label: "Bicycle", normal: "cyclistIcon", selected: "shuttleBusImg", tableName: "cyclists", dataClassName: "Observation"),
                          (label: "Propho", normal: "photographerIcon", selected: "shuttleBusImg", tableName: "photographers", dataClassName: "PhotographerObservation"),
                          (label: "Accessibility", normal: "accessibilityIcon", selected: "shuttleBusImg", tableName: "accessibility", dataClassName: "AccessibilityObservation"),
                          (label: "Subsistence", normal: "subsistenceIcon", selected: "shuttleBusImg", tableName: "subsistenceUsers", dataClassName: "Observation"),
                          (label: "Road Lottery", normal: "roadLotteryIcon", selected: "shuttleBusImg", tableName: "roadLottery", dataClassName: "Observation"),
                          (label: "Other", normal: "otherIcon", selected: "shuttleBusImg", tableName: "other", dataClassName: "Observation")]
    
    let barButtonSize: CGFloat = 65
    let barButtonWidth: CGFloat = 150
    let barHeight: CGFloat = 140
    var nBarGroups = 1
    var currentGroup = 0
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
    let cellLabelColumns = ["Bus":            (label2: "busType",         label3: "destination"),
                            "Lodge Bus":      (label2: "busType",         label3: "busNumber"),
                            "NPS Vehicle":    (label2: "driverName",      label3: "workDivision"),
                            "NPS Approved":   (label2: "approvedType",    label3: "destination"),
                            "NPS Contractor": (label2: "destination",     label3: "organizationName"),
                            "Employee":       (label2: "driverName",      label3: "nPassengers"),
                            "Right of Way":   (label2: "driverName",      label3: "nPassengers"),
                            "Tek Camper":     (label2: "nPassengers",     label3: ""),
                            "Bicycle":        (label2: "destination",     label3: "nPassengers"),
                            "Propho":         (label2: "driverName",      label3: "nExpectedNights"),
                            "Accessibility":  (label2: "driverName",      label3: "destination"),
                            "Subsistence":    (label2: "driverName",      label3: "nPassengers"),
                            "Road Lottery":   (label2: "permitNumber",    label3: "nPassengers"),
                            "Other":          (label2: "destination",     label3: "nPassengers")]
    
    
    //MARK: db properties
    //var modelObjects = [Any]()
    private var observations = [Observation]()
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
            fatalError(error.localizedDescription)
        }
        
        // Load observations
        //loadData()
        
        self.presentTransition = RightToLeftTransition()
        self.dismissTransition = LeftToRightTransition()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let navigationBarHeight: CGFloat = self.navigationBar.frame.size.height
        let newScreenSize = UIScreen.main.bounds
        
        self.tableView.frame = CGRect(x: 0, y: statusBarHeight + navigationBarHeight, width: newScreenSize.width, height: newScreenSize.height - (statusBarHeight + navigationBarHeight + self.barHeight))
        
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
    
    // Convenience function to load all tableView data
    func loadData() {
        do {
            try loadSession()
            //self.observations = loadObservations()!
            loadObservations()
        } catch let error{
            fatalError(error.localizedDescription)
        }
        
        self.tableView.reloadData()//This probably gets called twicce in veiwDidLoad(), but data needs to be reloaded from form view controller when an observation is added or updated

        let range = NSMakeRange(0, self.tableView.numberOfSections)
        let sections = NSIndexSet(indexesIn: range)
        self.tableView.reloadSections(sections as IndexSet, with: .automatic)
        
        // Set scrollable area so you can scroll past toolBar*/
        self.tableView.contentSize.height += self.toolBar.frame.height
    }
    
    
    //MARK: ToolBar setup
    // Arrange the tool bar for selecting the table display mode
    func setupToolBarLayout(){
        
        //let screenSize: CGRect = UIScreen.main.bounds
        let screenSize = UIScreen.main.bounds
        self.toolBar.frame = CGRect(x: 0, y: screenSize.height - self.barHeight, width: screenSize.width, height: self.barHeight)
        //self.toolBar.layer.position = CGPoint(x: screenSize.width/2, y: self.barHeight)
        
        //figure out how many buttons per group
        let tableViewButtonWidth = screenSize.width - (self.barButtonSize * 2) // Make room for back/forward buttons plus space on either side
        let nButtonsPerGroup = floor(tableViewButtonWidth / self.barButtonWidth)
        self.nBarGroups = Int(ceil(CGFloat(barButtonIcons.count) / nButtonsPerGroup))
        
        // Make the left and right buttons
        let leftButton = makeNextBarButton(tag: 0)
        let rightButton = makeNextBarButton(tag: 1)
        self.leftToolBarButton = UIBarButtonItem(customView: leftButton)
        self.rightToolBarButton = UIBarButtonItem(customView: rightButton)
        self.leftToolBarButton.isEnabled = false //Shouldn't be able go left before going right first
        
        // Add buttons to toolbar
        setToolBarButtons()
        
        self.view.addSubview(self.toolBar)
        
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
        
        let nButtonsPerGroup = self.barButtonIcons.count / self.nBarGroups
        let leftButtonId = (nButtonsPerGroup + 1) * self.currentGroup
        let rightButtonId = min(leftButtonId + nButtonsPerGroup + 1, self.barButtonIcons.count)
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        let barItems = [self.leftToolBarButton, flexSpace] + self.barButtons[leftButtonId..<rightButtonId] + [flexSpace, self.rightToolBarButton]
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
        let indicatorTop = self.toolBar.frame.minY + indicatorYSpacing
        let indicatorSize: CGFloat = 7
        let indicatorWidth = CGFloat(indicatorSize * CGFloat(self.nBarGroups)) + (indicatorXSpacing * CGFloat(self.nBarGroups - 1))
        let indicatorMinX = UIScreen.main.bounds.width / 2 - indicatorWidth / 2
        for i in 0..<self.nBarGroups {
            var indicator = UIImageView()
            if i == self.currentGroup {
                indicator = UIImageView(image: UIImage(named: "selectedCircle"))
                //indicator.image = UIImage(named: "selectedCircle")
            } else {
                indicator = UIImageView(image: UIImage(named: "unselectedCircle"))
                //indicator.image = UIImage(named: "unselectedCircle")
            }
            let thisMinX = indicatorMinX + (indicatorXSpacing + CGFloat(indicatorSize)) * CGFloat(i)
            indicator.frame = CGRect(x: thisMinX, y: indicatorTop, width: indicatorSize, height: indicatorSize)
            indicator.contentMode = .scaleAspectFit

            self.barGroupIndicators.append(indicator)
            self.view.addSubview(self.barGroupIndicators[i])
        }
    }
    
    func setBarGroupIndicator() {
        
        print(self.currentGroup)
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
        
        self.barGroupIndicators[self.currentGroup].image = UIImage(named: "unselectedCircle")
        print("Sender tag: \(sender.tag)")
        // Sender is the left button
        if sender.tag == 0 {
            self.currentGroup -= 1
            if self.currentGroup == 0 {
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
            self.currentGroup += 1
            if self.currentGroup == self.nBarGroups - 1 {
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
        self.barGroupIndicators[self.currentGroup].image = UIImage(named: "selectedCircle")
        
    }
    
    
    // When user swipes left on toolbar, call the function associated with the right "next" button
    @objc func swipeLeftOnToolBar() {
        print("Trying to swipe left")
        print("self.rightToolBarButton.tag: \(self.rightToolBarButton.tag)")
        if self.rightToolBarButton.isEnabled {
            self.rightToolBarButton.tag = 1
            handleNextButton(sender: self.rightToolBarButton)
        }
    }
    
    
    // When user swipes right on toolbar, call the function associated with the left "next" button
    @objc func swipeRightOnToolBar() {
        print("Trying to swipe right")
        if self.leftToolBarButton.isEnabled {
            handleNextButton(sender: self.leftToolBarButton)
        }
    }
    
    
    //MARK: - Navigation
    func setNavigationBar() {
        let screenSize: CGRect = UIScreen.main.bounds
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        self.navigationBar = CustomNavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: screenSize.width, height: 44))
        
        let navigationItem = UINavigationItem(title: self.title!)
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage (named: "backButton"), for: .normal)
        backButton.frame = CGRect(x: 0.0, y: 0.0, width: 25, height: 25)
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        backButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
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
        addButton.frame = CGRect(x: 0.0, y: 0.0, width: 25, height: 25)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        addButton.imageView?.contentMode = .scaleAspectFit
        addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
        let addObservationButton = UIBarButtonItem(customView: addButton)
        
        //let QRButton = UIBarButtonItem(title: "QR", style: .plain, target: self, action: #selector(qrButtonPressed))
        
        // Add a button for switching the active database file
        let databaseButton = UIButton(type: .custom)
        databaseButton.setImage(UIImage(named: "switchDatabaseIcon"), for: .normal)
        databaseButton.frame = CGRect(x: 0.0, y: 0.0, width: 30, height: 30)
        databaseButton.translatesAutoresizingMaskIntoConstraints = false
        databaseButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        databaseButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        databaseButton.imageView?.contentMode = .scaleAspectFit
        databaseButton.addTarget(self, action: #selector(selectDatabaseButtonPressed), for: .touchUpInside)
        let selectDatabaseButton = UIBarButtonItem(customView: databaseButton)
        
        //let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: #selector(archiveButtonPressed(button:)))
        // Add the archive button
        let archiveButton = UIButton(type: .custom)
        archiveButton.setImage(UIImage(named: "archiveIcon"), for: .normal)
        archiveButton.frame = CGRect(x: 0.0, y: 0.0, width: 25, height: 25)
        archiveButton.translatesAutoresizingMaskIntoConstraints = false
        archiveButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        archiveButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        archiveButton.imageView?.contentMode = .scaleAspectFit
        archiveButton.addTarget(self, action: #selector(archiveButtonPressed), for: .touchUpInside)//button:)), for: .touchUpInside)
        //archiveButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 100, bottom: 0, right: 0)
        let archiveBarButton = UIBarButtonItem(customView: archiveButton)
        
        let fixedSpaceLeft = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        let fixedSpaceRight = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        fixedSpaceLeft.width = 60
        fixedSpaceRight.width = 60
        navigationItem.leftBarButtonItems = [backBarButton, fixedSpaceLeft, archiveBarButton, fixedSpaceLeft, selectDatabaseButton]
        navigationItem.rightBarButtonItems = [addObservationButton, fixedSpaceRight, self.editBarButton]//, fixedSpaceRight, QRButton]
        self.navigationBar.setItems([navigationItem], animated: false)
        
        self.view.addSubview(self.navigationBar)
    }
    
    // Helper function to create edit button
    func makeEditButton(imageName: String) -> UIButton {
        let editButton = UIButton(type: .custom)
        editButton.setImage(UIImage(named: imageName), for: .normal)
        editButton.frame = CGRect(x: 0.0, y: 0.0, width: 25, height: 25)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        editButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
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
        if let presentingContoller = self.presentingViewController as? SessionViewController {
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
    
    @objc func selectDatabaseButtonPressed() {
        let browserViewController = DatabaseBrowserViewController()
        browserViewController.modalPresentationStyle = .formSheet
        browserViewController.preferredContentSize = CGSize(width: min(self.view.frame.width, 600), height: min(self.view.frame.height, 500))//CGSize.init(width: 600, height: 600)
        
        // Add blurred background from current view
        let popoverFrame = browserViewController.getVisibleFrame()
        let backgroundView = getBlurredSnapshot(frame: popoverFrame, whiteAlpha: 0.3)
        browserViewController.view.addSubview(backgroundView)
        browserViewController.view.sendSubview(toBack: backgroundView)
        
        present(browserViewController, animated: true, completion: nil)
    }
    
    
    // Return a blurred image of all currently visible views
    func getBlurredSnapshot(frame: CGRect, whiteAlpha: CGFloat = 0) -> UIImageView {
        
        //add blur temporarily
        addBlur()
        
        // Get image of all currently visible views
        let backgroundView = UIImageView(image: self.view.takeSnapshot())
        
        // remove blurview
        self.blurEffectView.removeFromSuperview()
        
        // Since a .formSheet modal presentation will show the image in the upper left corner of the frame, offset the frame so it displays in the right place
        backgroundView.contentMode = .scaleAspectFill
        let currentFrame = self.view.frame
        backgroundView.frame = CGRect(x: currentFrame.minX - frame.minX, y: currentFrame.minY - frame.minY, width: currentFrame.width, height: currentFrame.height)
        
        // Add translucent white
        if whiteAlpha > 0 {
            let translucentWhite = UIView(frame: backgroundView.frame)
            translucentWhite.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: whiteAlpha)
            backgroundView.addSubview(translucentWhite)
        }
        
        return backgroundView
    }
    
    
    @objc func archiveButtonPressed(button: UIBarButtonItem){
        
        let popoverController = ArchivePopoverViewController()
        popoverController.modalPresentationStyle = .formSheet
        popoverController.preferredContentSize = CGSize(width: min(self.view.frame.width, 450.0), height: min(self.view.frame.height, 350.0))//CGSize.init(width: 600, height: 600)
        
        // Add blurred background from current view
        let popoverFrame = popoverController.getVisibleFrame()
        let backgroundView = getBlurredSnapshot(frame: popoverFrame, whiteAlpha: 0.3)
        popoverController.view.addSubview(backgroundView)
        popoverController.view.sendSubview(toBack: backgroundView)
        
        present(popoverController, animated: true, completion: nil)
        
    }
    
    func makeBlurView() -> UIVisualEffectView {
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        //blurEffectView.frame = frame
        //blurEffectView.layer.cornerRadius = messageView.layer.cornerRadius
        //blurEffectView.layer.masksToBounds = true
        
        return blurEffectView
    }
    
    func addBlur() {
        // Only apply the blur if the user hasn't disabled transparency effects
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            self.view.backgroundColor = .clear
            
            let blurEffect = UIBlurEffect(style: .regular)
            self.blurEffectView = UIVisualEffectView(effect: blurEffect)
            
            //always fill the view
            self.blurEffectView.frame = self.view.frame//bounds
            self.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            self.view.addSubview(self.blurEffectView)
            
        } else {
            // ************ Might need to make a dummy blur effect so that removeFromSuperview() in AddObservationMenu transition doesn't choke
            self.view.backgroundColor = .black
        }
    }
    
    
    @objc func addButtonPressed(){
        
        // Cancel editing
        if self.isEditingTable {
            self.tableView.isEditing = false
            self.isEditingTable = false
            let editButton = makeEditButton(imageName: "deleteIcon")
            self.editBarButton.customView = editButton
        }
        
        // Add blurEffectView here because if it's added in AddObservationViewController,
        //  it will be presented modally with the menu. Adding it to this controller makes
        //  it appear visually between the two controllers, rather than sliding up from the
        //  bottom of the screen with the menu
        addBlur()
        
        let menuController = AddObservationViewController()
        menuController.modalPresentationStyle = .overCurrentContext
        menuController.modalTransitionStyle = .coverVertical
        present(menuController, animated: true, completion: nil)
    }
    
    
    //MARK: - TableView methods
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
        //let cellIdentifier = "cell"
        
        /*guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ObservationTableViewCell else {
         fatalError("The dequeued cell is not an instance of ObservationTableViewCell.")
         }*/
        
        // Fetch the right observation for the data source layout
        //let observation = observations[indexPath.row]

        let index = self.cellOrder[indexPath.row]
        let observationCell = observationCells[index]!
        let observation = observationCell.observation
        let imageName = (icons[observationCell.observationType]?.normal)!
        
        //cell.driverLabel.text = observation.driverName
        /*cell.destinationLabel.text = {
            let destination = observation.destination
            if destination.replacingOccurrences(of: " ", with: "").isEmpty {
                return "N/A"
            } else {
                return destination
            }
        }()*/
        cell.centerLabel.text = observationCell.label2
        let observationType = self.cellLabelColumns[observationCell.observationType]!
        let label2IconName = "\(observationType.label2)Icon"
        cell.centerIcon.image = UIImage(named: label2IconName)
        /*let destination = observation.destination
        if destination.replacingOccurrences(of: " ", with: "").isEmpty {
            cell.destinationLabel.text =  "N/A"
        } else {
            cell.destinationLabel.text = destination
        }*/
        cell.datetimeLabel.text = "\(observation.date) \(observation.time)"
        cell.rightLabel.text = observationCell.label3//observation.nPassengers
        let label3IconName = "\(observationType.label3)Icon"
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
        
        let index = self.cellOrder[indexPath.row]
        let thisObservation = (self.observationCells[index]?.observation)!
        let observationType = (self.observationCells[index]?.observationType)!
        /*let tableName = (self.icons[observationType]?.tableName)!
        let observationClassName = (self.icons[observationType]?.dataClassName)!*/
        
        let observationViewController = self.observationViewControllers[observationType]!
        observationViewController.observationId = thisObservation.id
        observationViewController.title = observationType
        
        observationViewController.isAddingNewObservation = false
        // post notification to pass observation to the view controller
        //NotificationCenter.default.post(name: Notification.Name("updatingObservation"), object: observations[indexPath.row])
        
        observationViewController.modalPresentationStyle = .custom
        observationViewController.transitioningDelegate = self
        
        // Set the transition. When done transitioning, reset presentTransition to nil
        self.presentTransition = RightToLeftTransition()
        present(observationViewController, animated: true, completion: {[weak self] in self?.presentTransition = nil})
    }
    
    
    // Enable editing
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            //let id = observations[indexPath.row].id
            let index = self.cellOrder[indexPath.row]
            let thisCell = self.observationCells[index]!
            let id = thisCell.observation.id
            let observationType = thisCell.observationType
            let tableName = (icons[observationType]?.tableName)!
            let table = Table(tableName)
            print("Deleting \(id) from \(tableName)")
            
            let recordToRemove = table.where(idColumn == id.datatypeValue)
            observationCells.removeValue(forKey: index)
            
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
            //**** Change title of nav bar *********
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
            var rows: [Row]
            
            do {
                rows = Array(try db.prepare(table))
            } catch {
                fatalError("Could not load observations: \(error.localizedDescription)")
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
                if (label == "Bus" && lodges.contains(row[label2Column])) || (label == "Lodge Bus" && !lodges.contains(row[label2Column])) {
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
                    fatalError("Could not interpret datetimeString: \(datetimeString)")
                }
                datetimeStamps[i] = datetime
                self.observationCells[i] = observationCell
                loadedObservations.append(observation!)
                i += 1
            }
            
        }
        
        // Get the indices sorted by datetime
        self.cellOrder.removeAll()
        let sortedStamps = datetimeStamps.sorted{$0.value < $1.value}
        for (index, _) in sortedStamps {
            self.cellOrder.append(index)
        }
        
        self.observations = loadedObservations
        
    }
    
    func loadSession() throws { //}-> Session?{
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
