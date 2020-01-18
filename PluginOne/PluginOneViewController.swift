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
    
    @IBOutlet var addItemView: UIView!
    
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
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
    var effect:UIVisualEffect!
   
    var screenRightEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
   // let semaphore = DispatchSemaphore(value: PluginOneViewController.maxInflightBuffers)
    lazy  var storedImage = UserDefaults.standard.data(forKey: "key\(imageSequenceNumber)")
    
    
    var modelData = [
                             ModelData(id: 0, imageName: "neon"),
                             ModelData(id: 1, imageName: "view"),
                             ModelData(id: 2, imageName: "dog"),
                             ModelData(id: 3, imageName: "notes"),
                             ModelData(id: 4, imageName: "martin"),
                             ModelData(id: 5, imageName: "purify"),
                             ModelData(id: 6, imageName: "purify2"),
                             ModelData(id: 7, imageName: "soup"),
                             ModelData(id: 8, imageName: "shirt"),
                             ModelData(id: 9, imageName: "shirt2"),
                             ModelData(id: 10, imageName: "beer")
        
    ]
    
    // Popup the runs the first time
    //let firstRun = UserDefaults.standard.bool(forKey: "firstRun") as Bool
    
    // ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        // Swipe right edge on screen
        screenRightEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwipedRight))
        screenRightEdgeRecognizer.edges = .right
        view.addGestureRecognizer(screenRightEdgeRecognizer)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        // Popup Window
        effect = visualEffectView.effect
        visualEffectView.effect = nil
        
        addItemView.layer.cornerRadius = 5
        
        //setUpVision()
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        view.addSubview(noLabel)
        
        // First run
        /*
        if firstRun {
            animateIn()
        } else {
            runFirst() //will only run once
        }
        */
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        captureButtonLayout()
        view.addSubview(captureButton)
    }
    
    func runFirst() {
        print("FIRST RUN!")
        UserDefaults.standard.set(true, forKey: "firstRun")
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
        //captureButton.setTitle(distanceArray[0], for: .normal)
    
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
    /*
    func animateIn() {
        self.view.addSubview(addItemView)
        addItemView.center = self.view.center
        
        addItemView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        addItemView.alpha = 0
        
        UIView.animate(withDuration: 0.4) {
            self.visualEffectView.effect = self.effect
            self.addItemView.alpha = 1
            self.addItemView.transform = CGAffineTransform.identity
        }
        
    }
    */
    
    func animateOut () {
        UIView.animate(withDuration: 0.3, animations: {
            self.addItemView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.addItemView.alpha = 0
            
            self.visualEffectView.effect = nil
            
        }) { (success:Bool) in
            self.addItemView.removeFromSuperview()
        }
    }
    
    @IBAction func dismissButtonPopupView(_ sender: Any) {
        animateOut()
    }
    
    
    
    func NoLabel() {
        // Hide the label initially
        self.noLabel.isHidden = true
        
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
    
    func processImages(image: CVPixelBuffer)
    {
        
        guard self.modelData.count > 0 else{
            return
        }
        
        var observation : VNFeaturePrintObservation? // local images
        var sourceObservation : VNFeaturePrintObservation? // image from pixel buffer
        
        //        sourceObservation = featureprintObservationForImage(image: UIImage(named: sourceImage)!)
        sourceObservation = featureprintObservationForCVPixelBuffer(image: image)
        
        var tempData = modelData
        
        tempData = modelData.enumerated().map { (i,m) in
            var model = m
            if let uiimage = UIImage(named: model.imageName){
                observation = featureprintObservationForImage(image: uiimage)
                
                do {
                    var distance = Float(0)
                    if let sourceObservation = sourceObservation{
                        try observation?.computeDistance(&distance, to: sourceObservation)
                        model.distance = "\(distance)"
                        var distanceValue = [distance]
                        // Threshold value
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            print(distance)
                            print(model.imageName)
                            self.showCaptureButton()
                            let distanceTwo = String(format:"%.2f",(distance))
                            self.captureButton.setTitle(distanceTwo, for: .normal)
                            
                            
                            if distance < 18.5 {
                                print(distance)
                                print(model.imageName)
                                print ("match")
                                sleep(1)
                                self.hideCaptureButton()
                                print("sleeping")
                                
                            }
                            
                        }
                        
                    }
                } catch {
                    print("errror occurred..")
                }
                
            }
            return model
        }
        //ONLY needed if results will be returned in sorted order
        //modelData = tempData.sorted(by: {Float($0.distance)! < Float($1.distance)!})
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        framesSeen += 1
        if framesSeen < 10 { return }
        framesSeen = 0
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        
        processImages(image: pixelBuffer)
        
    }
    
    
    @IBAction func captureButton(_ sender: Any) {
        
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
        
    }
    

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            
            let newImage = UIImage(data: imageData)?.fixedOrientation() // It is the image
            let theImageData:NSData = newImage!.jpegData(compressionQuality: 8)! as NSData
            let imageKey = "key\(imageSequenceNumber)"
            
            UserDefaults.standard.set(theImageData, forKey: imageKey)
            performSegue(withIdentifier: "forwardPluginOneToImageViewController", sender: self)
            print(imageKey)
            
        }
    }
    
    //FeaturePrintObservation on CvPixelBuffer
        func featureprintObservationForCVPixelBuffer(image: CVPixelBuffer) -> VNFeaturePrintObservation? {
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
            let request = VNGenerateImageFeaturePrintRequest()
            do {
                try requestHandler.perform([request])
                return request.results?.first as? VNFeaturePrintObservation
            } catch {
                print("Vision error: \(error)")
                return nil
            }
        }
 
       //FeaturePrintObservation on UIIMAGE
            func featureprintObservationForImage(image: UIImage) -> VNFeaturePrintObservation? {
                let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
                let request = VNGenerateImageFeaturePrintRequest()
                do {
                    try requestHandler.perform([request])
                    return request.results?.first as? VNFeaturePrintObservation
                } catch {
                    print("Vision error: \(error)")
                    return nil
                }
            }
    
    func showCaptureButton() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) {
                self.view.alpha = 1
                self.noLabel.isHidden = true
                self.captureButton.alpha = 1
            }
        }
    }
    
        func hideCaptureButton() {
            DispatchQueue.main.async {
             self.captureButton.alpha = 0
                self.noLabel.isHidden = false
                self.noLabel.text = "computer says NO"
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
        }
        
    }

struct ModelData : Identifiable{
    public let id: Int
    public var imageName : String
    public var distance : String = "NA"
}


