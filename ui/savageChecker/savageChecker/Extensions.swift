//
//  Extensions.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/31/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit

// Get dimensions of text labels
extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}


extension UIViewController {
    func addBackground() {
        /*let startingBackGroundView = UIImageView(image: UIImage(named: "viewControllerBackground"))
        startingBackGroundView.frame = self.view.frame
        startingBackGroundView.contentMode = .scaleAspectFill
        self.view.addSubview(startingBackGroundView)*/
        
        let backgroundImageView = UIImageView(image: UIImage(named: "viewControllerBackgroundBlurred"))
        backgroundImageView.frame = self.view.frame
        backgroundImageView.contentMode = .scaleAspectFill
        
        let translucentView = UIView(frame: self.view.frame)
        translucentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        let backgroundView = UIView(frame: self.view.frame)
        backgroundView.addSubview(translucentView)
        backgroundView.addSubview(backgroundImageView)
        backgroundView.sendSubview(toBack: backgroundImageView)
        backgroundView.tag = -1
        self.view.addSubview(backgroundView)
    }
/*    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
 
 while (topController.presentedViewController) {
 topController = topController.presentedViewController;
 }
 
 return topController;
 }*/
    func getTopMostController() -> UIViewController {
        var topController = UIApplication.shared.keyWindow?.rootViewController
        while topController?.presentedViewController != nil {
            topController = topController?.presentedViewController
        }
        
        return topController!
    }
}

// Add extension to dismiss keyboard for any text field
/*extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}*/
