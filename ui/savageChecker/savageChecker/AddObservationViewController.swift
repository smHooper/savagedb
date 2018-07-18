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

class AddObservationViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    let minSpacing = 50.0
    let menuPadding = 50.0
    var buttons = [VehicleButtonControl]()
    var presentTransition: UIViewControllerAnimatedTransitioning?
    var dismissTransition: UIViewControllerAnimatedTransitioning?
    var scrollView: UIScrollView!
    var blurEffectView: UIVisualEffectView!
    
    var icons: DictionaryLiteral = ["Bus": "busIcon",
                                    "NPS Vehicle": "npsVehicleIcon",
                                    "NPS Approved": "npsApprovedIcon",
                                    "NPS Contractor": "npsContractorIcon",
                                    "Employee": "employeeIcon",
                                    "Right of Way": "rightOfWayIcon",
                                    "Tek Camper": "tekCamperIcon",
                                    "Bicycle": "cyclistIcon",
                                    "Propho": "photographerIcon",
                                    "Accessibility": "accessibilityIcon",
                                    "Hunter": "hunterIcon",
                                    "Road lottery": "busIcon",
                                    "Other": "otherIcon"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add blur effect
        //addBlur()
        
        // Add make buttons to arrange
        for (offset: index, (key: labelText, value: iconName)) in self.icons.enumerated() {
            let thisButton = VehicleButtonControl()
            thisButton.setupButtonLayout(imageName: iconName, labelText: labelText, tag: index)
            thisButton.tag = -1//index
            thisButton.button.addTarget(self, action: #selector(AddObservationViewController.moveToObservationViewController(button:)), for: .touchUpInside)
            self.buttons.append(thisButton)
        }
        
        // Arrange them
        setupMenuLayout()
        
        // If someone taps outside the buttons, dismiss the menu
        dismissWhenTappedAround()
        
        self.scrollView.setContentOffset(CGPoint(x: 0, y: -self.scrollView.adjustedContentInset.top), animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Redo the layout when rotated
    //override func viewDidLayoutSubviews() {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        //super.viewDidLayoutSubviews()
        
        // Add the blur effect for the rotated view
        let presentingController = self.presentingViewController as! BaseTableViewController
        presentingController.blurEffectView.removeFromSuperview()
        presentingController.addBlur()//*/
        /*for button in self.buttons {
            button.removeFromSuperview()
        }
        
        addBlur()*/
        
        // Redo the menu
        setupMenuLayout()
        self.view.backgroundColor = UIColor.clear
    }
    
    
    //MARK: Private methods
    private func setupMenuLayout(){
        
        // Figure out how many buttons fit in one row
        let viewWidth = self.view.frame.width
        let menuWidth = Double(viewWidth) - self.menuPadding * 2
        let nPerRow = floor((menuWidth + self.minSpacing) / (VehicleButtonControl.width + self.minSpacing))
        let nRows = Int(ceil(Double(buttons.count) / nPerRow))
        //let menuWidth = nRows * VehicleButtonControl.width + ((nRows - 1) * self.minSpacing)
        
        // Figure out if there are too many rows to fit in the window. If so, put all of the buttons in a scrollview
        let viewHeight = self.view.frame.height
        let menuHeight = Double(viewHeight) - menuPadding * 2//nRows * (VehicleButtonControl.height + self.minSpacing) + self.minSpacing
        /*if Double(viewHeight) < menuHeight {
            // Put it in a scrollview
            
        }*/
        self.scrollView = UIScrollView()
        self.scrollView.showsVerticalScrollIndicator = false
        self.view.addSubview(self.scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        /*self.scrollView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.scrollView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.scrollView.widthAnchor.constraint(equalToConstant: CGFloat(menuWidth)).isActive = true
        self.scrollView.heightAnchor.constraint(equalToConstant:CGFloat(menuHeight)).isActive = true*/
        self.scrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: CGFloat(self.menuPadding)).isActive = true
        self.scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: CGFloat(-self.menuPadding)).isActive = true
        self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: CGFloat(self.menuPadding)).isActive = true
        self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: CGFloat(-self.menuPadding)).isActive = true
        
        // Set up the container
        let container = UIView()
        //container.backgroundColor = UIColor.blue
        /*self.view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        container.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        container.widthAnchor.constraint(equalToConstant: CGFloat(menuWidth)).isActive = true
        container.heightAnchor.constraint(equalToConstant:CGFloat(menuHeight)).isActive = true*/
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
    
    // MARK: - Navigation
    
    @objc func moveToObservationViewController(button: UIButton){
        let session = loadSession()
        let labelText = icons[button.tag].key
        let types = ["Bus": BusObservationViewController.self,
                     "NPS Vehicle": NPSVehicleObservationViewController.self,
                     "NPS Approved": NPSApprovedObservationViewController.self,
                     "NPS Contractor": NPSContractorObservationViewController.self,
                     "Employee": EmployeeObservationViewController.self,
                     "Right of Way": RightOfWayObservationViewController.self,
                     "Tek Camper": TeklanikaCamperObservationViewController.self,
                     "Bicycle": CyclistObservationViewController.self,
                     "Propho": PhotographerObservationViewController.self,
                     "Accessibility": AccessibilityObservationViewController.self,
                     "Hunter": HunterObservationViewController.self,
                     "Other": OtherObservationViewController.self]
        
        // Remove the blur effect
        animateRemoveMenu()
        
        let viewController = types[labelText]!.init()
        viewController.isAddingNewObservation = true
        viewController.session = session
        viewController.transitioningDelegate = self
        viewController.modalPresentationStyle = .custom
        self.presentTransition = RightToLeftTransition()
        present(viewController, animated: true, completion: {viewController.presentTransition = nil})
        
    }
    
    func dismissWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
        self.view.addGestureRecognizer(tap)
    }
    
    func addBlur() {
        
        //Remove the blur if it exists
        if let blurView = self.blurEffectView {
            self.blurEffectView.removeFromSuperview()
        }
        
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
    
    func animateRemoveMenu(duration: CGFloat = 0.75) {
        let presentingController = presentingViewController as! BaseTableViewController
        UIView.animate(withDuration: 0.75,
                       animations: {presentingController.blurEffectView.alpha = 0.0},//{self.blurEffectView.alpha = 0.0},//
                       completion: {(value: Bool) in presentingController.blurEffectView.removeFromSuperview()})//self.blurEffectView.removeFromSuperview()})//
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        // Check if the touch was on one of the buttons
        for button in self.buttons {
            if touch.view == button {
                return false
            }
        }
        // If not, the touch should get passed to the gesture recognizer
        return true
    }
    
    @objc func dismissMenu(){
        print("tapped around")
        dismiss(animated: true, completion: nil)
        animateRemoveMenu(duration: 0.25)
    }
    
    
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



