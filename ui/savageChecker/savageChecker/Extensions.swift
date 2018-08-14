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
        
        // Try to load an image in the Documents directory called background.png.
        //  If this is the first time the app is opened or if the file got moved,
        //  save the default image to Documents and try again
        
        /*let defaultImage = UIImage(named: "viewControllerBackgroundBlurred")
        var backgoundImage: UIImage
        guard var image = loadBackgroundImage(named: "background.png") else {
            backgoundImage = defaultImage!
            saveImage(image: backgoundImage)
            return
        }*/
        
        let backgroundImage: UIImage
        if let image = loadBackgroundImage(named: "background.png") {
            backgroundImage = image
        } else {
            let defaultImage = UIImage(named: "viewControllerBackgroundBlurred")
            saveImage(image: defaultImage!)
            backgroundImage = defaultImage!
        }
        
        let backgroundImageView = UIImageView(image: backgroundImage)//"UIImage(named: viewControllerBackgroundBlurred"))//
        backgroundImageView.frame = self.view.frame
        backgroundImageView.contentMode = .redraw//.scaleAspectFill
        
        let translucentView = UIView(frame: self.view.frame)
        translucentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        let backgroundView = UIView(frame: self.view.frame)
        backgroundView.addSubview(translucentView)
        backgroundView.addSubview(backgroundImageView)
        backgroundView.sendSubview(toBack: backgroundImageView)
        backgroundView.tag = -1
        self.view.addSubview(backgroundView)
        /*let backgroundImageView = UIImageView(image: UIImage(named: "viewControllerBackgroundBlurred"))
        backgroundImageView.frame = self.view.frame
        backgroundImageView.contentMode = .scaleAspectFill
        
        let translucentView = UIView(frame: self.view.frame)
        translucentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        let backgroundView = UIView(frame: self.view.frame)
        backgroundView.addSubview(translucentView)
        backgroundView.addSubview(backgroundImageView)
        backgroundView.sendSubview(toBack: backgroundImageView)
        backgroundView.tag = -1
        self.view.addSubview(backgroundView)*/
    }
    
    func loadBackgroundImage(named: String) -> UIImage? {
        if let documentsDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: documentsDirectory.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    
    func saveImage(image: UIImage) -> Bool {
        guard let data = UIImageJPEGRepresentation(image, 1) ?? UIImagePNGRepresentation(image) else {
            return false
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        do {
            try data.write(to: directory.appendingPathComponent("background.png")!)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
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
    
    func loadUserData() -> UserData? {
        let userData = NSKeyedUnarchiver.unarchiveObject(withFile: userDataPath) as? UserData
        if let data = userData { print("User data successfully loaded: \(userData!.activeDatabase)") }
        
        return userData
    }
    
    
}

extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
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
