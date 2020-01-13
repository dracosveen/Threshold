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
        showImage()
        
        // Do any additional setup after loading the view.
    }
    
    private func showImage() {
        //imageView.frame = self.view.bounds
        
        //imageView.translatesAutoresizingMaskIntoConstraints = true
        
        //imageView.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
        
        let inputImage = UserDefaults.standard.data(forKey: "key\(imageSequenceNumber)")
        imageView.image = UIImage(data: inputImage!)
        print(UserDefaults.standard.integer(forKey: "key\(imageSequenceNumber)"))
        
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self]_ in
                self!.dismiss(animated: true, completion: nil)
            }))
            present(ac, animated: true)
            
            UserDefaults.standard.removeObject(forKey: "key\(imageSequenceNumber)")
            
            
        }
        
    }
    
}


