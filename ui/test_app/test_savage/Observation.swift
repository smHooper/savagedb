//
//  Observation.swift
//  test_savage
//
//  Created by Sam Hooper on 5/8/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import Foundation
import UIKit
import os.log


class Observation: NSObject, NSCoding {
    
    // MARK: Properties
    var name: String
    var image: UIImage?
    var rating: Int
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("observations") //path becomes Observation.ArchivURL.path
    
    // MARK: Types
    struct PropertyKey {
        static let name = "name"
        static let image = "image"
        static let rating = "rating"
    }
    
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
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(image, forKey: PropertyKey.image)
        aCoder.encode(rating, forKey: PropertyKey.rating)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // The name is required. If we can't decode a name string, the initializer should fail
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String else {
            os_log("Unable to decode the name for an observation object", log: OSLog.default, type: .debug)
            return nil
        }
        
        // Because image is an optional property of Observation, just use conditional cast
        let image = aDecoder.decodeObject(forKey: PropertyKey.image) as? UIImage
        
        let rating = aDecoder.decodeInteger(forKey: PropertyKey.rating)
        
        // Must call designated initializer
        self.init(name: name, image: image, rating: rating)
    }
    
}
