//
//  WelcomeViewController.swift
//  Threshold
//
//  Created by Martin Adolfsson on 5/19/20.
//  Copyright © 2020 Martin Adolfsson. All rights reserved.
//

import UIKit
import OpalImagePicker
import Photos
import RealmSwift

class WelcomeViewController: UIViewController, OpalImagePickerControllerDelegate {


    @IBOutlet weak var imagePickerButton: UIButton!
    @IBOutlet weak var cameraBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func imagePickerBtnTocuhed(_ sender: UIButton) {
        let imagePicker = OpalImagePickerController()
        presentOpalImagePickerController(imagePicker, animated: true,
            select: { (assets) in
                print(assets)
                for temp in assets {
                    temp.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (editingInput, info) in
                        let newImage: UIImage = (editingInput?.displaySizeImage)!
                        let imageFileName = "\(UUID().uuidString).png"
                        let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageFileName)
                        //let imageSize = newImage.resized(to: CGSize(width: 800, height: T##CGFloat))
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
                              //addedFilePath.created = getCaptureDate()
                              realm.add(addedFilePath)
                              print(addedFilePath)
                            self.performSegue(withIdentifier: "cameraSegue", sender: Any?.self)
                          }
                    }
                }
                
            }, cancel: {
                self.performSegue(withIdentifier: "cameraSegue", sender: Any?.self)
            })
    }
    
    @IBAction func cameraBtnTouched(_ sender: Any) {
        performSegue(withIdentifier: "cameraSegue", sender: Any?.self)
    }

}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
