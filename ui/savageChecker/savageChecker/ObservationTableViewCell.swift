//
//  ObservationTableViewCell.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit

class BaseObservationTableViewCell: UITableViewCell {
    
    
    let mainIcon = UIImageView()
    /*let driverLabel = UILabel()
    let driverIcon = UIImageView()*/
    let centerLabel = UILabel()
    let centerIcon = UIImageView()
    let datetimeLabel = UILabel()
    let datetimeIcon = UIImageView()
    let rightLabel = UILabel()
    let rightIcon = UIImageView()
    
    let spacing: CGFloat = 16
    let largeTextSize: CGFloat = 24
    let smallTextSize: CGFloat = 20
    let mainIconImageSize: CGFloat = 60
    let smallIconImageSize: CGFloat = 30
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let iconSpacing = (min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - mainIconImageSize - spacing * 2) / 3
        let bundle = Bundle(for: type(of: self))
        mainIcon.image = UIImage(named: "busIcon", in: bundle, compatibleWith: self.traitCollection)
        mainIcon.frame = CGRect(x: 0, y: 0, width: mainIconImageSize, height: mainIconImageSize)
        mainIcon.contentMode = .scaleAspectFit
        
        datetimeIcon.image = UIImage(named: "clockIcon", in: bundle, compatibleWith: self.traitCollection)
        datetimeIcon.contentMode = .scaleAspectFit
        
        centerIcon.image = UIImage(named: "destinationIcon", in: bundle, compatibleWith: self.traitCollection)
        centerIcon.contentMode = .scaleAspectFit
        
        rightIcon.image = UIImage(named: "passengerIcon", in: bundle, compatibleWith: self.traitCollection)
        rightIcon.contentMode = .scaleAspectFit
        
        let contentSafeArea = UIView()
        contentView.addSubview(contentSafeArea)
        contentSafeArea.translatesAutoresizingMaskIntoConstraints = false
        contentSafeArea.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: spacing).isActive = true
        contentSafeArea.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing).isActive = true
        contentSafeArea.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: spacing * -1).isActive = true
        contentSafeArea.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: spacing * -1).isActive = true
        
        contentSafeArea.addSubview(mainIcon)
        //contentSafeArea.addSubview(driverLabel)
        //contentSafeArea.addSubview(driverIcon)
        contentSafeArea.addSubview(centerLabel)
        contentSafeArea.addSubview(centerIcon)
        contentSafeArea.addSubview(datetimeLabel)
        contentSafeArea.addSubview(datetimeIcon)
        contentSafeArea.addSubview(rightLabel)
        contentSafeArea.addSubview(rightIcon)
        
        // Set up constraints
        mainIcon.translatesAutoresizingMaskIntoConstraints = false
        centerLabel.translatesAutoresizingMaskIntoConstraints = false
        centerIcon.translatesAutoresizingMaskIntoConstraints = false
        datetimeLabel.translatesAutoresizingMaskIntoConstraints = false
        datetimeIcon.translatesAutoresizingMaskIntoConstraints = false
        rightLabel.translatesAutoresizingMaskIntoConstraints = false
        rightIcon.translatesAutoresizingMaskIntoConstraints = false
        
        mainIcon.leftAnchor.constraint(equalTo: contentSafeArea.leftAnchor).isActive = true
        mainIcon.topAnchor.constraint(equalTo: contentSafeArea.topAnchor).isActive = true
        mainIcon.heightAnchor.constraint(equalToConstant: mainIconImageSize).isActive = true
        mainIcon.widthAnchor.constraint(equalToConstant: mainIconImageSize).isActive = true
        
        datetimeIcon.heightAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        datetimeIcon.widthAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        datetimeIcon.leftAnchor.constraint(equalTo: mainIcon.rightAnchor, constant: spacing * 2).isActive = true
        datetimeIcon.centerYAnchor.constraint(equalTo: mainIcon.centerYAnchor).isActive = true
        datetimeLabel.centerYAnchor.constraint(equalTo: datetimeIcon.centerYAnchor).isActive = true
        datetimeLabel.leftAnchor.constraint(equalTo: datetimeIcon.rightAnchor, constant: spacing).isActive = true
        datetimeLabel.textAlignment = .left
        datetimeLabel.font = UIFont.systemFont(ofSize: smallTextSize)
        
        centerIcon.heightAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        centerIcon.widthAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        centerIcon.leftAnchor.constraint(equalTo: datetimeIcon.leftAnchor, constant: iconSpacing).isActive = true
        centerIcon.centerYAnchor.constraint(equalTo: mainIcon.centerYAnchor).isActive = true
        centerLabel.leftAnchor.constraint(equalTo: centerIcon.rightAnchor, constant: spacing).isActive = true
        centerLabel.widthAnchor.constraint(equalToConstant: iconSpacing - self.spacing * 3).isActive = true
        centerLabel.centerYAnchor.constraint(equalTo: centerIcon.centerYAnchor).isActive = true
        centerLabel.textAlignment = .left
        centerLabel.font = UIFont.systemFont(ofSize: smallTextSize)
        
        rightIcon.heightAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        rightIcon.widthAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        rightIcon.leftAnchor.constraint(equalTo: centerIcon.leftAnchor, constant: iconSpacing).isActive = true
        rightIcon.centerYAnchor.constraint(equalTo: mainIcon.centerYAnchor).isActive = true
        rightLabel.centerYAnchor.constraint(equalTo: rightIcon.centerYAnchor).isActive = true
        rightLabel.leftAnchor.constraint(equalTo: rightIcon.rightAnchor, constant: spacing).isActive = true
        rightLabel.rightAnchor.constraint(equalTo: contentSafeArea.rightAnchor, constant: -self.spacing).isActive = true
        rightLabel.textAlignment = .left
        rightLabel.font = UIFont.systemFont(ofSize: smallTextSize)
        
        
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
