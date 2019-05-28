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
//        SaveButton.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
//        BackButton.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
        
        showImage()
        ButtonLayout()
        // Do any additional setup after loading the view.
    }
    
    private func ButtonLayout() {
        BackButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor)
        BackButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor)
        BackButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor)
        BackButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        
        SaveButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor)
        SaveButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor)
        SaveButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor)
        SaveButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        
        SaveButton.translatesAutoresizingMaskIntoConstraints = false
        BackButton.translatesAutoresizingMaskIntoConstraints = false
        //SaveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        SaveButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 35).isActive = true
        SaveButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
        BackButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        BackButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 40).isActive = true
        
        SaveButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        SaveButton.heightAnchor.constraint(equalToConstant: 75).isActive = true
    
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
            //let backToVC = performSegue(withIdentifier: "backbutton", sender: self)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self]_ in
                //self?.performSegue(withIdentifier: "backButton", sender: nil)
                self!.dismiss(animated: true, completion: nil)
            }))
            present(ac, animated: true)
            
            UserDefaults.standard.removeObject(forKey: "key\(imageSequenceNumber)")
            
            
        }
        
    }
    
}


