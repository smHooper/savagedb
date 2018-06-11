//
//  ObservationTableViewCell.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/14/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit

class ObservationTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var mainIcon: UIImageView!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var datetimeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

class BaseObservationTableViewCell: UITableViewCell {
    
    
    let mainIcon = UIImageView()
    let driverLabel = UILabel()
    let driverIcon = UIImageView()
    let destinationLabel = UILabel()
    let destinationIcon = UIImageView()
    let datetimeLabel = UILabel()
    let datetimeIcon = UIImageView()
    let nPassengersLabel = UILabel()
    let nPassengersIcon = UIImageView()
    
    let spacing: CGFloat = 8
    let largeTextSize: CGFloat = 24
    let smallTextSize: CGFloat = 20
    let mainIconImageSize: CGFloat = 90
    let smallIconImageSize: CGFloat = 30
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let bundle = Bundle(for: type(of: self))
        mainIcon.image = UIImage(named: "busIcon", in: bundle, compatibleWith: self.traitCollection)
        mainIcon.frame = CGRect(x: 0, y: 0, width: mainIconImageSize, height: mainIconImageSize)
        mainIcon.contentMode = .scaleAspectFit
        
        driverIcon.image = UIImage(named: "driverIcon", in: bundle, compatibleWith: self.traitCollection)
        //driverIcon.frame = CGRect(x: 0, y: 0, width: smallIconImageSize, height: smallIconImageSize)
        driverIcon.contentMode = .scaleAspectFit
        
        destinationIcon.image = UIImage(named: "destinationIcon", in: bundle, compatibleWith: self.traitCollection)
        destinationIcon.contentMode = .scaleAspectFit
        
        datetimeIcon.image = UIImage(named: "clockIcon", in: bundle, compatibleWith: self.traitCollection)
        datetimeIcon.contentMode = .scaleAspectFit
        
        nPassengersIcon.image = UIImage(named: "passengerIcon", in: bundle, compatibleWith: self.traitCollection)
        nPassengersIcon.contentMode = .scaleAspectFit
        
        let contentSafeArea = UIView()
        contentView.addSubview(contentSafeArea)
        contentSafeArea.translatesAutoresizingMaskIntoConstraints = false
        contentSafeArea.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: spacing).isActive = true
        contentSafeArea.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing).isActive = true
        contentSafeArea.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: spacing * -1).isActive = true
        contentSafeArea.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: spacing * -1).isActive = true
        
        contentSafeArea.addSubview(mainIcon)
        contentSafeArea.addSubview(driverLabel)
        contentSafeArea.addSubview(driverIcon)
        contentSafeArea.addSubview(destinationLabel)
        contentSafeArea.addSubview(destinationIcon)
        contentSafeArea.addSubview(datetimeLabel)
        contentSafeArea.addSubview(datetimeIcon)
        contentSafeArea.addSubview(nPassengersLabel)
        contentSafeArea.addSubview(nPassengersIcon)
        
        // Set up constraints
        mainIcon.translatesAutoresizingMaskIntoConstraints = false
        driverLabel.translatesAutoresizingMaskIntoConstraints = false
        driverIcon.translatesAutoresizingMaskIntoConstraints = false
        destinationLabel.translatesAutoresizingMaskIntoConstraints = false
        destinationIcon.translatesAutoresizingMaskIntoConstraints = false
        datetimeLabel.translatesAutoresizingMaskIntoConstraints = false
        datetimeIcon.translatesAutoresizingMaskIntoConstraints = false
        nPassengersLabel.translatesAutoresizingMaskIntoConstraints = false
        nPassengersIcon.translatesAutoresizingMaskIntoConstraints = false
        
        mainIcon.leftAnchor.constraint(equalTo: contentSafeArea.leftAnchor).isActive = true
        mainIcon.topAnchor.constraint(equalTo: contentSafeArea.topAnchor).isActive = true
        mainIcon.heightAnchor.constraint(equalTo: contentSafeArea.heightAnchor).isActive = true
        mainIcon.widthAnchor.constraint(equalToConstant: mainIconImageSize).isActive = true
        
        driverIcon.heightAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        driverIcon.widthAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        driverIcon.leftAnchor.constraint(equalTo: mainIcon.rightAnchor, constant: spacing * 2).isActive = true
        driverIcon.topAnchor.constraint(equalTo: mainIcon.topAnchor, constant: spacing).isActive = true
        driverLabel.centerYAnchor.constraint(equalTo: driverIcon.centerYAnchor).isActive = true
        driverLabel.leftAnchor.constraint(equalTo: driverIcon.rightAnchor, constant: spacing).isActive = true
        driverLabel.textAlignment = .left
        driverLabel.font = UIFont.systemFont(ofSize: smallTextSize)
        
        destinationIcon.heightAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        destinationIcon.widthAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        destinationIcon.centerXAnchor.constraint(equalTo: driverIcon.centerXAnchor).isActive = true
        destinationIcon.bottomAnchor.constraint(equalTo: mainIcon.bottomAnchor, constant: spacing * -1).isActive = true
        destinationLabel.centerYAnchor.constraint(equalTo: destinationIcon.centerYAnchor).isActive = true
        destinationLabel.leftAnchor.constraint(equalTo: driverLabel.leftAnchor).isActive = true
        destinationLabel.textAlignment = .left
        destinationLabel.font = UIFont.systemFont(ofSize: smallTextSize)
        
        
        datetimeIcon.heightAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        datetimeIcon.widthAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        datetimeIcon.leftAnchor.constraint(equalTo: driverLabel.leftAnchor, constant: contentView.frame.width/2).isActive = true
        datetimeIcon.centerYAnchor.constraint(equalTo: driverIcon.centerYAnchor).isActive = true
        datetimeLabel.leftAnchor.constraint(equalTo: datetimeIcon.rightAnchor, constant: spacing).isActive = true
        datetimeLabel.centerYAnchor.constraint(equalTo: driverIcon.centerYAnchor).isActive = true
        datetimeLabel.textAlignment = .left
        datetimeLabel.font = UIFont.systemFont(ofSize: smallTextSize)
        
        nPassengersIcon.heightAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        nPassengersIcon.widthAnchor.constraint(equalToConstant: smallIconImageSize).isActive = true
        nPassengersIcon.centerXAnchor.constraint(equalTo: datetimeIcon.centerXAnchor).isActive = true
        nPassengersIcon.bottomAnchor.constraint(equalTo: destinationIcon.bottomAnchor).isActive = true
        nPassengersLabel.centerYAnchor.constraint(equalTo: destinationIcon.centerYAnchor).isActive = true
        nPassengersLabel.leftAnchor.constraint(equalTo: datetimeLabel.leftAnchor).isActive = true
        nPassengersLabel.textAlignment = .left
        nPassengersLabel.font = UIFont.systemFont(ofSize: smallTextSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
