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
    private var captureDevice: AVCaptureDevice?
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var faceRectangleLayer = CAShapeLayer()
    private var faceLandmarksLayer = CAShapeLayer()
    //private var shapeLayer = CAShapeLayer()
    
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    private let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
    private let requestHandler = VNSequenceRequestHandler()
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.checkCameraPermission()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.previewLayer.frame = self.view.frame
        self.faceRectangleLayer.frame = self.view.frame
        self.faceLandmarksLayer.frame = self.view.frame
        self.faceLandmarksLayer.setAffineTransform(CGAffineTransform(scaleX: 1, y: -1))
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
        
        // Add the PreviewLayer (video data output) to the view.
        self.previewLayer.session = self.captureSession
        
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
        
        // Add the faceRectangleLayer to draw the face rectangle to the view.
        self.view.layer.addSublayer(self.faceRectangleLayer)
        
        // Add the faceLandmarkLayer to draw the face landmarks to the view.
        self.view.layer.addSublayer(self.faceLandmarksLayer)
        
        // Create the data output and add it to the session.
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue")) // To run the method to detect Faces.
        self.captureSession.addOutput(dataOutput)
    }
    
    ///
    /// Detect faces on an image.
    ///
    private func detectFaces(on image: CIImage) {
        
        // Clear previous face rectangle and face landmarks layer from detected faces.
        DispatchQueue.main.async {
            self.faceRectangleLayer.sublayers?.removeAll()
            self.faceLandmarksLayer.sublayers?.removeAll()
        }
        
        do {
            try self.requestHandler.perform([self.faceDetectionRequest], on: image)
            
            if let results = self.faceDetectionRequest.results as? [VNFaceObservation] {
                print("Faces detected: \(results.count)")
                
                if !results.isEmpty {
                    // Draw a rectangle over each detected face.
                    for faceObservation in results {
                        self.drawFaceRectangle(at: faceObservation.boundingBox)
                    }
                    
                    // Detect face landmarks.
                    self.faceLandmarksRequest.inputFaceObservations = results // ¿?
                    self.detectFaceLandmarks(on: image)
                }
            } else {
                print("No faces detected")
            }
            
        } catch let error {
            print("Failed to handler FaceDetectionRequest: \(error.localizedDescription)")
        }
    }
    
    ///
    /// Detect face landmarks on an image.
    /// - Face contour
    /// - Left eyebrow
    /// - Left eye
    /// - Left eye pupil
    /// - Right eyebrow
    /// - Right eye
    /// - Right eye pupil
    /// - Nose
    /// - Nose crest
    /// - Lips
    /// - Outer lips
    ///
    private func detectFaceLandmarks(on image: CIImage) {
        do {
            try self.requestHandler.perform([self.faceLandmarksRequest], on: image)
            
            if let results = self.faceLandmarksRequest.results as? [VNFaceObservation],
               let boundingBox = self.faceLandmarksRequest.inputFaceObservations?.first?.boundingBox {
                for faceObservation in results {
                    self.drawFaceLandmark(at: faceObservation.landmarks?.faceContour, boundingBox: boundingBox)
                    self.drawFaceLandmark(at: faceObservation.landmarks?.leftEyebrow, boundingBox: boundingBox)
                    self.drawFaceLandmark(at: faceObservation.landmarks?.leftEye, boundingBox: boundingBox)
                    self.drawFaceLandmark(at: faceObservation.landmarks?.leftPupil, boundingBox: boundingBox)
                    self.drawFaceLandmark(at: faceObservation.landmarks?.rightEyebrow, boundingBox: boundingBox)
                    self.drawFaceLandmark(at: faceObservation.landmarks?.rightEye, boundingBox: boundingBox)
                    self.drawFaceLandmark(at: faceObservation.landmarks?.rightPupil, boundingBox: boundingBox)
                    self.drawFaceLandmark(at: faceObservation.landmarks?.nose, boundingBox: boundingBox)
                    self.drawFaceLandmark(at: faceObservation.landmarks?.noseCrest, boundingBox: boundingBox)
                    self.drawFaceLandmark(at: faceObservation.landmarks?.innerLips, boundingBox: boundingBox)
                    self.drawFaceLandmark(at: faceObservation.landmarks?.outerLips, boundingBox: boundingBox)
                }
            } else {
                print("No face landmark detected.")
            }
        } catch let error {
            print("Failed to handler FaceLandmarksRequest: \(error.localizedDescription)")
        }
    }
    
    ///
    /// Convert the bounding box from the detected face to a new bounding box compatible with the screen.
    /// The new bounding box will be used to draw the rectangle in place on the screen.
    ///
    private func convertBoundingBox(detected: CGRect) -> CGRect {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.view.frame.height)
        let translate = CGAffineTransform.identity.scaledBy(x: self.view.frame.width, y: self.view.frame.height)
        let newBoundingBox = detected.applying(translate).applying(transform)
        return newBoundingBox
    }
    
    ///
    /// Convert the points of a face landmark.
    ///
    private func convertFaceLandmarkPoints(detected: [CGPoint], boundingBox: CGRect) -> [CGPoint] {
        var landmarkPoints: [CGPoint] = []
        
        let x = boundingBox.origin.x * self.view.bounds.size.width
        let y = boundingBox.origin.y * self.view.bounds.size.height
        let w = boundingBox.size.width * self.view.bounds.size.width
        let h = boundingBox.size.height * self.view.bounds.size.height
        
        for point in detected {
            let pointX: CGFloat = x + point.x * w
            let pointY: CGFloat = y + point.y * h
            
            let landmarkPoint: CGPoint = CGPoint(x: pointX, y: pointY)
            landmarkPoints.append(landmarkPoint)
        }
        
        return landmarkPoints
    }
    
    ///
    /// Draw a rectangle on top of the detected face position.
    ///
    private func drawFaceRectangle(at position: CGRect) {
        DispatchQueue.main.async {
            // Convert the boundingBox.
            let newBoundingBox = self.convertBoundingBox(detected: position)
            
            // Create the Shape layer.
            let faceBoundingBoxShape = CAShapeLayer()
            faceBoundingBoxShape.path = CGPath(rect: newBoundingBox, transform: nil)
            faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
            faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
            faceBoundingBoxShape.lineWidth = 2.0
            
            // Add and display the new shape layer.
            self.faceRectangleLayer.addSublayer(faceBoundingBoxShape)
        }
    }
    
    ///
    /// Draw face landmark.
    ///
    private func drawFaceLandmark(at landmark: VNFaceLandmarkRegion2D?, boundingBox: CGRect) {
        guard let landmark = landmark,
              landmark.normalizedPoints.count > 0 else { return }
        
        DispatchQueue.main.async {
            // Convert points.
            let landmarkPoints: [CGPoint] = self.convertFaceLandmarkPoints(detected: landmark.normalizedPoints, boundingBox: boundingBox)
            
            // Draw landmark.
            let newFaceLandmarkLayer = CAShapeLayer()
            newFaceLandmarkLayer.strokeColor = UIColor.red.cgColor
            newFaceLandmarkLayer.lineWidth = 2.0
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: landmarkPoints[0].x, y: landmarkPoints[0].y))
            
            for i in 0..<landmarkPoints.count - 1 {
                let point = CGPoint(x: landmarkPoints[i].x, y: landmarkPoints[i].y)
                path.addLine(to: point)
                path.move(to: point)
            }
            path.addLine(to: CGPoint(x: landmarkPoints[0].x, y: landmarkPoints[0].y))
            newFaceLandmarkLayer.path = path.cgPath
            
            self.faceLandmarksLayer.addSublayer(newFaceLandmarkLayer)
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
