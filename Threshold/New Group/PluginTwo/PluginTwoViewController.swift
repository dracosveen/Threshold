//
//  PluginTwoViewController.swift
//  Threshold
//
//  Created by Martin Adolfsson on 5/15/19.
//  Copyright © 2019 Martin Adolfsson. All rights reserved.
//

import UIKit

class PluginTwoViewController: UIViewController {

    
    @IBOutlet weak var StayTunedLabel: UILabel!
    
    var screenLeftEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenLeftEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwipedLeft))
        screenLeftEdgeRecognizer.edges = .left
        view.addGestureRecognizer(screenLeftEdgeRecognizer)

        // Do any additional setup after loading the view.
        
        StayTunedLabel.textAlignment = .center
        StayTunedLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        StayTunedLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    
    }
    
    
    @objc func screenEdgeSwipedLeft(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        
        if recognizer.state == .recognized {
            print("Left Edge")
            dismiss(animated: true, completion: nil)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
