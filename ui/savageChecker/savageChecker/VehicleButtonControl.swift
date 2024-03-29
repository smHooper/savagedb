//
//  VehicleButtonViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/29/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit

@IBDesignable class VehicleButtonControl: UIStackView {
    
    //var image: UIImage?
    //var labelText: String?
    static let width = 150.0
    var height = 158.0 // Changes depending on text in label
    var buttonSize = 120.0
    var labelText: String?
    var button = UIButton()
    
    //MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    //MARK: Private methods
    func setupButtonLayout(imageName: String, labelText: String, tag: Int = 0) {
        let button = UIButton()
        button.tag = tag
        
        // Add the button with constraints
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: CGFloat(self.buttonSize)).isActive = true
        button.widthAnchor.constraint(equalToConstant: CGFloat(self.buttonSize)).isActive = true
        
        // Add image
        let bundle = Bundle(for: type(of: self))
        let image = UIImage(named: imageName, in: bundle, compatibleWith: self.traitCollection)
        button.setImage(image, for: .normal)
        self.button = button
        addArrangedSubview(self.button)
        
        // Add a label
        let label = UILabel()
        label.text = labelText
        self.labelText = labelText
        label.font = UIFont.systemFont(ofSize: 25.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.textColor = UIColor.black
        addArrangedSubview(label)
        
        self.spacing = 8.0
        self.axis = .vertical
        self.alignment = .center
        
        let font = label.font
        let fontAttributes = [NSAttributedStringKey.font: font]
        let fontSize = (labelText as NSString).size(withAttributes: fontAttributes)
        self.height = self.buttonSize + Double(self.spacing) + Double(fontSize.height)
    }

}
