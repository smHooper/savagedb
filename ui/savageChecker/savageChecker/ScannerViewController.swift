//
//  ScannerViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 8/8/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import AVFoundation
import UIKit
import SQLite
import os.log

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var metadataOutput = AVCaptureMetadataOutput()
    var captureButton = UIButton()
    let buttonSpacing: CGFloat = 40
    let buttonSize: CGFloat = 75
    let portraitDeviceSize: CGSize = {
        let deviceSize = UIScreen.main.bounds.size
        let maxDimension = max(deviceSize.width, deviceSize.height)
        let minDimension = min(deviceSize.width, deviceSize.height)
        
        return CGSize(width: minDimension, height: maxDimension)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        self.captureSession = AVCaptureSession()
        
        
        // Configure the video capture device
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            try videoCaptureDevice.lockForConfiguration()
            self.captureSession.beginConfiguration()
            videoCaptureDevice.focusMode = .continuousAutoFocus
            videoCaptureDevice.exposureMode = .continuousAutoExposure
            videoCaptureDevice.autoFocusRangeRestriction = .near
            self.captureSession.commitConfiguration()
            videoCaptureDevice.unlockForConfiguration()
        } catch {
            return
        }
        
        // Check to make sure the capture session can add input and output
        if (self.captureSession.canAddInput(videoInput)) {
            self.captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        setMetadataOutput()
    
        // Set up the video on screen
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer.frame = self.view.frame
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        
        /*// Set up buttons
        self.captureButton = UIButton(type: .custom)
        self.captureButton.setImage(UIImage(named: "startScanIcon"), for: .normal)
        self.view.addSubview(self.captureButton)
        self.captureButton.translatesAutoresizingMaskIntoConstraints = false
        self.captureButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -self.buttonSpacing).isActive = true
        self.captureButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -self.buttonSpacing).isActive = true
        self.captureButton.widthAnchor.constraint(equalToConstant: self.buttonSize).isActive = true
        self.captureButton.heightAnchor.constraint(equalToConstant: self.buttonSize).isActive = true
        self.captureButton.addTarget(self, action: #selector(captureButtonPressed), for: .touchUpInside)*/
        
        let cancelButton = UIButton(type: .custom)
        self.view.addSubview(cancelButton)
        cancelButton.setImage(UIImage(named: "cancelScanIcon"), for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -self.buttonSpacing).isActive = true
        cancelButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        cancelButton.widthAnchor.constraint(equalToConstant: self.buttonSize).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: self.buttonSize).isActive = true
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)

        self.view.bringSubview(toFront: cancelButton)
        //self.view.bringSubview(toFront: self.captureButton)
        
        self.captureSession.startRunning()
    }

    
    func failed() {
        let alert = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        self.captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (self.captureSession?.isRunning == false) {
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (self.captureSession?.isRunning == true) {
            self.captureSession.stopRunning()
        }

    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            qrFound(qrString: stringValue)
        }
    }
    
    func setMetadataOutput () {
        
        if (self.captureSession.canAddOutput(self.metadataOutput)) {
            self.captureSession.addOutput(self.metadataOutput)
            self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            self.metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
    }
    
    @objc func captureButtonPressed() {
        if !self.captureSession.isRunning {
            setMetadataOutput()
            //self.captureSession.startRunning()
            self.captureButton.setImage(UIImage(named: "stopScanIcon"), for: .normal)
        } else {
            //self.captureSession.stopRunning()
            self.captureSession.removeOutput(self.metadataOutput)
            self.captureButton.setImage(UIImage(named: "startScanIcon"), for: .normal)
        }
    }
    
    @objc func cancelButtonPressed() {
        dismiss(animated: true)
    }
    
    
    func showCodeReadErrorAlert(alertMessage: String) {
        let alertTitle = "QR Code read error"
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel scan", style: .cancel, handler: {handler in self.dismiss(animated: true, completion: nil)}))
        alertController.addAction(UIAlertAction(title: "Try again", style: .default, handler: {handler in self.captureSession.startRunning()}))
        present(alertController, animated: true, completion: nil)
    }
    
    func sanitizeQRString(qrString: String)-> String {
        // Some permits created with an early version of the front end weren't quoted correctly, so handle those properly
        var qr_items = [String]()
        for item in qrString.split(separator: ",") {
            if let property = item.split(separator: ":").first, let value = item.split(separator: ":").last {
                let this_property = property.replacingOccurrences(of: "{", with: "").trimmingCharacters(in: .whitespaces)
                let this_value = value.replacingOccurrences(of: "}", with: "").trimmingCharacters(in: .whitespaces)
                let trimmed_property = this_property.hasPrefix("\"") ?
                    "\(this_property.trimmingCharacters(in: .whitespaces))" :
                "\"\(this_property.trimmingCharacters(in: .whitespaces))\""
                let trimmed_value = this_value.trimmingCharacters(in: .whitespaces).hasPrefix("\"") ?
                    "\(this_value.trimmingCharacters(in: .whitespaces))" :
                "\"\(this_value.trimmingCharacters(in: .whitespaces))\""
                qr_items.append("\(trimmed_property): \(trimmed_value)")
            }
        }
        return "{\(qr_items.joined(separator: ", "))}"
    }
    
    func showVehicleViewController(qrString: String, vehicleType: String) {
        if let viewController = observationViewControllers[vehicleType]?.init() {
            viewController.qrString = qrString
            viewController.isAddingNewObservation = true
            viewController.session = loadSession()
            viewController.modalPresentationStyle = .fullScreen
            viewController.title = "New \(vehicleType) Observation"
            present(viewController, animated: true, completion: nil)//{self.presentingViewController?.dismiss(animated: false, completion: nil)})
        } else {
            let typesString = Array(observationViewControllers.keys).joined(separator: "\n")
            let alertMessage = "The vehicle type '\(vehicleType)' from the QR code string '\(qrString)' did not match one of these types: \n\n\(typesString)\n"
            showCodeReadErrorAlert(alertMessage: alertMessage)
        }
    }
    
    func qrFound(qrString: String) {
        // parse code from format <label: comma-separated string>
        if let data = sanitizeQRString(qrString: qrString).data(using: .utf8) {
            // Try to read it as a JSON struct (from JSONParser)
            if let jsonObject = try? JSON(data: data) {
                let vehicleType = jsonObject["vehicle_type"].string ?? ""
                let inholderName = jsonObject["Permit holder"].string ?? ""
                let rightOfWayText = "Right of Way"
                let lodgeBusText = "Lodge Bus"
                if vehicleType == rightOfWayText && lodges.contains(inholderName){
                    let alertTitle = "Right of Way or Lodge Bus?"
                    //let alertMessageText = "This permit was recorded as a \(rightOfWayText) vehicle. Is it supposed to be a \(rightOfWayText) or a \(lodgeBusText)?"
                    let boldAttribute = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize + 2)]
                    let attributedROWString = NSMutableAttributedString(string: rightOfWayText, attributes: boldAttribute)
                    let attributedBusString = NSMutableAttributedString(string: lodgeBusText, attributes: boldAttribute)
                    
                    let attributedMessageString = NSMutableAttributedString(string: "\nThis permit was recorded as a \(rightOfWayText) vehicle. Is it supposed to be a ")
                    attributedMessageString.append(attributedROWString)
                    attributedMessageString.append(NSMutableAttributedString(string: " or a "))
                    attributedMessageString.append(attributedBusString)
                    attributedMessageString.append(NSMutableAttributedString(string: "?"))
                    
                    let alertController = UIAlertController(title: alertTitle, message: "", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: rightOfWayText, style: .default, handler: {handler in
                        self.showVehicleViewController(qrString: qrString, vehicleType: rightOfWayText)
                    }))
                    alertController.addAction(UIAlertAction(title: lodgeBusText, style: .default, handler: {handler in
                        // The lodge name is given with the "Permit holder" key so replace it so that the lodge field autopopulates
                        let correctedQRString = qrString.replacingOccurrences(of:"Permit holder", with: "Lodge")
                        self.showVehicleViewController(qrString: correctedQRString, vehicleType: lodgeBusText)
                    }))
                    
                    alertController.setValue(attributedMessageString, forKey: "attributedMessage")
                    
                    present(alertController, animated: true, completion: nil)
                } else {
                    showVehicleViewController(qrString: qrString, vehicleType: vehicleType)
                }
                

            } else {
                showCodeReadErrorAlert(alertMessage: "String from QR code not understood: \(qrString)")
            }
        } else {
            showCodeReadErrorAlert(alertMessage: "String from QR code not understood: \(qrString)")
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private func loadSession() -> Session? {
        // ************* check that the table exists first **********************
        var rows = [Row]()
        let db: Connection!
        let sessionsTable = Table("sessions")
        let idColumn = Expression<Int64>("id")
        let observerNameColumn = Expression<String>("observer_name")
        let dateColumn = Expression<String>("date")
        let openTimeColumn = Expression<String>("open_time")
        let closeTimeColumn = Expression<String>("close_time")
        do {
            db = try Connection(dbPath)
            rows = Array(try db.prepare(sessionsTable))
        } catch {
            showGenericAlert(message: "Error loading shift info: \(error.localizedDescription)")
            os_log("Error loading session", log: OSLog.default, type: .debug)
        }
        if rows.count > 1 {
            //fatalError("Multiple sessions found")
            os_log("Multiple sessions found", log: OSLog.default, type: .debug)
        }
        
        var session: Session?
        for row in rows{
            session = Session(id: Int(row[idColumn]), observerName: row[observerNameColumn], openTime:row[openTimeColumn], closeTime: row[closeTimeColumn], givenDate: row[dateColumn])
        }
        
        return session
    }
}
