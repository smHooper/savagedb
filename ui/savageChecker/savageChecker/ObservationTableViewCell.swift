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
    @IBOutlet weak var iconImage: UIImageView!
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
    
    
    let iconImage = UIImageView()
    let driverLabel = UILabel()
    let destinationLabel = UILabel()
    let datetimeLabel = UILabel()
    
    let spacing: CGFloat = 6.0
    let largeTextSize: CGFloat = 24
    let smallTextSize: CGFloat = 17
    let mainIconImageSize: CGFloat = 90
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //iconImage.backgroundColor = UIColor.blue
        
        let bundle = Bundle(for: type(of: self))
        iconImage.image = UIImage(named: "shuttleBusImg", in: bundle, compatibleWith: self.traitCollection)
        //iconImage.frame = CGRect(x: 0, y:0, width: self.mainIconImageSize, height: self.mainIconImageSize)
        iconImage.contentMode = .scaleAspectFit
        
        contentView.addSubview(iconImage)
        contentView.addSubview(driverLabel)
        contentView.addSubview(destinationLabel)
        contentView.addSubview(datetimeLabel)
        
        // Set up constraints
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        driverLabel.translatesAutoresizingMaskIntoConstraints = false
        destinationLabel.translatesAutoresizingMaskIntoConstraints = false
        datetimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        iconImage.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        iconImage.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        iconImage.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
        
        driverLabel.textAlignment = .left
        driverLabel.font = UIFont.systemFont(ofSize: largeTextSize)
        driverLabel.leftAnchor.constraint(equalTo: iconImage.rightAnchor, constant: spacing).isActive = true
        driverLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing).isActive = true
        
        destinationLabel.textAlignment = .left
        destinationLabel.font = UIFont.systemFont(ofSize: smallTextSize)
        destinationLabel.leftAnchor.constraint(equalTo: iconImage.rightAnchor, constant: spacing).isActive = true
        destinationLabel.topAnchor.constraint(equalTo: driverLabel.bottomAnchor, constant: spacing).isActive = true
        
        datetimeLabel.textAlignment = .left
        datetimeLabel.font = UIFont.systemFont(ofSize: smallTextSize)
        datetimeLabel.leftAnchor.constraint(equalTo: iconImage.rightAnchor, constant: spacing).isActive = true
        datetimeLabel.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: spacing).isActive = true
        
        
        /*let viewsDict = [
            "iconImage" : iconImage,
            "driver" : driverLabel,
            "destination" : destinationLabel,
            "datetimeLabel" : datetimeLabel,
            ] as [String : Any]
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[iconImage(10)]", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[datetimeLabel]-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[driver]-[destination]-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[driver]-[iconImage(10)]-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[destination]-[datetimeLabel]-|", options: [], metrics: nil, views: viewsDict))*/
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
