//
//  ViewController.swift
//  Threshold
//
//  Created by Martin Adolfsson on 5/14/19.
//  Copyright © 2019 Martin Adolfsson. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
}

extension UIButton {
    
    func createRectangleButton(buttonPositionX: Double, buttonPositionY: Double ,buttonWidth: Double, buttonHeight: Double, buttonTilte: String) {
        let button = self // changes made here
        button.frame = CGRect(x: buttonPositionX, y: buttonPositionY, width: buttonWidth, height: buttonHeight)
        button.setTitle(buttonTilte, for: .normal)
        button.backgroundColor = .white
        button.tintColor = .black
        button.layer.cornerRadius = button.frame.size.width / 2
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 10.0
        
}
}

extension UIImage {
    func upOrientationImage() -> UIImage? {
        switch imageOrientation {
        case .up:
            return self
        default:
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            draw(in: CGRect(origin: .zero, size: size))
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return result
        }
    }
}
