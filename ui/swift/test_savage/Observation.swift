//
//  Observation.swift
//  test_savage
//
//  Created by Sam Hooper on 5/8/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import Foundation
import UIKit


class Observation {
    
    // MARK: Properties
    var name: String
    var image: UIImage?
    var rating: Int
    
    //MARK: Initialization
    init?(name: String, image: UIImage?, rating: Int){

        // The name must not be empty
        guard !name.isEmpty else {
            return nil
        }
        
        // The rating must be between 0 and 5 inclusively
        guard (rating >= 0) && (rating <= 5) else {
            return nil
        }

        self.name = name
        self.image = image
        self.rating = rating
        
    }
}
