//
//  CaptureButtonClass.swift
//  Threshold
//
//  Created by Martin Adolfsson on 6/10/19.
//  Copyright © 2019 Martin Adolfsson. All rights reserved.
//

import UIKit

class CaptureButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame:frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func doLayout(parent: UIView) {
    
        // Size the button in preportion to the view
        let buttonSize = frame.width * 0.25
        
        // Distance from bottom of the view
        let distanceFromBottom: CGFloat = 80.0
        
        // Position the button
        centerXAnchor.constraint(equalTo: parent.centerXAnchor).isActive = true
        bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: distanceFromBottom * -1).isActive = true
        
        // Set the button size
        widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
        
        // Set the corder radius
        layer.cornerRadius = buttonSize / 2
        clipsToBounds = true
        
        // Style the button
        backgroundColor = .white
        translatesAutoresizingMaskIntoConstraints = false
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 10
        //        captureButton.setTitle("", for: .normal)
        
    }
}
