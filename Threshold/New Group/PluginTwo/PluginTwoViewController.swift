//
//  PluginTwoViewController.swift
//  Threshold
//
//  Created by Martin Adolfsson on 5/15/19.
//  Copyright © 2019 Martin Adolfsson. All rights reserved.
//

import UIKit

class PluginTwoViewController: UIViewController {

     var screenLeftEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenLeftEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwipedLeft))
        screenLeftEdgeRecognizer.edges = .left
        view.addGestureRecognizer(screenLeftEdgeRecognizer)

        // Do any additional setup after loading the view.
    }
    
    
    @objc func screenEdgeSwipedLeft(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        
        if recognizer.state == .recognized {
            print("Left Edge")
            performSegue(withIdentifier: "SegueFromPluginTwoViewControllerToPluginOneViewController", sender: Any?.self)
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
