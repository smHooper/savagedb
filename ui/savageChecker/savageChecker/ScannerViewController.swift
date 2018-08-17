//
//  ScannerViewController.swift
//  savageChecker
//
//  Created by Sam Hooper on 8/8/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import AVFoundation
import UIKit

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
    
    
    // Lock device orientation
    /*override var shouldAutorotate: Bool {
        return true
    }*/
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        self.captureSession = AVCaptureSession()
        
        setAutoRotation(value: false)
        
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
    
    // Prevent rotation by passing the current orientation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: self.portraitDeviceSize, with: coordinator)
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
        
        // Reset autorotation to true
        setAutoRotation(value: true)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        
        // Prepare and move to the appropriate view controller
        dismiss(animated: true)
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
    
    func found(code: String) {
        // parse code
        // get vehicle type and use dictionary to present appropriate view controller. Maybe vehicle type is first item followed by :, then rest is comma-delimited
        //  each view controller should have its own method for parsing the string
        print(code)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
