//
//  GoogleDriveUploadViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 8/21/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import os.log
import QuartzCore
import SQLite


class GoogleDriveUploadViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, DBBrowserViewControllerDelegate  {

    
    
    
    //MARK: - Properties
    let spacing: CGFloat = 16
    var selectedFiles = [dbPath.components(separatedBy: "/").last!] //initialize with just the current file
    var fileTableView = FileTableView()
    var tableViewHeightConstraint = NSLayoutConstraint()
    let preferredCellSize: CGFloat = 40
    let userNameLabel = UILabel()
    var dbBrowserViewController: DatabaseBrowserViewController!
    var maxTableViewHeight: CGFloat!
    let googleIcon = UIImageView(image: UIImage(named: "googleIcon"))
    let signInButton = GIDSignInButton() //store this as a property so you can enable/disable depending on whether the user is signed in
    var uploadButton = UIButton(type: .system) //same for this button
    let driveService = GTLRDriveService()
    var uploadFolderName: String?
    
    //MARK: - Layout
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment to automatically sign in the user.
        //GIDSignIn.sharedInstance().signIn()
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDrive]//"https://www.googleapis.com/auth/drive.file"]
        
        // Add a title at the top
        let titleLabel = UILabel()
        titleLabel.text = "Upload files to Google Drive"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        self.view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.spacing * 1.5).isActive = true
        
        // Add the upload button
        let controllerFrame = getVisibleFrame()
        uploadButton.setTitle("Upload", for: .normal)
        uploadButton.titleLabel!.font = UIFont.systemFont(ofSize: 22)
        uploadButton.addTarget(self, action: #selector(uploadButtonPressed), for: .touchUpInside)
        self.view.addSubview(uploadButton)
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -controllerFrame.width/4).isActive = true
        uploadButton.bottomAnchor.constraint(equalTo: self.view.topAnchor, constant: self.preferredContentSize.height - self.spacing).isActive = true
        uploadButton.isEnabled = false
        
        // Add a cancel button at the bottom
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel!.font = UIFont.systemFont(ofSize: 22)
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        self.view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: controllerFrame.width/4).isActive = true
        cancelButton.centerYAnchor.constraint(equalTo: uploadButton.centerYAnchor).isActive = true
        
        // Draw lines to separate buttons from text
        //  Horizontal line
        let lineColor = UIColor(named: "neutralAccent40")//UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.4)
        let horizontalLine = UIView(frame: CGRect(x:0, y: 0, width: controllerFrame.width, height: 1))
        self.view.addSubview(horizontalLine)
        horizontalLine.backgroundColor = lineColor
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        horizontalLine.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        horizontalLine.topAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -self.spacing/2).isActive = true
        horizontalLine.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        horizontalLine.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        
        //  Vertical line
        let verticalLine = UIView(frame: CGRect(x:0, y: 0, width: 1, height: 1))
        self.view.addSubview(verticalLine)
        verticalLine.backgroundColor = lineColor
        verticalLine.translatesAutoresizingMaskIntoConstraints = false
        verticalLine.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        verticalLine.topAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -self.spacing/2).isActive = true
        verticalLine.widthAnchor.constraint(equalToConstant: 1.0).isActive = true
        verticalLine.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor).isActive = true
        
        // Add tableView to show which files are selected for upload
        let textButtonHeight = "A".height(withConstrainedWidth: 20, font: (uploadButton.titleLabel?.font)!)
        let titleHeight = "A".height(withConstrainedWidth: 20, font: titleLabel.font)
        self.maxTableViewHeight = self.preferredContentSize.height - self.spacing * 9 - textButtonHeight - titleHeight - self.preferredCellSize
        self.fileTableView = FileTableView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.view.addSubview(self.fileTableView)
        self.fileTableView.translatesAutoresizingMaskIntoConstraints = false
        self.fileTableView.tableView.backgroundColor = UIColor(named: "backgroundContrast40")//UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
        self.fileTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: self.spacing * 2).isActive = true
        self.fileTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -(self.spacing * 2)).isActive = true
        self.fileTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: self.spacing * 2).isActive = true
        self.tableViewHeightConstraint = self.fileTableView.heightAnchor.constraint(equalToConstant: min(self.maxTableViewHeight, self.preferredCellSize * CGFloat(self.selectedFiles.count)))
        self.tableViewHeightConstraint.isActive = true
        self.fileTableView.tableView.layer.borderColor = UIColor.clear.cgColor
        self.fileTableView.tableView.layer.borderWidth = 0
        self.fileTableView.tableView.rowHeight = self.preferredCellSize
        self.fileTableView.files = self.selectedFiles
        
        // Add google username label and google icon
        self.view.addSubview(self.googleIcon)
        self.googleIcon.contentMode = .scaleAspectFit
        self.googleIcon.translatesAutoresizingMaskIntoConstraints = false
        self.googleIcon.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: self.spacing * 2).isActive = true
        //googleIcon.bottomAnchor.constraint(equalTo: uploadButton.topAnchor, constant: -(self.spacing * 2)).isActive = true
        self.googleIcon.topAnchor.constraint(equalTo: self.fileTableView.bottomAnchor, constant: self.spacing * 2).isActive = true
        self.googleIcon.heightAnchor.constraint(equalToConstant: self.preferredCellSize).isActive = true
        self.googleIcon.widthAnchor.constraint(equalToConstant: self.preferredCellSize).isActive = true
        self.googleIcon.isHidden = true
        
        self.userNameLabel.text = GIDSignIn.sharedInstance().currentUser?.userID ?? ""
        self.userNameLabel.textAlignment = .left
        self.userNameLabel.font = UIFont.systemFont(ofSize: 20)
        self.view.addSubview(self.userNameLabel)
        self.userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.userNameLabel.leftAnchor.constraint(equalTo: googleIcon.rightAnchor, constant: self.spacing).isActive = true
        self.userNameLabel.centerYAnchor.constraint(equalTo: googleIcon.centerYAnchor).isActive = true
        self.userNameLabel.rightAnchor.constraint(equalTo: uploadButton.rightAnchor).isActive = true
        
        // Configure the sign-in button
        self.view.addSubview(self.signInButton)
        self.signInButton.style = .standard
        self.signInButton.colorScheme = .dark
        self.signInButton.translatesAutoresizingMaskIntoConstraints = false
        self.signInButton.leftAnchor.constraint(equalTo: self.googleIcon.leftAnchor).isActive = true
        self.signInButton.topAnchor.constraint(equalTo: self.googleIcon.topAnchor).isActive = true
        
        // Add a button for selecting files
        let selectFileButton = UIButton(type: .custom)
        selectFileButton.setImage(UIImage(named: "switchDatabaseIcon"), for: .normal)
        selectFileButton.imageView?.contentMode = .scaleAspectFit
        self.view.addSubview(selectFileButton)
        selectFileButton.translatesAutoresizingMaskIntoConstraints = false
        selectFileButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -(self.spacing * 2)).isActive = true
        selectFileButton.topAnchor.constraint(equalTo: googleIcon.topAnchor).isActive = true
        selectFileButton.widthAnchor.constraint(equalTo: googleIcon.widthAnchor).isActive = true
        selectFileButton.heightAnchor.constraint(equalTo: googleIcon.heightAnchor).isActive = true
        selectFileButton.addTarget(self, action: #selector(selectFileButtonPressed), for: .touchUpInside)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Check if the file to upload to (which get's created on sign-in) has any files in it. If not, delete the whole folder
        search(self.uploadFolderName ?? "") { (folderID, error) in
            if let id = folderID {
                let query = GTLRDriveQuery_FilesList.query()
                query.pageSize = 50 // number of items to return
                query.q = "'\(id)' in parents and trashed=false"
                self.driveService.executeQuery(query) { (ticket, results, error) in
                    if (results as? GTLRDrive_FileList)?.files?.count ?? 1 == 0 {
                        let deleteQuery = GTLRDriveQuery_FilesDelete.query(withFileId: id)
                        self.driveService.executeQuery(deleteQuery, completionHandler: nil)
                    }
                }
            }
        }
    }
    
    
    //MARK: - Navigation
    // Sign out automatically when the cancel button is pressed. This way, a separate signout button isn't necessary
    @objc func cancelButtonPressed() {
        dismiss(animated: true, completion: {GIDSignIn.sharedInstance().signOut()})
    }
    
    
    //MARK: - GDrive upload
    public func search(_ fileName: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        query.q = "name = '\(fileName)' and trashed=false"
        
        self.driveService.executeQuery(query) { (ticket, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first?.identifier, error)
        }
    }

    
    public func createFolder(_ name: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let file = GTLRDrive_File()
        file.name = name
        file.mimeType = "application/vnd.google-apps.folder"
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: nil)
        query.fields = "id"
        
        self.driveService.executeQuery(query) { (ticket, folder, error) in
            onCompleted((folder as? GTLRDrive_File)?.identifier, error)
        }
    }//*/
    
    
    private func upload(_ parentID: String?, path: String, uploadedFileName: String? = nil, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
        
        guard let data = FileManager.default.contents(atPath: path) else {
            //onCompleted?(nil, GDriveError.NoDataAtPath)
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_hh-mm-ss"
        let now = Date()
        let cleanedDeviceName = getCleanedDeviceName() ?? UIDevice.current.name
        
        let timestamp = "\(formatter.string(from: now))_\(cleanedDeviceName)" // Don't make a helper function out of this because timeStyle in uploadButtonPressed = .none
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "’", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        
        let file = GTLRDrive_File()
        let gdriveFileName = uploadedFileName == nil ? path.components(separatedBy: "/").last?.replacingOccurrences(of: ".db", with: "_\(timestamp).db") : uploadedFileName?.replacingOccurrences(of: ".db", with: "_\(timestamp).db")
        file.name = gdriveFileName
        if let id = parentID {
            file.parents = [id] // file can have multiple parents because it can exist in multiple folders
        }
        
        let uploadParams = GTLRUploadParameters.init(data: data, mimeType: MIMEType)
        uploadParams.shouldUploadWithSingleRequest = true
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParams)
        query.fields = "id"
        
        self.driveService.executeQuery(query, completionHandler: { (ticket, file, error) in
            onCompleted?((file as? GTLRDrive_File)?.identifier, error)
        })
    }
    

    public func uploadFile(_ folderName: String, filePath: String, uploadedFileName: String? = nil, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
        
        search(folderName) { (folderID, error) in
            
            if let ID = folderID {
                self.upload(ID, path: filePath, uploadedFileName: uploadedFileName, MIMEType: MIMEType, onCompleted: onCompleted)
            } else {
                self.createFolder(folderName, onCompleted: { (folderID, error) in
                    guard let ID = folderID else {
                        onCompleted?(nil, error)
                        return
                    }
                    self.upload(ID, path: filePath, uploadedFileName: uploadedFileName, MIMEType: MIMEType, onCompleted: onCompleted)
                })
            }
        }
    }
    
    
    // Submit uploads
    @objc func uploadButtonPressed() {
        
        
        let sessionsTable = Table("sessions")
        let uploadedColumn = Expression<Bool>("uploaded")
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        var successfulFiles = [String]()
        var failedFiles = [String]()
        var uploadError: Error?
        var nFiles = 0
        var badFiles = [String]()
        for fileName in self.selectedFiles {
            let fullPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName).path
            if !dbHasData(path: fullPath){
                badFiles.append(fileName)
            }
        }
        for fileName in self.selectedFiles {
            let fullPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName).path
            uploadFile(self.uploadFolderName ?? "", filePath: fullPath, MIMEType: "application/x-sqlite3") { (fileID, error) in
                uploadError = error
                if error == nil {
                    // Update the uploaded column in the session table
                    let backupPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("backup").appendingPathComponent(fileName).path
                    if let db = try? Connection(fullPath) {
                        // Update all records because there should be only 1
                        if let resultCode = try? db.run(sessionsTable.update(uploadedColumn <- true)), resultCode > 0 {
                            print("Updated upload field successful for \(fileName) to \(String(describing: try? db.pluck(Table("sessions"))?[uploadedColumn]))")
                        } else {
                            self.showGenericAlert(message: "Upload for \(fileName) was successful, but update of the \"upload\" status for this file failed. This file will still appear with the \"Not uploaded\" icon in the list of files to upload", title: "\"Uploaded\" status not updated")
                            // If there was a problem updating the table, there could be something wrong with the DB so just upload the backup too
                            self.uploadFile(self.uploadFolderName ?? "", filePath: backupPath, uploadedFileName: fileName.replacingOccurrences(of: ".db", with: "_backup.db"), MIMEType: "application/x-sqlite3") { (fileID, error) in uploadError = error}
                        }
                    } else {
                        // If the user couldn't connect, the db might be corrupt so try to upload the backup
                        self.showGenericAlert(message: "This file might not have uploaded correctly. A backup of the file has also been uploaded as a measure of safety.", title: "Possible upload failure")
                        self.uploadFile(self.uploadFolderName ?? "", filePath: backupPath, uploadedFileName: fileName.replacingOccurrences(of: ".db", with: "_backup.db"), MIMEType: "application/x-sqlite3") { (fileID, error) in uploadError = error}
                    }
                }
            }
            // Check if there was an error outside the completion closure because appending to a var inside the closure doesn't work
            if uploadError == nil {
                successfulFiles.append(fileName)
            } else {
                failedFiles.append(fileName)
            }
            nFiles += 1
        }
        
        let userName = (self.userNameLabel.text)?.split(separator: "@").first ?? ""
        // Let the user know if the upload was successful
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        if badFiles.count > 0 {
            let badFileString = badFiles.joined(separator: "\n")
            alertController.message = "The data for the following files might not have uploaded properly. Press OK to continue and then verify that the uploads were successful and/or there is a file with \"_backup_\" in the name uploaded to Google Drive for each of the following files: \n\n\(badFileString)"
            alertController.title = "Possible invalid data file(s)"
        } else if successfulFiles.count == nFiles {
            alertController.title = "File upload successful"
            alertController.message = "Your data were successfull uploaded to \(userName)'s Google Drive account."
        } else if failedFiles.count == nFiles {
            alertController.title = "File upload failed"
            alertController.message = "All file uploads to \(userName)'s Google Drive account failed. Make sure you're connected to the internet and you used the correct Google account to log in, then try again."
        } else {
            let failedFileString = failedFiles.joined(separator: "\n")
            alertController.title = "Only \(successfulFiles.count) of \(nFiles) files uploaded"
            alertController.message = "All files were uploaded successfully to \(userName)'s Google Drive account except: \n\n\(failedFileString)\n\n Make sure your internet connection is reliable and try again."
        }
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {handler in
            self.dismiss(animated: true, completion: nil)
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func selectFileButtonPressed() {
        self.dbBrowserViewController.delegate = self
        present(self.dbBrowserViewController, animated: true, completion: {self.dbBrowserViewController.isLoadingDatabase = false})
    }
    
    
    //MARK: - DBBrowserViewControllerDelegate
    func updateSelectedFiles(value: Any?) {
        guard let filesFromDBController = value as? [String] else {
            print("Could not convert value to String Array: \(String(describing: value))")
            os_log("Could not convert value to String Array in GoogleDriveUploadController.updateSelectedFiles()", log: .default, type: .debug)
            return
        }
        
        self.selectedFiles = filesFromDBController
        self.fileTableView.files = filesFromDBController
    }
    
    func updateTableViewHeight() {
        
        self.tableViewHeightConstraint.constant = min(self.maxTableViewHeight, self.preferredCellSize * CGFloat(self.selectedFiles.count))
        self.fileTableView.setNeedsLayout()
        self.fileTableView.layoutIfNeeded()
        
    }
    
    
    //MARK:- GIDSignInUIDelegate methods
    // Stop the UIActivityIndicatorView animation that was started when the user
    // pressed the Sign In button
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        //myActivityIndicator.stopAnimating()
    }
    
    // Present a view that prompts the user to sign in with Google
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        self.present(viewController, animated: true, completion: nil)
    }
    
    // Dismiss the "Sign in with Google" view
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK:- GIDSignInDelegate method
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            self.driveService.authorizer = nil
            os_log("Google sign in failed", log: OSLog.default, type: .debug)
            let errorDescription = error.localizedDescription
            if errorDescription != "The user canceled the sign-in flow." {
                showGenericAlert(message: "Google sign-in failed because \(error.localizedDescription)", title: "Google sign-in failed")
            }
        } else {
            // Perform any operations on signed in user here.
            self.userNameLabel.text = user.profile.email
            self.googleIcon.isHidden = false
            self.uploadButton.isEnabled = true
            self.signInButton.isHidden = true
            self.driveService.authorizer = user.authentication.fetcherAuthorizer()
            
            // Create a folder name with a datestamp tag. If the folder already exists, the selected files will just get uploaded there
            let formatter = DateFormatter()
            formatter.timeStyle = .none//.short//
            formatter.dateStyle = .short
            let now = Date()
            let timestamp = "\(formatter.string(from: now))_\(getCleanedDeviceName() ?? UIDevice.current.name)"
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "’", with: "-")
                .replacingOccurrences(of: "'", with: "-")
                .replacingOccurrences(of: ":", with: "-")
            let folderName = "savageChecker_data_\(timestamp)"
            
            // If the folder doesn't exist, create it here because GDrives annoying lazy execution will create the folder and files all at once.
            //  This means that, even though createFolder() is called before the uploads, it doesn't actually exist so the uploadFiles() function
            //  thinks it needs to create the folder for each file (if there are multiple files)
            search(folderName) { (folderID, error) in
                if folderID == nil {
                    let _ = self.createFolder(folderName) { (folderID, error) in
                    }
                }
                self.uploadFolderName = folderName
            }
        }
    }

}


protocol DBBrowserViewControllerDelegate {
    func updateSelectedFiles(value: Any?)
}


// Make this view it's own class so the height can be easily adjusted
class FileTableView: UIControl, UITableViewDelegate, UITableViewDataSource  {
    
    //MARK: Properties
    var files = [String]()
    var tableView = UITableView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(tableView)
        
        self.tableView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.tableView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.tableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        self.tableView.layer.borderWidth = 0.5
        //self.tableView.layer.borderColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1).cgColor
        //self.tableView.layer.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.2).cgColor
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.files[indexPath.row]
        cell.backgroundColor = UIColor.clear
        cell.layer.borderWidth = 0
        cell.layer.borderColor = UIColor.clear.cgColor
        cell.textLabel?.textAlignment = .left
        cell.selectionStyle = .none
        
        return cell
    }
    
}
