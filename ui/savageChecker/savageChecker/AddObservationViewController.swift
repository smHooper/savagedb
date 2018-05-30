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
    var buttons = [VehicleButtonViewControl]()
    
    var icons: DictionaryLiteral = ["JV Bus": "busIcon",
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
                                    "Other": "busIcon"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add make buttons to arrange
        for (vehicle, iconName) in self.icons {
            let thisButton = VehicleButtonViewControl()
            thisButton.setupButtonLayout(imageName: iconName, labelText: vehicle)
            buttons.append(thisButton)
        }
        
        // Arrange them
        setupMenuLayout()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupMenuLayout(){
        
        // Figure out how many buttons fit in one row
        let viewWidth = self.view.frame.width
        let menuWidth = Double(viewWidth) - menuPadding * 2
        let nPerRow = floor((menuWidth + self.minSpacing) / (VehicleButtonViewControl.width + self.minSpacing)) // this doesn't work quite right because
        let nRows = Int(ceil(Double(buttons.count) / nPerRow))
        //let menuWidth = nRows * VehicleButtonViewControl.width + ((nRows - 1) * self.minSpacing)
        
        // Figure out if there are too many rows to fit in the window. If so, put all of the buttons in a scrollview
        let viewHeight = self.view.frame.height
        let menuHeight = Double(viewHeight) - menuPadding * 2//nRows * (VehicleButtonViewControl.height + self.minSpacing) + self.minSpacing
        if Double(viewHeight) < menuHeight {
            // Put it in a scrollview
        }
        
        // Set up the container
        let container = UIView()
        self.view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.centerXAnchor.constraint(lessThanOrEqualTo: self.view.centerXAnchor, constant: CGFloat(self.menuPadding)).isActive = true
        container.centerYAnchor.constraint(lessThanOrEqualTo: self.view.centerYAnchor, constant: CGFloat(self.menuPadding)).isActive = true
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
            stack.alignment = .leading
            container.addSubview(stack)
            
            // Set up constraints for the stack view
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.topAnchor.constraint(lessThanOrEqualTo: lastBottomAnchor, constant: stack.spacing).isActive = true
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
