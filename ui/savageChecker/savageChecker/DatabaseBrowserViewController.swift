//
//  DatabaseBrowserViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 7/27/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit

class DatabaseBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.allowsPickingMultipleItems = false
        

        // Do any additional setup after loading the view.
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
