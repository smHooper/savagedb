//
//  TextFieldCell.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/31/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit


struct CellModel {
    let labelString: String
    let placeHolderString: String
    let labelFontSize: CGFloat
    let textFieldFontSize: CGFloat
}

class TextFieldCell: UITableViewCell {
    var label: UILabel?
    var textField: UITextField?
}


/*class TextFieldCell: UITableViewCell {
    
    let textFieldFontSize = 14.0
    
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false // enable auto layout
        label.textAlignment = .left
        return label
    }()
    
    var textField: UITextField?
    
    
    //MARK: Initialization
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addItems()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addItems() {
        addSubview(self.label)
        NSLayoutConstraint.activate([
            // label is tied to left side of cell
            label.leftAnchor.constraint(equalTo: leftAnchor)
            ])
        NSLayoutConstraint.activate([
            // label width is 70% of cell width
            label.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            // label is horizontally center of cell
            label.leftAnchor.constraint(equalTo: leftAnchor)
            ])
    }
    
    var model: CellModel? {
        didSet {
            label.text = model?.labelString ?? ""
            label.font = UIFont.systemFont(ofSize: (model?.labelFontSize)!)
            textField?.font = UIFont.systemFont(ofSize: (model?.textFieldFontSize)!)
            
        }
    }
}*/
