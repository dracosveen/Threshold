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
import RealmSwift


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
    var effect: UIVisualEffect!
    var storedImage = StoredImage()
    let showDetailsSegueID = "ShowDetailsSegue"
    
    let defaultPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString)
    var lastImageURL: URL?
    var arrayStoredImageURLs = [URL]()
    var ranking = [(contestantIndex: Int, featureprintDistance: Float)]()
    var screenRightEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    // Popup the runs the first time
    var firstRun = UserDefaults.standard.bool(forKey: "firstRun") as Bool
    
    @IBAction func dismissButtonPopupView(_ sender: Any) {
        animateOut()
    }
    
    @IBAction func captureButton(_ sender: Any) {
        
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        // Popup Window
        effect = visualEffectView.effect
        visualEffectView.effect = nil
        
        addItemView.layer.cornerRadius = 5
        getURL()
        
        //setUpVision()
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        view.addSubview(noLabel)

        
        // First run

        if firstRun {
            firstRun = false
        } else {
           animateIn()
            runFirst()  //will only run once
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.processImagesTwo()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        captureButtonLayout()
        view.addSubview(captureButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupRunningCaptureSession()
        NoLabel()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.alpha = 1
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) -> Void in
            self.camerapreviewLayer?.connection?.videoOrientation = self.transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
            self.camerapreviewLayer?.frame.size = self.view.frame.size
        }, completion: { (context) -> Void in
            
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == showDetailsSegueID, let detailsVC = segue.destination as? DetailsViewController else {
            return
        }
        // Append original as a first node.
        let realm = try! Realm()
        let array = realm.objects(StoredImage.self).last
        //let arrayTwo = realm.objects(StoredImage.self)
        
        let imagePath = defaultPath.appendingPathComponent(array!.filepath)
        let url = URL(fileURLWithPath: imagePath)
            //print("THIS IS URLTWO \(url)")
        
        detailsVC.nodes.append((url: url, label: "Original", distance: 0))
        // Now append contestant images.
        
        for entry in ranking {
            let idx = entry.contestantIndex
            print("THIS IS idX \(idx)")
            let url = arrayStoredImageURLs[idx]
            detailsVC.nodes.append((url: url, label: "Contestant \(idx + 1)", distance: entry.featureprintDistance))
            print("THIS IS RANKING \(ranking)")
            
        }
    }
    
    func getURL() {
        let realm = try! Realm()
        let url = realm.objects(StoredImage.self).last
        // fixed image pathing issue (RMC)
        lastImageURL = URL(fileURLWithPath: defaultPath.appendingPathComponent(url!.filepath))
        let urlTwo = realm.objects(StoredImage.self).toArray(ofType: StoredImage.self)
        arrayStoredImageURLs = urlTwo.compactMap { URL(string: defaultPath.appendingPathComponent($0.filepath)) }
        print("THIS IS arrayStoredImageURLs \(arrayStoredImageURLs)")
    }
    
    func runFirst() {
        print("FIRST RUN!")
        UserDefaults.standard.set(true, forKey: "firstRun")
    }
    
    func setupForViewControllerB() {
        let vc = PluginOneImageViewController()
        vc.onDismiss = {
            self.view.alpha = 0
            print("here")
        }
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
    
    func animateOut () {
        UIView.animate(withDuration: 0.3, animations: {
            self.addItemView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.addItemView.alpha = 0
            
            self.visualEffectView.effect = nil
            
        }) { (success:Bool) in
            self.addItemView.removeFromSuperview()
        }
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
            photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.h264])], completionHandler: nil)
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
            performSegue(withIdentifier: "SegueFromPluginOneViewControllerToPluginTwoViewController", sender: Any?.self)
        }
    }
    
    func processImages(image: CVPixelBuffer) {
        var observation : VNFeaturePrintObservation? // Stored images
        var sourceObservation : VNFeaturePrintObservation? // image from pixel buffer
        sourceObservation = featureprintObservationForCVPixelBuffer(image: image)
           
        let realm = try! Realm()
        let storedImages = realm.objects(StoredImage.self).toArray(ofType: StoredImage.self)
           
        for storedImage in storedImages {
            if let uiimage = UIImage(contentsOfFile: defaultPath.appendingPathComponent(storedImage.filepath)) {
                observation = featureprintObservationForImage(image: uiimage)
               
                do {
                    var distance = Float(0)
                    if let sourceObservation = sourceObservation {
                        try observation?.computeDistance(&distance, to: sourceObservation)
                       
                        // Threshold value
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            //print(distance)
                            self.showCaptureButton()
                            let distanceTwo = String(format:"%.2f",(distance))
                            self.captureButton.setTitle(distanceTwo, for: .normal)
                           
                           
                            if distance < 12.5 {
                                print(distance)
                                //print(storedImage.filepath)
                                print ("match")
                                self.hideCaptureButton()
                           }
                       }
                   }
                   
               } catch {
                   print("errror occurred..")
               }
            }
        }
    }
    
    func processImagesTwo() {
        
        guard let originalURL = lastImageURL else {
                 return
             }
        
        // Make sure we can generate featureprint for original drawing.
        guard let originalFPO = featureprintObservationForURL(atURL: originalURL) else {
            return
        }
        // Generate featureprints for copies and compute distances from original featureprint.
       
        for idx in arrayStoredImageURLs.indices {
            print("THIS IS idX \(idx)")
            let contestantImageURL = arrayStoredImageURLs[idx]
            if let contestantFPO = featureprintObservationForURL(atURL: contestantImageURL) {
                do {
                    var distance = Float(0)
                    try contestantFPO.computeDistance(&distance, to: originalFPO)
                    ranking.append((contestantIndex: idx, featureprintDistance: distance))
                     print("THIS IS Ranking \(ranking)")
                } catch {
                    print("Error computing distance between featureprints.")
                }
            }
        }
        // Sort results based on distance.
        ranking.sort { (result1, result2) -> Bool in
            return result1.featureprintDistance < result2.featureprintDistance
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        framesSeen += 1
        if framesSeen < 10 { return }
        framesSeen = 0
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        
        processImages(image: pixelBuffer)
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
          if let imageData = photo.fileDataRepresentation() {
              
              let imageKey = "key\(imageSequenceNumber)"
              
              UserDefaults.standard.set(imageData, forKey: imageKey)
            performSegue(withIdentifier: "forwardPluginOneToImageViewController", sender: self)
              
          }
      }

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
 
    func featureprintObservationForImage(image: UIImage) -> VNFeaturePrintObservation? {
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()
        print("REQUEST UIIMAGE URL: \(request)")
        do {
            try requestHandler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            print("Vision error: \(error)")
            return nil
        }
    }

    func featureprintObservationForURL(atURL url: URL) -> VNFeaturePrintObservation? {
        // needed to add path here as only file name is in
        let requestHandler = VNImageRequestHandler(url: url, options: [:])
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
            UIView.animate(withDuration: 2) {
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


extension Results {
    func toArray<T>(ofType: T.Type) -> [T] {
        let array = Array(self) as! [T]
        return array
    }
}

