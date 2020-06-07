//
//  PluginOneImageViewController.swift
//  Threshold
//
//  Created by Martin Adolfsson on 5/14/19.
//  Copyright © 2019 Martin Adolfsson. All rights reserved.
//

import UIKit
import Photos
import RealmSwift

class ImageViewController: UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var SaveButton: UIButton!
    @IBOutlet weak var BackButton: UIButton!
    var onDismiss: (() -> Void)?
    
    var imageSequenceNumber = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showImage()
        
        // Do any additional setup after loading the view.
    }
    
    private func showImage() {
        
        let inputImage = UserDefaults.standard.data(forKey: "key\(imageSequenceNumber)")
        imageView.image = UIImage(data: inputImage!)
        
    }
    
    @IBAction func backButton(_ sender: Any) {
        onDismiss?()
        dismiss(animated: true, completion: nil)
        UserDefaults.standard.removeObject(forKey: "key\(imageSequenceNumber)")
        
    }
    func getCaptureDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let captureDate = formatter.string(from: date)
        //print(captureDate)
        return captureDate
    }
    
    @IBAction func saveButton(_ sender: Any) {
        onDismiss?()
        UIImageWriteToSavedPhotosAlbum(imageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        let newImage: UIImage = imageView.image!
        let imageFileName = "\(UUID().uuidString).png"
        let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageFileName)
        
        let data = newImage.upOrientationImage()?.jpegData(compressionQuality: 0.8)
        do {
            try data?.write(to: URL(fileURLWithPath: imagePath))
        } catch {
            print("error")
        }
        
        let realm = try! Realm()
        try! realm.write {
            
            let addedFilePath = StoredImage()
            addedFilePath.filepath = imageFileName
            addedFilePath.created = getCaptureDate()
            realm.add(addedFilePath)
            //print(addedFilePath)
        }
    }
    
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Image saved to library.", preferredStyle: .alert)
            
//            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self]_ in
//                self!.dismiss(animated: true, completion: nil)
//            }))
            self.dismiss(animated: true, completion: nil)
            present(ac, animated: true)
            
            UserDefaults.standard.removeObject(forKey: "key\(imageSequenceNumber)")
            
            
        }
        
    }
}


