//
//  FaceDetectionViewController.swift
//  Face-Recognition-Demo
//
//  Created by Aitor Zubizarreta Perez on 27/06/2021.
//  Copyright © 2021 Aitor Zubizarreta. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class FaceDetectionViewController: UIViewController {
    
    // MARK: - UI Elements
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession = AVCaptureSession()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var captureDevice: AVCaptureDevice?
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.checkCameraPermission()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.previewLayer.frame = self.view.frame
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
                
                DispatchQueue.main.async {
                    self.setupCameraSession()
                }
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
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              self.captureSession.canAddInput(videoDeviceInput) else { return }
        
        // Add the device input  to the session.
        self.captureSession.addInput(videoDeviceInput)
        
        // Start the session.
        self.captureSession.startRunning()
        
        // Add the PreviewLayer to the view.
        self.previewLayer.session = self.captureSession
        
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
        
        // Create the data output and add it to the session.
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue")) // To run the method to detect Faces.
        self.captureSession.addOutput(dataOutput)
    }
    
    ///
    /// Detect faces on an image.
    ///
    private func detectFaces(on image: CIImage) {
        let faceDetectionRequest = VNDetectFaceRectanglesRequest()
        let requestHandler = VNSequenceRequestHandler()
        
        do {
            try requestHandler.perform([faceDetectionRequest], on: image)
            
            if let results = faceDetectionRequest.results {
                print("Faces detected: \(results.count)")
            } else {
                print("No faces detected")
            }
        } catch let error {
            print("Failed to handler FaceDetectionRequest: \(error.localizedDescription)")
        }
    }
    
}

// MARK: - AVCapture Video Data Output Sample Buffer Delegate

extension FaceDetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    ///
    /// Detect Faces.
    ///
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Create a CIImage from the pixelBuffer.
        var ciImage: CIImage = CIImage(cvImageBuffer: pixelBuffer)
        ciImage = ciImage.oriented(.leftMirrored)
        
        // Detect faces on the image.
        self.detectFaces(on: ciImage)
    }
    
}
