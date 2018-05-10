//
//  ObservationTableViewCell.swift
//  test_savage
//
//  Created by Sam Hooper on 5/8/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit

class ObservationTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var observationLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var ratingControl: RatingControl!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
