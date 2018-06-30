//
//  TableViewToolBar.swift
//  savageChecker
//
//  Created by Sam Hooper on 6/28/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit

class TableViewToolBar: UIToolbar {
    
    //MARK: Properties
    let barButtonSize: CGFloat = 80
    let barHeight: CGFloat = 120
    var currentGroup = 0
    var buttons = [UIBarButtonItem]()
    let icons = [(label: "Bus", normal: "busIcon", selected: "shuttleBusImg", tableName: "buses", dataClassName: "BusObservation"),
                 (label: "NPS Vehicle", normal: "npsVehicleIcon", selected: "shuttleBusImg", tableName: "npsVehicles", dataClassName: "NPSVehicleObservation"),
                 (label: "NPS Approved", normal: "npsApprovedIcon", selected: "shuttleBusImg", tableName: "npsApproved", dataClassName: "NPSApprovedObservation"),
                 (label: "NPS Contractor", normal: "npsContractorIcon", selected: "shuttleBusImg", tableName: "npsContractors", dataClassName: "NPSContractorObservation"),
                 (label: "Employee", normal: "employeeIcon", selected: "shuttleBusImg", tableName: "employees", dataClassName: "EmployeeObservation"),
                 (label: "Right of Way", normal: "rightOfWayIcon", selected: "shuttleBusImg", tableName: "rightOfWay", dataClassName: "RightOfWayObservation"),
                 (label: "Tek Camper", normal: "tekCamperIcon", selected: "shuttleBusImg", tableName: "tekCampers", dataClassName: "TeklanikaCamperObservation"),
                 (label: "Bicycle", normal: "cyclistIcon", selected: "shuttleBusImg", tableName: "cyclists", dataClassName: "Observation"),
                 (label: "Propho", normal: "busIcon", selected: "shuttleBusImg", tableName: "photographers", dataClassName: "PhotographerObservation"),
                 (label: "Accessibility", normal: "busIcon", selected: "shuttleBusImg", tableName: "accessibility", dataClassName: "AccessibilityObservation"),
                 (label: "Hunting", normal: "busIcon", selected: "shuttleBusImg", tableName: "hunters", dataClassName: "Observation"),
                 (label: "Road lottery", normal: "busIcon", selected: "shuttleBusImg", tableName: "roadLottery", dataClassName: "Observation"),
                 (label: "Other", normal: "busIcon", selected: "shuttleBusImg", tableName: "other", dataClassName: "Observation")]
    
    //MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    //MARK: Layout
    func setupBarLayout(){
        
        let screenSize: CGRect = UIScreen.main.bounds
        self.frame = CGRect(x: 0, y: screenSize.height - self.barHeight, width: screenSize.width, height: self.barHeight)
        //self.layer.position = CGPoint(x: screenSize.width/2, y: self.barHeight)
        
        //figure out how many buttons per group
        
        for i in 0..<icons.count {
            let thisIcon = icons[i]
            
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: thisIcon.normal), for: .normal)
            //button.setBackgroundImage(image: normalBackGroundImage, for: .normal)
            //button.setBackgroundImage(image: selectedBackGroundImage, for: .selected)
            button.frame = CGRect(x: 0.0, y: 0.0, width: self.barButtonSize, height: self.barButtonSize)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: self.barButtonSize).isActive = true
            button.heightAnchor.constraint(equalToConstant: self.barButtonSize).isActive = true
            button.imageView?.contentMode = .scaleAspectFit
            
            let barButton = UIBarButtonItem(customView: button)
            
            
        }
    }
    
    
}
