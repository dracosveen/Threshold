//
//  PluginOne.swift
//  Threshold
//
//  Created by Martin Adolfsson on 5/14/19.
//  Copyright © 2019 Martin Adolfsson. All rights reserved.
//

import UIKit
import Vision
import AVFoundation


class PluginOneViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var model: VNCoreMLModel!
    var request: VNCoreMLRequest!
    
    @IBOutlet weak var noLabel: UILabel!

    @IBOutlet weak var captureButton: UIButton!
    
    
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    
    var photoOutput: AVCapturePhotoOutput?
    var camerapreviewLayer: AVCaptureVideoPreviewLayer?
    
    var framesSeen = UserDefaults.standard.integer(forKey: "framesSeen")
    var firstObservation: VNClassificationObservation?
    var imageSequenceNumber = 0
   
    var screenRightEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        screenRightEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwipedRight))
        screenRightEdgeRecognizer.edges = .right
        view.addGestureRecognizer(screenRightEdgeRecognizer)
        
        captureButton.createRectangleButton(buttonPositionX: 150, buttonPositionY: 650, buttonWidth: 100, buttonHeight: 100, buttonTilte: "")
        captureButton.backgroundColor = .green
        captureButton.translatesAutoresizingMaskIntoConstraints = true
        captureButton.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
        self.view.addSubview(captureButton)
        
        
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        /*PluginTwo.mlmodel = AvocadoToast and Fedora Hats */
        model = try? VNCoreMLModel(for: PluginTwo().model)
        
        request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
            self?.processQuery(for: request, error: error)
        })
        request.imageCropAndScaleOption = .centerCrop
        //return request
        
        
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        setupRunningCaptureSession()
        view.addSubview(noLabel)
        updateOrientation()
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NoLabel()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func NoLabel() {
        
        self.noLabel.textColor = .red
        self.noLabel.frame.size = .init(width: 414, height: 896)
        self.noLabel.adjustsFontSizeToFitWidth = true
        self.noLabel.numberOfLines = 3
        self.noLabel.font = UIFont.systemFont(ofSize: 170, weight: UIFont.Weight.heavy)
        self.noLabel.textAlignment = .center
        self.noLabel.text = "computer says NO"
        noLabel.translatesAutoresizingMaskIntoConstraints = true
        noLabel.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
    }
    
    
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let device = deviceDiscoverySession.devices
        
        for device in device {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        
        currentCamera = backCamera
    }
    
    func setupInputOutput() {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
            photoOutput = AVCapturePhotoOutput()
            photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
            photoOutput?.connections[0].videoOrientation = AVCaptureVideoOrientation.portrait
        } catch {
            print(error)
        }
    }
    
    func setupPreviewLayer() {
        camerapreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        camerapreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        camerapreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        camerapreviewLayer?.frame = self.view.frame
        
        self.view.translatesAutoresizingMaskIntoConstraints = true
        self.view.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin]
        
        self.view.layer.insertSublayer(camerapreviewLayer!, at: 0)
        
    }
    
    func updateOrientation() {
        let videoOrientation: AVCaptureVideoOrientation
        switch UIDevice.current.orientation {
        case .portrait:
            videoOrientation = .portrait

        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown

        case .landscapeLeft:
            videoOrientation = .landscapeRight

        case .landscapeRight:
            videoOrientation = .landscapeLeft

        default:
            videoOrientation = .portrait
        }

        camerapreviewLayer?.connection?.videoOrientation = videoOrientation
    }

    func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        updateOrientation()
    }

    
    func  setupRunningCaptureSession() {
        captureSession.startRunning()
        captureSession.sessionPreset = .high
    }
    
    @objc func screenEdgeSwipedRight(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        
        if recognizer.state == .recognized {
            print("Right Edge")
            captureSession.stopRunning()
            performSegue(withIdentifier: "SegueFromPluginOneViewControllerToPluginTwoViewController", sender: Any?.self)
        }
    }
    
 
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PluginThreeSegue" {
//            UIView.animate(withDuration: 0.4) {
//                let toViewController = segue.destination as! PluginOneImageViewController
//                toViewController.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .push(direction: .right))
//                toViewController.modalPresentationStyle = .overFullScreen
//
//            }
            captureSession.stopRunning()
            
            
            print("preparing animation")
            
        }
    }
    
    func processQuery(for request: VNRequest, error: Error?, k: Int = 5) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                //self.referenceRanking.text = "Unable to rank image.\n\(error!.localizedDescription)"
                return
            }
            
            let queryResults = results as! [VNCoreMLFeatureValueObservation]
            let distances = queryResults.first!.featureValue.multiArrayValue!
            
            // Create an array of distances to sort
            let numReferenceImages = distances.shape[0].intValue
            var distanceArray = [Double]()
            for r in 0..<numReferenceImages {
                distanceArray.append(Double(truncating: distances[r]))
            }
            
            let sorted = distanceArray.enumerated().sorted(by: {$0.element < $1.element})
            let knn = sorted[..<min(k, numReferenceImages)]
            
            if distanceArray[0] < 21 {
                print ("match")
                print(distanceArray[0])
                self.hideCaptureButton()
                
            } else {
                print ("no match")
                print(distanceArray[0])
                self.showCaptureButton()
            }
            
        }
    }
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        framesSeen += 1
        if framesSeen < 10 { return }
        framesSeen = 0
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        //print(request)
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    
    
    @IBAction func captureButton(_ sender: Any) {
        
        // IF imageSequenceNumber is disabled PluginTwoImageViewController will return image from model
        imageSequenceNumber += 1
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
        captureSession.stopRunning()
        
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            
            let newImage = UIImage(data: imageData)?.fixedOrientation() // It is the image
            let theImageData:NSData = newImage!.pngData()! as NSData
            let imageKey = "key\(imageSequenceNumber)"
            
            UserDefaults.standard.set(theImageData, forKey: imageKey)
            performSegue(withIdentifier: "forwardPluginOneToImageViewController", sender: nil)
            
            print(imageKey)
            
        }
    }
    
    func showCaptureButton() {
        UIView.animate(withDuration: 0.5) {
            self.view.alpha = 1
            self.captureButton.alpha = 1
            self.noLabel.isHidden = true
            return
        }
    }
    
    func hideCaptureButton() {
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .transitionCrossDissolve, animations: {
            
            
            self.noLabel.isHidden = false
            
            //            self.gradientLayer?.frame = self.view.frame
            //            self.gradientLayer.colors = [
            //                UIColor.init(red: 255, green: 255, blue: 255, alpha: 1).cgColor,
            //                UIColor.init(red: 255, green: 255, blue: 255, alpha: 1).cgColor,
            //            ]
            //            self.gradientLayer.locations = [0.0, 0.5]
            //            self.gradientLayer.locations = [0.0, 0.5]
            //            self.view.layer.addSublayer(self.gradientLayer)
            
            
            self.captureButton.alpha = 0
            
            return
        })
        
        
    }
    
}
extension UIDevice {
    static func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
