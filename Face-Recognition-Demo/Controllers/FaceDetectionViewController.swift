//
//  FaceDetectionViewController.swift
//  Face-Recognition-Demo
//
//  Created by Aitor Zubizarreta Perez on 27/06/2021.
//  Copyright © 2021 Aitor Zubizarreta. All rights reserved.
//

import UIKit
import AVFoundation

class FaceDetectionViewController: UIViewController {
    
    // MARK: - UI Elements
    
    // MARK: - Properties
    
    var captureSession: AVCaptureSession?
    var captureDevice: AVCaptureDevice?
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.checkCameraPermission()
    }
    
    ///
    /// Check if the user granted permission to use the camera.
    ///
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera permission: Authorized")
            self.setupCameraSession()
        case .notDetermined:
            print("Camera permission: Not Determined")
            self.askCameraPermission()
        case .denied:
            print("Camera permission: Denied")
        case .restricted:
            print("Camera permission: Restricted")
        default:
            print("Camera permission: ¿Default?")
        }
    }
    
    ///
    /// Ask permission to the user to access the camera.
    ///
    private func askCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            if granted {
                print("Permission granted.")
            } else {
                print("The user has NOT granted access to the camera.")
            }
        }
    }
    
    ///
    /// Setup the AVCameraSession.
    ///
    private func setupCameraSession() {
        // Create the Capture Session.
        self.captureSession = AVCaptureSession()
        
        // Find a list of cameras from the Device.
        let discoverSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera, .builtInTrueDepthCamera],
                                                               mediaType: .video,
                                                               position: .front)
        let devices = discoverSession.devices
        
        // Check if there are any cameras and if so select the first one.
        if !devices.isEmpty {
            self.captureDevice = devices.first
            self.displayCameraOutput()
        } else {
            print("No cameras")
        }
    }
    
    ///
    /// Display the image from the selected camera.
    ///
    private func displayCameraOutput() {
        guard let videoCaptureDevice = self.captureDevice,
              let _ = self.captureSession,
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              self.captureSession!.canAddInput(videoDeviceInput) else { return }
        
        // Add the device input  to the session.
        self.captureSession!.addInput(videoDeviceInput)
        
        // Start the session.
        self.captureSession!.startRunning()
        
        // Create the preview layer.
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
        self.view.layer.addSublayer(previewLayer)
        previewLayer.frame = UIScreen.main.bounds // FIXME: - Get the correct size for the preview layer.
        
        // Create the data output and add it to the session.
        let dataOutput = AVCaptureVideoDataOutput()
        self.captureSession!.addOutput(dataOutput)
    }
}
