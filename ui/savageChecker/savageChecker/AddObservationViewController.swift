//
//  AddObservationViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/29/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit

class AddObservationViewController: UIViewController {
    
    let minSpacing = 50.0
    let menuPadding = 50.0
    var buttons = [VehicleButtonControl]()
    
    /*var icons: DictionaryLiteral = ["JV Bus": "busIcon",
                                    "Lodge Bus": "busIcon",
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
                                    "Other": "busIcon"]*/
    
    let icons = [
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
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add make buttons to arrange
        for (labelText, iconName, function) in self.icons {
            let thisButton = VehicleButtonControl()
            thisButton.setupButtonLayout(imageName: iconName, labelText: labelText)
            buttons.append(thisButton)
        }
        
        // Arrange them
        setupMenuLayout()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}



