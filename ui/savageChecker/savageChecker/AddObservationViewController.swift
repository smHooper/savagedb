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
import GoogleSignIn

class AddObservationViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate{//}, GIDSignInUIDelegate {
    
    let minSpacing = 50.0
    let menuPadding = 50.0
    let navigationButtonSize: CGFloat = 35
    var buttons = [VehicleButtonControl]()
    var presentTransition: UIViewControllerAnimatedTransitioning?
    var dismissTransition: UIViewControllerAnimatedTransitioning?
    var scrollView: UIScrollView!
    var navigationBar: CustomNavigationBar!
    var blurEffectView: UIVisualEffectView!
    var messageView: UITextView!
    var messageViewBackground: UIVisualEffectView!
    var blurredBackground: UIImageView!
    
    //MARK: data model properties
    var db: Connection!
    var userData: UserData?
    var userDataLoaded = false
    
    var icons: DictionaryLiteral = ["Bus": "busIcon",
                                    "Lodge Bus": "lodgeBusIcon",
                                    "NPS Vehicle": "npsVehicleIcon",
                                    "NPS Approved": "npsApprovedIcon",
                                    "NPS Contractor": "npsContractorIcon",
                                    "Employee": "employeeIcon",
                                    "Right of Way": "rightOfWayIcon",
                                    "Tek Camper": "tekCamperIcon",
                                    "Bicycle": "cyclistIcon",
                                    "Propho": "photographerIcon",
                                    "Accessibility": "accessibilityIcon",
                                    "Subsistence": "subsistenceIcon",
                                    "Road Lottery": "roadLotteryIcon",
                                    "Other": "otherIcon"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Try to load the database, but if userData has not been created yet, open the ShiftInfo controller
        //loadData()
        
        addBackground()
        
        setNavigationBar()
        
        // Make buttons to arrange
        for (offset: index, (key: labelText, value: iconName)) in self.icons.enumerated() {
            let thisButton = VehicleButtonControl()
            thisButton.setupButtonLayout(imageName: iconName, labelText: labelText, tag: index)
            thisButton.tag = -1//index
            thisButton.button.addTarget(self, action: #selector(AddObservationViewController.moveToObservationViewController(button:)), for: .touchUpInside)
            self.buttons.append(thisButton)
        }
        
        // Arrange the buttons
        setupMenuLayout()
        
        // Because scrollView and container are centered in setupMenuLayout(),
        //  scroll position is in the middle of the view when first loaded
        setScrollViewPositionToTop()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(cancelAnimation))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        // Change this to use some var or notification to check if I should show quote or just loadData()
        showQuote(seconds: 5.0)
    }
    

    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        // If userData isn't nil, then it's already been loaded in viewDidLoad()
        if !userDataLoaded {
            
            // Flash scroll indicators so user knows they can scroll. Should only flash if content goes off screen.
            self.scrollView.flashScrollIndicators()
            
            loadData()
        }
    }
    
    func showQuote(seconds: Double) {
        
        // Will get loaded after animation is finished, but this must be set before viewDidAppear() is called,
        //  which happens before the animation is done
        self.userDataLoaded = true
        
        let borderSpacing: CGFloat = 16
        let randomIndex = Int(arc4random_uniform(UInt32(launchScreenQuotes.count)))
        let randomQuote = launchScreenQuotes[randomIndex]
        
        let screenBounds = UIScreen.main.bounds
        
        // Configure the message
        let messageViewWidth = min(screenBounds.width, 450)
        let font = UIFont.systemFont(ofSize: 18)
        let messageHeight = randomQuote.height(withConstrainedWidth: messageViewWidth - borderSpacing * 2, font: font)
        let messageFrame = CGRect(x: screenBounds.width/2 - messageViewWidth/2, y: screenBounds.height/2 - (messageHeight/2 + borderSpacing), width: messageViewWidth, height: messageHeight + borderSpacing * 2)
        self.messageView = UITextView(frame: messageFrame)
        self.messageView.font = font
        self.messageView.layer.cornerRadius = 25
        self.messageView.layer.borderColor = UIColor.clear.cgColor
        self.messageView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        self.messageView.textContainerInset = UIEdgeInsets(top: borderSpacing, left: borderSpacing, bottom: borderSpacing, right: borderSpacing)
        self.messageView.text = randomQuote
        let blurEffect = UIBlurEffect(style: .light)
        self.messageViewBackground = UIVisualEffectView(effect: blurEffect)
        self.messageViewBackground.frame = messageFrame
        self.messageViewBackground.layer.cornerRadius = self.messageView.layer.cornerRadius
        self.messageViewBackground.layer.masksToBounds = true
        self.messageView.addSubview(self.messageViewBackground)
        //self.messageView.sendSubview(toBack: self.messageViewBackground)
        
        // Add the message view with the background
        let screenView = UIImageView(frame: screenBounds)
        screenView.image = UIImage(named: "viewControllerBackground")
        screenView.contentMode = .scaleAspectFill
        screenView.addSubview(self.messageViewBackground)
        screenView.addSubview(self.messageView)
        self.view.addSubview(screenView)
        
        // Set up the false background that's identical to the viewController's background so it looks like all of the view controller elements fade into view
        self.blurredBackground = UIImageView(frame: screenView.frame)//image:
        self.blurredBackground.image = UIImage(named: "viewControllerBackgroundBlurred")
        self.blurredBackground.alpha = 0.0
        let translucentWhite = UIView(frame: screenView.frame)
        translucentWhite.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        self.blurredBackground.addSubview(translucentWhite)
        self.view.addSubview(self.blurredBackground)
        
        let quoteTimeSeconds = min(7, max(Double(randomQuote.count)/200 * 5, 3))
        
        // Add acticity indicator so it looks like things are loading
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.center = CGPoint(x: self.view.center.x, y: self.messageView.frame.maxY + (self.view.frame.height - self.messageView.frame.maxY)/2)
        self.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + quoteTimeSeconds + 0.5) {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
        
        // First, animate the messageView disappearing (it appears with crossfade automatically
        UIView.animate(withDuration: 0.75, delay: quoteTimeSeconds, animations: { self.messageView.alpha = 0.0; self.messageViewBackground.alpha = 0.0}, completion: {_ in
            self.messageView.removeFromSuperview()
            // Next, animate the blurred background appearing
            UIView.animate(withDuration: 0.75, delay: 0.2, animations: {self.blurredBackground.alpha = 1.0}, completion: {_ in
                screenView.removeFromSuperview()
                // Finally, make the blurred background disappear. Because it's just a crossfade, it looks like the screen elements are the ones fading into view.
                UIView.animate(withDuration: 0.5, animations: {self.blurredBackground.alpha = 0.0}, completion: {_ in
                    self.blurredBackground.removeFromSuperview()
                    self.loadData()
                    self.scrollView.flashScrollIndicators()
                })
            })
        })
        
    }
    
    // Cancel animation (to be used with swipe gesture)
    @objc func cancelAnimation() {
        self.messageView.layer.removeAllAnimations()
        self.messageViewBackground.layer.removeAllAnimations()
        self.blurredBackground.layer.removeAllAnimations()
        
    }
    
    
    // Redo the layout when rotated
    //override func viewDidLayoutSubviews() {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        addBackground()
        
        // Redo the menu and nav bar
        setupMenuLayout()
        setNavigationBar()
        
        // Reset the scrollView position to 0 if necessary
        setScrollViewPositionToTop()
    }
    
    
    //MARK: Private methods
    private func setupMenuLayout(){
        
        // Figure out how many buttons fit in one row
        let screenSize = UIScreen.main.bounds // This is actually the screen size before rotation
        let isLandscape = UIDevice.current.orientation.isLandscape
        let currentScreenFrame: CGRect = {
            if isLandscape {
                return CGRect(x: 0, y: 0, width: max(screenSize.width, screenSize.height), height: min(screenSize.width, screenSize.height))
            } else {
                return CGRect(x: 0, y: 0, width: min(screenSize.width, screenSize.height), height: max(screenSize.width, screenSize.height))
            }
        }()
        let viewWidth = currentScreenFrame.width
        let menuWidth = Double(viewWidth) - self.menuPadding * 2
        let nPerRow = floor((menuWidth + self.minSpacing) / (VehicleButtonControl.width + self.minSpacing))
        let nRows = Int(ceil(Double(buttons.count) / nPerRow))
        //let menuWidth = nRows * VehicleButtonControl.width + ((nRows - 1) * self.minSpacing)
        
        // Figure out if there are too many rows to fit in the window. If so, put all of the buttons in a scrollview
        let viewHeight = currentScreenFrame.height
        let menuHeight = Double(viewHeight) - menuPadding * 2//nRows * (VehicleButtonControl.height + self.minSpacing) + self.minSpacing

        self.scrollView = UIScrollView()
        self.scrollView.showsVerticalScrollIndicator = false
        self.view.addSubview(self.scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: CGFloat(self.menuPadding)).isActive = true
        self.scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: CGFloat(-self.menuPadding)).isActive = true
        self.scrollView.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor, constant: CGFloat(self.menuPadding/2)).isActive = true
        self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: CGFloat(-self.menuPadding)).isActive = true
        
        // Set up the container
        let container = UIView()
        self.scrollView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        container.topAnchor.constraint(equalTo: self.scrollView.topAnchor).isActive = true
        container.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor).isActive = true
        // Don't set the height until all buttons have been added
        
        // Loop through each row, making a horizontal stack view for each
        var lastBottomAnchor = container.topAnchor
        let menuLeftAnchor = container.leftAnchor
        let menuRightAnchor = container.rightAnchor
        var contentHeight: Double = 0
        for rowIndex in 0..<nRows {
            let stack = UIStackView()
            let startIndex = rowIndex * Int(nPerRow)
            let endIndex = min(startIndex + Int(nPerRow), self.buttons.count)
            var theseButtons = self.buttons[startIndex ..< endIndex]
            
            // Check if the row is full. If not, add clear, dummy buttons
            for _ in 0..<(Int(nPerRow) - theseButtons.count){
                let button = UIButton()
                button.backgroundColor = UIColor.clear
                button.frame = self.buttons.first!.frame
                let vehicleButton = VehicleButtonControl()
                vehicleButton.button = button
                theseButtons.append(vehicleButton)
            }
            
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
            
            stack.leftAnchor.constraint(equalTo: menuLeftAnchor).isActive = true
            stack.rightAnchor.constraint(equalTo: menuRightAnchor).isActive = true
            lastBottomAnchor = stack.bottomAnchor
        }
        
        container.bottomAnchor.constraint(equalTo: lastBottomAnchor).isActive = true
        contentHeight = (self.buttons[0].height + self.minSpacing) * Double(nRows) - self.minSpacing
        self.scrollView.contentSize = CGSize(width: menuWidth, height: contentHeight)
        
    }

    
    // MARK:  - Scrollview Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
    }
    
    func setScrollViewPositionToTop() {
        var offset = CGPoint(x: -self.scrollView.contentInset.left,
                             y: -scrollView.contentInset.top)
        
        if #available(iOS 11.0, *) {
            offset = CGPoint(x: -self.scrollView.adjustedContentInset.left,
                             y: -scrollView.adjustedContentInset.top)
        }
        
        self.scrollView.setContentOffset(offset, animated: true)
    }
    
    // MARK: - Navigation
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
        
        let obsListButton = UIButton(type: .custom)
        obsListButton.setImage(UIImage (named: "observationListIcon"), for: .normal)
        obsListButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        obsListButton.addTarget(self, action: #selector(dismissMenu), for: .touchUpInside)
        obsListButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        obsListButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        let observationListButton = UIBarButtonItem(customView: obsListButton)
        
        let shiftButton = UIButton(type: .custom)
        shiftButton.setImage(UIImage(named: "shiftInfoIcon"), for: .normal)
        shiftButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        shiftButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        shiftButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        shiftButton.addTarget(self, action: #selector(editShiftInfoButtonPressed), for: .touchUpInside)
        let shiftBarButton = UIBarButtonItem(customView: shiftButton)
        
        let navigationItem = UINavigationItem(title: "Enter a new observation")
        
        let qrButton = UIButton(type: .custom)
        qrButton.setImage(UIImage (named: "scanQRIcon"), for: .normal)
        qrButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        qrButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        qrButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        qrButton.addTarget(self, action: #selector(qrButtonPressed), for: .touchUpInside)
        let qrBarButton = UIBarButtonItem(customView: qrButton)
        
        // Add a button for switching the active database file
        let databaseButton = UIButton(type: .custom)
        databaseButton.setImage(UIImage(named: "switchDatabaseIcon"), for: .normal)
        databaseButton.frame = CGRect(x: 0.0, y: 0.0, width: navigationButtonSize, height: navigationButtonSize)
        databaseButton.translatesAutoresizingMaskIntoConstraints = false
        databaseButton.widthAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        databaseButton.heightAnchor.constraint(equalToConstant: navigationButtonSize).isActive = true
        databaseButton.imageView?.contentMode = .scaleAspectFit
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
        googleDriveButton.imageView?.contentMode = .scaleAspectFit
        googleDriveButton.addTarget(self, action: #selector(googleDriveButtonPressed), for: .touchUpInside)
        let googleDriveBarButton = UIBarButtonItem(customView: googleDriveButton)
        
        
        let fixedSpaceLeft = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        let fixedSpaceRight = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        fixedSpaceLeft.width = 50
        fixedSpaceRight.width = 50
        navigationItem.leftBarButtonItems = [selectDatabaseButton, fixedSpaceLeft, googleDriveBarButton]
        navigationItem.rightBarButtonItems = [shiftBarButton, fixedSpaceRight, qrBarButton, fixedSpaceRight, observationListButton]
        self.navigationBar.setItems([navigationItem], animated: false)
        
        self.view.addSubview(self.navigationBar)
    }
    
    
    @objc func qrButtonPressed(){
        let scannerController = ScannerViewController()
        present(scannerController, animated: true)
    }
    
    func prepareDatabaseBrowserViewController() -> DatabaseBrowserViewController {
        let browserViewController = DatabaseBrowserViewController()
        browserViewController.modalPresentationStyle = .formSheet
        browserViewController.preferredContentSize = CGSize(width: min(self.view.frame.width, 600), height: min(self.view.frame.height, 500))//CGSize.init(width: 600, height: 600)
        
        // Add blurred background from current view
        let popoverFrame = browserViewController.getVisibleFrame()
        let backgroundView = getBlurredSnapshot(frame: popoverFrame)
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
            uploadViewController.preferredContentSize = CGSize(width: min(self.view.frame.width, 600), height: min(self.view.frame.height, 400))
            
            // Add blurred background from current view
            let popoverFrame = uploadViewController.getVisibleFrame()
            let backgroundView = getBlurredSnapshot(frame: popoverFrame)
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
    
    
    func getImage(from view:UIView) -> UIImage? {
        defer {
            UIGraphicsEndImageContext()
        }
        
        /*let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        let navigationBarHeight = self.navigationBar.frame.height
        let barSize = CGSize(width: self.view.frame.width, height: statusBarHeight + navigationBarHeight)*/
        
        UIGraphicsBeginImageContextWithOptions(self.view.frame.size, true, UIScreen.main.scale)
        guard let context =  UIGraphicsGetCurrentContext() else {
            return nil
        }
        self.view.layer.render(in: context)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    @objc func moveToObservationViewController(button: UIButton){
        let session = loadSession()
        let labelText = icons[button.tag].key
        let types = ["Bus": BusObservationViewController.self,
                     "Lodge Bus": LodgeBusObservationViewController.self,
                     "NPS Vehicle": NPSVehicleObservationViewController.self,
                     "NPS Approved": NPSApprovedObservationViewController.self,
                     "NPS Contractor": NPSContractorObservationViewController.self,
                     "Employee": EmployeeObservationViewController.self,
                     "Right of Way": RightOfWayObservationViewController.self,
                     "Tek Camper": TeklanikaCamperObservationViewController.self,
                     "Bicycle": CyclistObservationViewController.self,
                     "Propho": PhotographerObservationViewController.self,
                     "Accessibility": AccessibilityObservationViewController.self,
                     "Subsistence": SubsistenceObservationViewController.self,
                     "Road Lottery": RoadLotteryObservationViewController.self,
                     "Other": OtherObservationViewController.self]
        
        // Remove the blur effect
        //animateRemoveMenu()
        
        let viewController = types[labelText]!.init()
        viewController.isAddingNewObservation = true
        viewController.session = session
        viewController.title = "New \(labelText) Observation"
        viewController.transitioningDelegate = self
        viewController.modalPresentationStyle = .custom
        self.presentTransition = RightToLeftTransition()
        present(viewController, animated: true, completion: {viewController.presentTransition = nil})
        
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
    
    func prepareShiftInfoController() -> ShiftInfoViewController {
        let shiftViewController = ShiftInfoViewController()
        shiftViewController.modalPresentationStyle = .formSheet
        shiftViewController.preferredContentSize = CGSize(width: min(self.view.frame.width, 400), height: min(self.view.frame.height, 600))//CGSize.init(width: 600, height: 600)
        
        // Add blurred background from current view
        let popoverFrame = shiftViewController.getVisibleFrame()
        let backgroundView = getBlurredSnapshot(frame: popoverFrame)
        shiftViewController.view.addSubview(backgroundView)
        shiftViewController.view.sendSubview(toBack: backgroundView)
        
        return shiftViewController
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
    
    
    func showShiftInfoForm() {
        let shiftViewController = prepareShiftInfoController()
        present(shiftViewController, animated: true, completion: nil)
    }
    
    @objc func editShiftInfoButtonPressed() {
        showShiftInfoForm()
    }
    
    
    
    func dismissWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
        self.view.addGestureRecognizer(tap)
    }
    
    
    func animateRemoveMenu(duration: CGFloat = 0.75) {
        let presentingController = presentingViewController as! BaseTableViewController
        UIView.animate(withDuration: 0.75,
                       animations: {presentingController.blurEffectView.alpha = 0.0},//{self.blurEffectView.alpha = 0.0},//
                       completion: {(value: Bool) in presentingController.blurEffectView.removeFromSuperview()})//self.blurEffectView.removeFromSuperview()})//
    }
    
    
    /*func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        // Check if the touch was on one of the buttons
        for button in self.buttons {
            if touch.view == button {
                return false
            }
        }
        // If not, the touch should get passed to the gesture recognizer
        return true
    }*/
    
    @objc func dismissMenu(){
        let tableViewController = BaseTableViewController()
        tableViewController.loadData()
        tableViewController.transitioningDelegate = self
        tableViewController.modalPresentationStyle = .custom
        self.presentTransition = RightToLeftTransition()
        present(tableViewController, animated: true, completion: {tableViewController.presentTransition = nil})
    }
    
    //MARK: Data model
    func loadData() {
        // First check if there's user data from a previous session
        if let userData = loadUserData() {
            dbPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(userData.activeDatabase).path
            self.userData = userData
            self.userDataLoaded = true
        } else {
            self.userDataLoaded = false
            showShiftInfoForm()
        }
    }
    
    func loadSession() -> Session? {
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
            print("problem getting session rows: \(error.localizedDescription)")
        }
        if rows.count > 1 {
            os_log("Multiple sessions found", log: OSLog.default, type: .debug)
        }
        
        var session: Session?
        for row in rows{
            session = Session(id: Int(row[idColumn]), observerName: row[observerNameColumn], openTime:row[openTimeColumn], closeTime: row[closeTimeColumn], givenDate: row[dateColumn])
        }
        
        return session
    }

}



