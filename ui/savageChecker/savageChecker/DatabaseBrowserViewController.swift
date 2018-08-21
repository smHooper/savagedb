//
//  DatabaseBrowserViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 7/27/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import SQLite
import os.log


class DatabaseBrowserViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var userData: UserData?
    var files = [String]()
    var fileTableView: UITableView!
    let spacing: CGFloat = 16
    let legendIconSize: CGFloat = 30
    let selectedColor = UIColor(red: 0.5, green: 0.6, blue: 0.7, alpha: 0.5)
    //var cancelButton: UI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.view.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
        self.view.backgroundColor = UIColor.clear
        
        guard let userData = loadUserData() else {
            os_log("Couldn't load user data", log: OSLog.default, type: .default)
            return
        }
        self.userData = userData
        
        findFiles()
        
        // Add a title at the top
        let titleLabel = UILabel()
        titleLabel.text = "Select a database file to load"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        self.view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.spacing * 1.5).isActive = true
        print((self.view.frame.height - min(self.preferredContentSize.height, self.view.frame.height))/2)
        
        // Add a cancel button at the bottom
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel!.font = UIFont.systemFont(ofSize: 22)
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        self.view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -self.spacing * 2).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -self.spacing).isActive = true
        
        // Add legend for file status (uploaded or not)
        let notUploadedIcon = UIImageView(image: UIImage(named: "databaseFileIcon"))
        self.view.addSubview(notUploadedIcon)
        notUploadedIcon.contentMode = .scaleAspectFit
        notUploadedIcon.translatesAutoresizingMaskIntoConstraints = false
        notUploadedIcon.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: self.spacing * 2).isActive = true
        notUploadedIcon.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -self.spacing).isActive = true
        notUploadedIcon.widthAnchor.constraint(equalToConstant: self.legendIconSize).isActive = true
        notUploadedIcon.heightAnchor.constraint(equalToConstant: self.legendIconSize).isActive = true
        
        let notUploadedLabel = UILabel()
        self.view.addSubview(notUploadedLabel)
        notUploadedLabel.text = "Not uploaded"
        notUploadedLabel.font = UIFont.systemFont(ofSize: 16)
        notUploadedLabel.translatesAutoresizingMaskIntoConstraints = false
        notUploadedLabel.leftAnchor.constraint(equalTo: notUploadedIcon.rightAnchor, constant: self.spacing).isActive = true
        notUploadedLabel.centerYAnchor.constraint(equalTo: notUploadedIcon.centerYAnchor).isActive = true
        
        let uploadedIcon = UIImageView(image: UIImage(named: "databaseFileUploadedIcon"))
        self.view.addSubview(uploadedIcon)
        uploadedIcon.contentMode = .scaleAspectFit
        uploadedIcon.translatesAutoresizingMaskIntoConstraints = false
        uploadedIcon.leftAnchor.constraint(equalTo: notUploadedIcon.leftAnchor).isActive = true
        uploadedIcon.bottomAnchor.constraint(equalTo: notUploadedIcon.topAnchor, constant: -self.spacing).isActive = true
        uploadedIcon.widthAnchor.constraint(equalToConstant: self.legendIconSize).isActive = true
        uploadedIcon.heightAnchor.constraint(equalToConstant: self.legendIconSize).isActive = true
        
        let uploadedLabel = UILabel()
        self.view.addSubview(uploadedLabel)
        uploadedLabel.text = "Uploaded to Google Drive"
        uploadedLabel.font = UIFont.systemFont(ofSize: 16)
        uploadedLabel.translatesAutoresizingMaskIntoConstraints = false
        uploadedLabel.leftAnchor.constraint(equalTo: notUploadedIcon.rightAnchor, constant: self.spacing).isActive = true
        uploadedLabel.centerYAnchor.constraint(equalTo: uploadedIcon.centerYAnchor).isActive = true
        
        // Configure the tableView
        //let screenFrame = self.view.frame
        let titleWidth = titleLabel.text?.width(withConstrainedHeight: 30, font: titleLabel.font)
        let titleHeight = titleLabel.text?.height(withConstrainedWidth: titleWidth!, font: titleLabel.font)
        //let tableViewMinY = screenFrame.height/2 - self.preferredContentSize.height/2 + self.spacing * 2 + titleHeight!
        //let tableViewMinX = screenFrame.width/2 - self.preferredContentSize.width/2 + self.spacing
        let tableViewHeight = self.preferredContentSize.height - self.spacing * 5 - self.legendIconSize * 2 - titleHeight! // vertical layout = spacing * 2 | title | spacing | table | spacing | legendIcon | spacing | legendIcon | spacing
        self.fileTableView = UITableView(frame: CGRect(x: 0, y: self.spacing * 2 + titleHeight!, width: self.preferredContentSize.width, height: tableViewHeight))
        self.view.addSubview(self.fileTableView)
        self.fileTableView.register(DatabaseBrowserTableViewCell.self, forCellReuseIdentifier: "DatabaseBrowserCell")
        self.fileTableView.rowHeight = 65//UITableViewAutomaticDimension
        self.fileTableView.dataSource = self
        self.fileTableView.delegate = self
        self.fileTableView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
        
        
    }

    
    private func findFiles(){
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for url in fileURLs {
                let fileName = url.lastPathComponent
                if fileName != "savageChecker.db" && fileName.hasSuffix(".db"){
                    self.files.append(fileName)
                }
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
            os_log("Error while enumerating files", log: OSLog.default, type: .default)
        }
        
        // Sort in alphabetical order
        self.files.sort()
    }
    
    
    //MARK: - Navigation
    @objc func cancelButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: - TableView Delegate Methods
    func numberOfSections(in tableView: UITableView) -> Int{
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return self.observations.count
        return self.files.count
    }
    
    // Compose each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cell = tableView.dequeueReusableCell(withIdentifier: "DatabaseBrowserCell", for: indexPath) as! DatabaseBrowserTableViewCell
        
        // Fetch the right observation for the data source layout
        let fileString = self.files[indexPath.row]
        
        // Set the label's text to the filename
        cell.fileNameLabel.text = fileString
        
        // Check if this is the current DB. If so, make this cell look selected
        let currentDBName = dbPath.split(separator: "/").last!
        if fileString == currentDBName {
            //cell.backgroundColor = UIColor(red: 190/255, green: 220/255, blue: 240/255, alpha: 0.7)
            cell.backgroundColor = selectedColor
        } else {
            cell.backgroundColor = UIColor.clear
        }
        
        return cell
    }
    
    // Called when the cell is selected.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Change the dbPath
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let selectedFileName = self.files[indexPath.row]
        dbPath = documentsURL.appendingPathComponent(selectedFileName).path
        
        // Update UserData instance
        self.userData?.update(databaseFileName: selectedFileName)
        
        // Open the new datbase
        let presentingController = self.presentingViewController as! BaseTableViewController
        do {
            presentingController.db = try Connection(dbPath)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        dismiss(animated: true, completion: {presentingController.loadData()})
    }

    // Set custom color for selected cell
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DatabaseBrowserCell", for: indexPath) as! DatabaseBrowserTableViewCell
        
        let selectionView = UIView()
        selectionView.layer.borderWidth = 1
        selectionView.layer.borderColor = self.selectedColor.cgColor
        selectionView.backgroundColor = self.selectedColor
        cell.selectedBackgroundView = selectionView
        
        return indexPath
    }
}

//MARK: -
//MARK: -
class DatabaseBrowserTableViewCell: UITableViewCell {
    
    let icon = UIImageView()
    let fileNameLabel = UILabel()
    
    let iconSize: CGFloat = 30
    let fontSize: CGFloat = 20
    let spacing: CGFloat = 16
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.icon.image = UIImage(named: "databaseFileIcon", in: Bundle(for: type(of: self)), compatibleWith: self.traitCollection)
        self.icon.contentMode = .scaleAspectFill
        
        let contentSafeArea = UIView()
        self.contentView.addSubview(contentSafeArea)
        contentSafeArea.translatesAutoresizingMaskIntoConstraints = false
        contentSafeArea.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: self.spacing).isActive = true
        contentSafeArea.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: self.spacing).isActive = true
        contentSafeArea.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: self.spacing * -1).isActive = true
        contentSafeArea.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: self.spacing * -1).isActive = true
        
        contentSafeArea.addSubview(self.icon)
        contentSafeArea.addSubview(self.fileNameLabel)
        
        self.icon.translatesAutoresizingMaskIntoConstraints = false
        self.icon.leftAnchor.constraint(equalTo: contentSafeArea.leftAnchor).isActive = true
        self.icon.topAnchor.constraint(equalTo: contentSafeArea.topAnchor).isActive = true
        self.icon.heightAnchor.constraint(equalTo: contentSafeArea.heightAnchor).isActive = true
        self.icon.widthAnchor.constraint(equalToConstant: self.iconSize).isActive = true
        
        self.fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.fileNameLabel.centerYAnchor.constraint(equalTo: self.icon.centerYAnchor).isActive = true
        self.fileNameLabel.leftAnchor.constraint(equalTo: self.icon.rightAnchor, constant: spacing).isActive = true
        self.fileNameLabel.textAlignment = .left
        self.fileNameLabel.font = UIFont.systemFont(ofSize: fontSize)
        
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
