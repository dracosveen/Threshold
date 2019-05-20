//
//  PluginOneImageViewController.swift
//  Threshold
//
//  Created by Martin Adolfsson on 5/14/19.
//  Copyright © 2019 Martin Adolfsson. All rights reserved.
//

import UIKit

class PluginOneImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var SaveButton: UIButton!
    @IBOutlet weak var BackButton: UIButton!
    var imageSequenceNumber = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.SaveButton.frame = .init(x: 330, y: 40, width: 75, height: 75)
        self.BackButton.frame = .init(x: 30, y: 40, width: 75, height: 75)
        
        SaveButton.translatesAutoresizingMaskIntoConstraints = true
        BackButton.translatesAutoresizingMaskIntoConstraints = true
        SaveButton.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
        BackButton.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
        
        showImage()
        // Do any additional setup after loading the view.
    }
    
    
    private func showImage() {
        imageView.frame = self.view.bounds
        
        imageView.translatesAutoresizingMaskIntoConstraints = true
        
        imageView.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
        
        let inputImage = UserDefaults.standard.data(forKey: "key\(imageSequenceNumber)")
        imageView.image = UIImage(data: inputImage!)
        
        print(UserDefaults.standard.integer(forKey: "key\(imageSequenceNumber)"))
        
    }
    
    @IBAction func backButton(_ sender: Any) {
        
        performSegue(withIdentifier: "backButton", sender: Any?.self)
        UserDefaults.standard.removeObject(forKey: "key\(imageSequenceNumber)")
    }
    
    
    @IBAction func saveButton(_ sender: Any) {
        UIImageWriteToSavedPhotosAlbum(imageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)    }
    
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Image saved to library.", preferredStyle: .alert)
            //let backToVC = performSegue(withIdentifier: "backbutton", sender: self)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.performSegue(withIdentifier: "backButton", sender: nil)
            }))
            present(ac, animated: true)
            
            UserDefaults.standard.removeObject(forKey: "key\(imageSequenceNumber)")
            
            
        }
        
    }
    
}


