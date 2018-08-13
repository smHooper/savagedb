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


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //configureDatabase()
        parseDropDownOptionJSON()
        
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
            print(fileManager.fileExists(atPath: url.path))
            if fileManager.fileExists(atPath: url.path) {
                jsonURL = url
            }
            // If it's not there, use the default config file in Resources
            else if let url = Bundle.main.url(forResource: "savageCheckerConfig", withExtension: "json") {
                jsonURL = url
            } else {
                fatalError("Could not configure dropDown menus")
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
                for item in globalFields["Destinations"]["options"].arrayValue {
                    destinations.append(item.stringValue)
                }
                
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
                catch {print("Could not delete background.png")}
            }
        }
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
