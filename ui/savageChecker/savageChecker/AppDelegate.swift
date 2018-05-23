//
//  AppDelegate.swift
//  savageChecker
//
//  Created by Sam Hooper on 5/10/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import SQLite3

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Connect to DB and create all necessary tables
        let db: SQLiteDatabase
        do {
            db = try SQLiteDatabase.open(path: SQLiteDatabase.path)
            print("Successfully opened connection to database.")
        } catch SQLiteError.OpenDatabase(let message) {
            fatalError("Unable to establish database connection")
        } catch let error {
            fatalError(error.localizedDescription)
        }

        // Make tables
        /*let createSessionSQL = "CREATE TABLE IF NOT EXISTS sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, observerName TEXT, date TEXT, openTime TEXT, closeTime TEXT);"
        do {
            try db.createTable(sql: createSessionSQL)
            print("Successfully created session table")
        } catch {
            print(db.errorMessage)
        }*/
        
        let createObservationsSQL = "CREATE TABLE IF NOT EXISTS observations (id INTEGER PRIMARY KEY AUTOINCREMENT, observerName TEXT, date TEXT, time TEXT, driverName TEXT, destination TEXT, nPassengers TEXT);"
        do {
            try db.createTable(sql: createObservationsSQL)
            print("Successfully created session table")
        } catch {
            fatalError(db.errorMessage)
        }
        
        // Close the database so another view can connect to it
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("applicationWillTerminate")
    }


}

// Add extension to dismiss keyboard for any text field
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
