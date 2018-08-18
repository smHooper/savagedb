//
//  AppDelegate.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/10/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
//import SQLite3
import SQLite
import GoogleSignIn
import os.log


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize sign-in
        GIDSignIn.sharedInstance().clientID = "59359788509-qqmv7kic2loknn25atsbsoumofu9vvf6.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self
        
        // Parse global vars from JSON
        parseDropDownOptionJSON()
        
        // Set the status bar height var from Globals.swift
        statusBarHeight = application.statusBarFrame.size.height
        
        // Set up log file
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileName = "\(Date()).log"
        let logFilePath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName).path
        freopen(logFilePath.cString(using: String.Encoding.ascii)!, "a+", stderr)
        
        let sessionController = SessionViewController()
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = sessionController
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    
    func parseDropDownOptionJSON(){
        var jsonURL = URL(fileURLWithPath: "")
        // Look for config file in Documents folder.
        let fileManager = FileManager.default
        if let documentsDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).absoluteString {
            let url = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("savageCheckerConfig.json")
            
            if fileManager.fileExists(atPath: url.path) {
                jsonURL = url
            }
            // If it's not there, use the default config file in Resources
            else if let url = Bundle.main.url(forResource: "savageCheckerConfig", withExtension: "json") {
                jsonURL = url
            } else {
                os_log("Could not configure dropDown menus in AppDelegate.parseDropDownOptions()", log: OSLog.default, type: .debug)
            }
        }
        
        // Read in the .json as one long text string
        let jsonString: String
        jsonString = try! String(contentsOf: jsonURL, encoding: .utf8)
        //catch {print(error)}
        
        // If we can read the binary string from the text string
        if let data = jsonString.data(using: .utf8) {
            // Try to read it as a JSON struct (from JSONParser)
            let jsonObject: JSON!
            jsonObject = try! JSON(data: data)
            if jsonObject != nil {
                // Get globally applicable dropDown options
                let globalFields = jsonObject["fields"]["global"]
                for item in globalFields["Observer name"]["options"].arrayValue {
                    observers.append(item.stringValue)
                }
                for item in globalFields["Destination"]["options"].arrayValue {
                    destinations.append(item.stringValue)
                }
                
                // Set 'lodges' global var because ObservationTableViewController needs access to these values
                for item in jsonObject["fields"]["Lodge Bus"]["Lodge"]["options"].arrayValue {
                    lodges.append(item.stringValue)
                }
                
                // For all the controller-specific options, just set the global var dropDownJSON so each controller can access it
                dropDownJSON = jsonObject["fields"]
            }
        }
    }
    
    
    func replaceBackgroundImage() {
        let fileManager = FileManager.default
        
        if let documentsDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            
            let url = URL(fileURLWithPath: documentsDirectory.absoluteString).appendingPathComponent("background.png")
            
            if !fileManager.fileExists(atPath: url.path){
                do { try fileManager.removeItem(atPath: url.absoluteString)}
                catch {os_log("Could not delete background.png", log: OSLog.default, type: .debug)}
            }
        }
    }
    
    
    //MARK: - GoogleSignin delegate methods
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url as URL?,
                                                 sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: options[UIApplicationOpenURLOptionsKey.annotation]
        )
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            print("\(error.localizedDescription)")
            os_log("Google sign in failed", log: OSLog.default, type: .debug)
        } else {
            // Perform any operations on signed in user here.
            let userId = user.userID                  // For client-side use only!
            let idToken = user.authentication.idToken // Safe to send to the server
            let fullName = user.profile.name
            let givenName = user.profile.givenName
            let familyName = user.profile.familyName
            let email = user.profile.email
            // ...
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        //print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        //print("applicationDidEnterBackground")
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        //print("applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //print("applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        //print("applicationWillTerminate")
    }

}
