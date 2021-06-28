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
    @IBOutlet weak var faceDetectionButton: UIButton!
    @IBAction func faceDetectionButtonTapped(_ sender: Any) {
        self.goToFaceDetectionVC()
    }
    
    // MARK: - Properties
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    ///
    /// Go to Face Detection ViewController.
    ///
    private func goToFaceDetectionVC() {
        self.navigationController?.pushViewController(FaceDetectionViewController(), animated: true)
    }
}
