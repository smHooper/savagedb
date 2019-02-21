//
//  CheckBoxControl.swift
//  Convenience class to add a custom check box. Works with extension checkBoxTapped
//
//  savageChecker
//
//  Created by Sam Hooper on 2/19/19.
//  Copyright © 2019 Sam Hooper. All rights reserved.
//

import UIKit

class CheckBoxControl: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setImage(UIImage(named:"checkBoxUnselectedIcon"), for: .normal)
        self.setImage(UIImage(named:"checkBoxSelectedIcon"), for: .selected)
        self.contentHorizontalAlignment = .fill
        self.contentVerticalAlignment = .fill
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
