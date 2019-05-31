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
    
    @IBOutlet weak var noLabel: UILabel!

    @IBOutlet weak var captureButton: UIButton!
    
    
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    
    var photoOutput: AVCapturePhotoOutput?
    var camerapreviewLayer: AVCaptureVideoPreviewLayer?
    
    var framesSeen = UserDefaults.standard.integer(forKey: "framesSeen")
    var imageSequenceNumber = 0
   
    var screenRightEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    var classificationRequests = [VNCoreMLRequest]()
    let semaphore = DispatchSemaphore(value: PluginOneViewController.maxInflightBuffers)
    
    lazy var visionModel: VNCoreMLModel = {
        do {
            let pluginTwo = PluginTwo()
            return try VNCoreMLModel(for: pluginTwo.model)
        } catch {
            fatalError("Failed to create VNCoreMLModel: \(error)")
        }
    }()
    var inflightBuffer = 0
    static let maxInflightBuffers = 2
    
    func setUpVision() {
        for _ in 0..<PluginOneViewController.maxInflightBuffers {
            let request = VNCoreMLRequest(model: visionModel, completionHandler: {
                [weak self] request, error in
                self?.processQuery(for: request, error: error)
            })
            
            request.imageCropAndScaleOption = .centerCrop

            classificationRequests.append(request)
        }
        
        framesSeen += 1
        if framesSeen < 10 { return }
        framesSeen = 0
        print(framesSeen)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        screenRightEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwipedRight))
        screenRightEdgeRecognizer.edges = .right
        view.addGestureRecognizer(screenRightEdgeRecognizer)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        setUpVision()
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
//        captureButtonLayout()
        view.addSubview(noLabel)
        
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        captureButtonLayout()
        view.addSubview(captureButton)
    }
    
   private func captureButtonLayout() {
    
        // Size the button in preportion to the view
        let buttonSize = view.frame.width * 0.25
    
        // Distance from bottom of the view
        let distanceFromBottom: CGFloat = 80.0
    
        // Position the button
        captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: distanceFromBottom * -1).isActive = true
    
        // Set the button size
        captureButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        captureButton.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
    
        // Set the corder radius
        captureButton.layer.cornerRadius = buttonSize / 2
        captureButton.clipsToBounds = true
    
        // Style the button
        captureButton.backgroundColor = .white
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 10
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupRunningCaptureSession()
        NoLabel()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    
    
    func NoLabel() {
        self.noLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.noLabel.widthAnchor.constraint(equalToConstant: 750).isActive = true
        self.noLabel.heightAnchor.constraint(equalToConstant: 750).isActive = true
        self.noLabel.textColor = .red
        self.noLabel.adjustsFontSizeToFitWidth = true
        self.noLabel.numberOfLines = 0
        self.noLabel.font = UIFont.systemFont(ofSize: 170, weight: UIFont.Weight.heavy)
        self.noLabel.textAlignment = .center
        self.noLabel.translatesAutoresizingMaskIntoConstraints = false
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) -> Void in
            self.camerapreviewLayer?.connection?.videoOrientation = self.transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
            self.camerapreviewLayer?.frame.size = self.view.frame.size
        }, completion: { (context) -> Void in
            
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    func transformOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
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
                print(numReferenceImages)
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
        semaphore.wait()
        
        DispatchQueue.main.async {
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform(self.classificationRequests)
            self.semaphore.signal()
        }
        
    }
 
    
    @IBAction func captureButton(_ sender: Any) {
        
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
        
    }
    

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            
            let newImage = UIImage(data: imageData)?.fixedOrientation() // It is the image
            let theImageData:NSData = newImage!.pngData()! as NSData
            let imageKey = "key\(imageSequenceNumber)"
            
            UserDefaults.standard.set(theImageData, forKey: imageKey)
            performSegue(withIdentifier: "forwardPluginOneToImageViewController", sender: self)
            
            print(imageKey)
            
        }
    }
 
    
    func showCaptureButton() {
        UIView.animate(withDuration: 0.5) {
            self.view.alpha = 1
            self.captureButton.alpha = 1
            self.noLabel.isHidden = true

        }
    }
    
    func hideCaptureButton() {
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .transitionCrossDissolve, animations: {
            self.noLabel.isHidden = false
            self.captureButton.alpha = 0
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            self.noLabel.text = "computer says NO"
            
        })
        
        
    }
    
}


