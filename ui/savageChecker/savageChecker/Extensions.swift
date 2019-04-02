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
    
    static var formSheetSize = CGSize(width: min(UIScreen.main.bounds.width, 400), height: min(UIScreen.main.bounds.height, 600))
    var formSheetFrame: CGRect {
        let contentSize = UIViewController.formSheetSize//CGSize(width: min(self.view.frame.width, 400), height: min(self.view.frame.height, 600))
        let frame = self.view.frame
        let controllerMinX = frame.minX + frame.width/2 - contentSize.width/2
        let controllerMinY = frame.minY + frame.height/2 - contentSize.height/2
        return CGRect(x: controllerMinX, y: controllerMinY, width: contentSize.width, height: contentSize.height)
    }
    
    var blurredSnapshotView: UIView {
        get {
            let blurEffect = UIBlurEffect(style: .light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            // Only apply the blur if the user hasn't disabled transparency effects
            if !UIAccessibilityIsReduceTransparencyEnabled() {
                self.view.backgroundColor = .clear
                
                let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
                let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
                
                blurEffectView.frame = self.view.frame//bounds
                blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
                self.view.addSubview(blurEffectView)
                self.view.addSubview(vibrancyView)
                
            } else {
                // ************ Might need to make a dummy blur effect so that removeFromSuperview() in AddObservationMenu transition doesn't choke
                self.view.backgroundColor = .black
            }
        
            
            // Get image of all currently visible views with the blur
            let backgroundView = UIImageView(image: self.view.takeSnapshot())
            
            // remove blurview
            blurEffectView.removeFromSuperview()
            
            // Since a .formSheet modal presentation will show the image in the upper left corner of the frame, offset the frame so it displays in the right place
            backgroundView.contentMode = .scaleAspectFill
            let currentFrame = self.view.frame
            backgroundView.frame = CGRect(x: currentFrame.minX - formSheetFrame.minX, y: currentFrame.minY - formSheetFrame.minY, width: currentFrame.width, height: currentFrame.height)
            
            // Add translucent white
            let whiteAlpha: CGFloat = 0 // this is just here in case I want to use this in the future
            if whiteAlpha > 0 {
                let translucentWhite = UIView(frame: backgroundView.frame)
                translucentWhite.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: whiteAlpha)
                backgroundView.addSubview(translucentWhite)
            }
            
            return backgroundView
        }
        /*set {
            
        }*/
    }
    
    
    
    func addBackground(showWhiteView: Bool = true) {
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
            let _ = saveImage(image: defaultImage!)
            backgroundImage = defaultImage!
        }
        
        let backgroundImageView = UIImageView(image: backgroundImage)//"UIImage(named: viewControllerBackgroundBlurred"))//
        backgroundImageView.frame = self.view.frame
        backgroundImageView.contentMode = .scaleAspectFill
        
        let translucentView = UIView(frame: self.view.frame)
        translucentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        let backgroundView = UIView()//frame: self.view.frame)
        //backgroundView.backgroundColor = UIColor.red
        if showWhiteView {backgroundView.addSubview(translucentView)}
        backgroundView.addSubview(backgroundImageView)
        backgroundView.sendSubview(toBack: backgroundImageView)
        backgroundView.tag = -1
        self.view.addSubview(backgroundView)
        
        // Set constraints to the whole view
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        backgroundView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        backgroundView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        if showWhiteView {
            translucentView.translatesAutoresizingMaskIntoConstraints = false
            translucentView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            translucentView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            translucentView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            translucentView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        }
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        backgroundImageView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        backgroundImageView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
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
    
    func getVisibleFrame() -> CGRect {
        let frame = self.view.frame// frame is actually the size of the device even though preferredContentSize is smaller
        let contentSize = self.preferredContentSize
        let controllerMinX = frame.minX + frame.width/2 - contentSize.width/2
        let controllerMinY = frame.minY + frame.height/2 - contentSize.height/2
        let controllerFrame = CGRect(x: controllerMinX, y: controllerMinY, width: contentSize.width, height: contentSize.height)
        
        return controllerFrame
    }
    
    
    func getTopMostController() -> UIViewController {
        var topController = UIApplication.shared.keyWindow?.rootViewController
        while topController?.presentedViewController != nil {
            topController = topController?.presentedViewController
        }
        
        return topController!
    }
    
    func loadUserData() -> UserData? {
        let userData = NSKeyedUnarchiver.unarchiveObject(withFile: userDataPath) as? UserData
        if userData != nil { print("User data successfully loaded: \(userData!.activeDatabase)") }
        
        return userData
    }
    
    
    // Get the datestamp for the dbPath
    func getFileNameTag() -> String {
        let formatter = DateFormatter()
        let now = Date()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        let dateString = formatter.string(from: now).replacingOccurrences(of: "/", with: "-")//.replacingOccurrences(of: "1", with: "2")
        
        return dateString
    }
    
    
    @objc func checkBoxTapped(sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseInOut, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            
        }) { (success) in
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
                sender.isSelected = !sender.isSelected
                sender.transform = .identity
            }, completion: nil)
        }
    }
    
    // Get the dropDown options for a given controller/field combo
    func parseJSON(controllerLabel: String, fieldName: String) -> [String] {
        let fields = dropDownJSON[controllerLabel]
        var options = [String]()
        for item in fields[fieldName]["options"].arrayValue {
            options.append(item.stringValue)
        }
        return options
    }
    
    // Get the current screen size
    func getCurrentScreenFrame() -> CGRect {
        let screenSize = UIScreen.main.bounds // This is actually the screen size before rotation
        let isLandscape = UIDevice.current.orientation.isLandscape
        let currentScreenFrame: CGRect = {
            if isLandscape {
                return CGRect(x: 0, y: 0, width: max(screenSize.width, screenSize.height), height: min(screenSize.width, screenSize.height))
            } else {
                return CGRect(x: 0, y: 0, width: min(screenSize.width, screenSize.height), height: max(screenSize.width, screenSize.height))
            }
        }()
        
        return currentScreenFrame
    }
    

    func getCurrentDbPath() -> String {
        if let userData = loadUserData() {
            // Check if the active path's exists
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(userData.activeDatabase).path
        } else {
            // Use global path
            return dbPath
        }
    }
    
    
    func currentDbExists() -> Bool {
        let currentDbPath = getCurrentDbPath()
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: currentDbPath)
    }
    

    func showShiftInfoForm() {
        let shiftViewController = ShiftInfoViewController()
        shiftViewController.modalPresentationStyle = .formSheet
        UIViewController.formSheetSize = CGSize(width: min(self.view.frame.width, 400), height: min(self.view.frame.height, 600)) // Set this because it affects the bounds of the blurEffectView
        shiftViewController.preferredContentSize = UIViewController.formSheetSize//CGSize.init(width: 600, height: 600)
        
        // Add blurred background from current view
        //let popoverFrame = shiftViewController.getVisibleFrame()
        let backgroundView = self.blurredSnapshotView//getBlurredSnapshot(frame: formSheetFrame)
        shiftViewController.view.addSubview(backgroundView)
        shiftViewController.view.sendSubview(toBack: backgroundView)
        
        present(shiftViewController, animated: true, completion: nil)
    }
    
    
    func showDbNotExistsAlert() {
        // If the current DB does not exist, alert the user and force them to create a new DB
        let currentDbName = getCurrentDbPath().split(separator: "/").last ?? ""
        let alertTitle = "No database file found"
        let alertMessage = "The database named \(currentDbName) that you are trying to access does not exist or could not be found, and you can't perform the current operation without a valid file. Perhaps the file was deleted? Press OK to create a new database, then re-try what you were trying to do."
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {handler in
            //alertController.dismiss(animated: false, completion: nil)
            self.showShiftInfoForm()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    // Show a generic warning.info message
    func showGenericAlert(message: String = "An unknown error has occurred", title: String = "Error") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        // run in separate process so that it present works in viewDidLoad
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: {
                let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
                let fileName = "error_screenshot \(Date()).png"
                let screenshotDir = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("errors")
                let fileManager = FileManager.default
                var isDir: ObjCBool = false
                if !fileManager.fileExists(atPath: screenshotDir.path, isDirectory:&isDir) {
                    try? fileManager.createDirectory(at: screenshotDir, withIntermediateDirectories: true, attributes: nil)
                }
                let imgURL = fileManager.fileExists(atPath: screenshotDir.path, isDirectory:&isDir) ? screenshotDir.appendingPathComponent(fileName) : URL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName)
                let screenshot = alertController.view.takeSnapshot()
                try? UIImagePNGRepresentation(screenshot)?.write(to: imgURL)
            })
        }
    }
}


extension UIImageView {
    
    func blurEffect(radius: Int) -> UIImageView {
        let context = CIContext(options: nil)
        
        let currentFilter = CIFilter(name: "CIGaussianBlur")
        let beginImage = CIImage(image: self.image!)
        currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter!.setValue(radius, forKey: kCIInputRadiusKey)
        
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
        cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")
        
        let output = cropFilter!.outputImage
        let cgimg = context.createCGImage(output!, from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        
        return UIImageView(image: processedImage)
    }
}


extension UIView {
    
    func takeSnapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
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
