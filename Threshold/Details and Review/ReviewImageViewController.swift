//
//  ReviewImageViewController.swift
//  Threshold
//
//  Created by Martin Adolfsson on 5/5/20.
//  Copyright © 2020 Martin Adolfsson. All rights reserved.
//

import UIKit

class ReviewImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    
    
    var selectedImage = UIImage()
    var date = ""
    var distance = Float(0)
    

    override func viewDidLoad() {
        super.viewDidLoad()
        showImage()
        // Do any additional setup after loading the view.
    }

    private func showImage() {
        
        imageView.image = selectedImage
        dateLabel.text = date
        let dist = String(format: "%.2f", (distance))
        self.distanceLabel.text = "\(dist)"
        
    }

}
