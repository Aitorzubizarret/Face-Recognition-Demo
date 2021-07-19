//
//  MainViewController.swift
//  Face-Recognition-Demo
//
//  Created by Aitor Zubizarreta Perez on 24/06/2021.
//  Copyright © 2021 Aitor Zubizarreta. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    // MARK: - UI Elements
    
    @IBOutlet weak var faceDetectionFromCameraButton: UIButton!
    @IBAction func faceDetectionFromCameraButtonTapped(_ sender: Any) {
        self.goToFaceDetectionVC()
    }
    @IBOutlet weak var faceDetectionFromImageButton: UIButton!
    @IBAction func faceDetectionFromImageButtonTapped(_ sender: Any) {
    }
    
    
    // MARK: - Properties
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Face Recognition Demo"
    }
    
    ///
    /// Go to Face Detection ViewController.
    ///
    private func goToFaceDetectionVC() {
        self.navigationController?.pushViewController(FaceDetectionViewController(), animated: true)
    }
}
