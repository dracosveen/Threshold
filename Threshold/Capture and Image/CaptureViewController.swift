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
import OpalImagePicker
import Photos


class CaptureViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UIScrollViewDelegate {
    
    @IBOutlet var firstItemView: UIView!
    @IBOutlet var secondItemView: UIView!
    
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var noLabel: UILabel!
    @IBOutlet weak var captureButton: UIButton!
    
    @IBOutlet weak var pageController: UIPageControl!
    @IBOutlet weak var scrollViewController: UIScrollView!
    
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    
    var photoOutput: AVCapturePhotoOutput?
    var camerapreviewLayer: AVCaptureVideoPreviewLayer?
    
    var framesSeen = UserDefaults.standard.integer(forKey: "framesSeen")
    var imageSequenceNumber = 0
    var effect: UIVisualEffect!
    let showDetailsSegueID = "ShowDetailsSegue"
    
    let defaultPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString)
    var lastImageURL: URL?
    var arrayStoredImageURLs = [URL]()
    var ranking = [(contestantIndex: Int, featureprintDistance: Float)]()
    // Popup the runs the first time
    var firstRun = UserDefaults.standard.bool(forKey: "firstRun") as Bool
    var firstCapture = UserDefaults.standard.bool(forKey: "firstCapture") as Bool
    var imageCaptured = UserDefaults.standard.bool(forKey: "imageCaptured")
    var pageCopy = ["Now try to capture the same image again", "The number at the center of the capture button indicated how similar the image you're about to capture is to one captured in the past","Swipe left to see the similarities between the recently captured images and previous ones."]
    var frame = CGRect.zero
    
    @IBAction func dismissButtonPopupView(_ sender: Any) {
        animateOut()
    }
    
    @IBAction func captureButton(_ sender: Any) {
        
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
        imageCaptured = true
        print("Image Captured")
        
        if firstCapture {
                  firstCapture = false
              } else {
                  captureFirst()
              }
    }
    
    @IBAction func leftSwipGesture(_ sender: UISwipeGestureRecognizer) {
        if imageCaptured == false {
        let ac = UIAlertController(title: nil, message: "Need to take photo", preferredStyle: .alert)

        ac.addAction(UIAlertAction(title: "OK", style: .default, handler:  { [weak self]_ in
        self!.dismiss(animated: true, completion: nil)
                          }))
       //self.dismiss(animated: true, completion: nil)
       present(ac, animated: true)
                      } else {
            
    }
        performSegue(withIdentifier: "detailSegue", sender: Any?.self)
    }
    
    @IBAction func rightSwipeGesture(_ sender: Any) {
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
                                    self.dismiss(animated: true, completion: nil)
                                 }
                           }
                       }
                       
                   }, cancel: {
                    self.dismiss(animated: true, completion: nil)
                   })
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        // Popup Window
        effect = visualEffectView.effect
        visualEffectView.effect = nil
        firstItemView.layer.cornerRadius = 5
        
        //setUpVision()
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        
        //Labels
        view.addSubview(noLabel)
        setupForViewControllerB()
        pageController.numberOfPages = pageCopy.count
        setupScreens()
        scrollViewController.delegate = self
       
        // First run

        if firstRun {
            firstRun = false
        } else {
            runFirst()  //will only run once
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
        getURL()
        getRank()
        
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
        if segue.identifier == "detailSegue" {
            let detailsVC = segue.destination as! DetailsViewController
                
                //getRank()
                             // Append original as a first node.
                             let realm = try! Realm()
                             let array = realm.objects(StoredImage.self).last
                             
                             let date = array!.created
                             //print("THIS IS array \(array)")
                             
                             detailsVC.nodes.append((url: lastImageURL, label: date, distance: 0))
                             // Now append contestant images.
                             
                             let arrayTwo = realm.objects(StoredImage.self).toArray(ofType: StoredImage.self)
                             let datePath = arrayTwo.map { String(($0.created)) }
                             
                             // Ranking.prefix indicate the number of items being displayed.        
                                for entry in ranking.prefix(5) {
                                let idx = entry.contestantIndex
                                let url = arrayStoredImageURLs[idx]
                                let label = datePath[idx]
                                detailsVC.nodes.append((url: url, label: label, distance: entry.featureprintDistance))
            }
        }
    }
    
func setupScreens() {
    for index in 0..<pageCopy.count {
        
        frame.origin.x = scrollViewController.frame.size.width * CGFloat(index)
        frame.size = scrollViewController.frame.size

         let textView = UILabel(frame: frame)
        textView.textColor = UIColor.darkGray
         textView.textAlignment = .center
         textView.numberOfLines = 0

        textView.text = pageCopy[index]
        
        self.scrollViewController.addSubview(textView)
    }

    scrollViewController.contentSize = CGSize(width: (scrollViewController.frame.size.width * CGFloat(pageCopy.count)), height: scrollViewController.frame.size.height)
    scrollViewController.delegate = self
}
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = scrollViewController.contentOffset.x / scrollViewController.frame.size.width
        pageController.currentPage = Int(pageNumber)
    }
    
    func getURL() {
        let realm = try! Realm()
        let checkForNil = realm.objects(StoredImage.self).last
        guard let url = checkForNil else {
            return
        }
        lastImageURL = URL(fileURLWithPath: defaultPath.appendingPathComponent(url.filepath))
        let urlTwo = realm.objects(StoredImage.self).toArray(ofType: StoredImage.self)
        arrayStoredImageURLs = urlTwo.compactMap { URL(fileURLWithPath: defaultPath.appendingPathComponent($0.filepath)) }

    }
    
    func runFirst() {
        print("FIRST RUN!")
        UserDefaults.standard.set(true, forKey: "firstRun")
        self.view.addSubview(firstItemView)
            firstItemView.center = self.view.center

            firstItemView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            firstItemView.alpha = 0
            
            UIView.animate(withDuration: 0.4) {
                // Background Blur
                self.visualEffectView.effect = self.effect
                self.firstItemView.alpha = 1
                self.firstItemView.transform = CGAffineTransform.identity
            }
    }
    
    func captureFirst() {
        print("FIRST Capture!")
        UserDefaults.standard.set(true, forKey: "firstCapture")
        self.view.addSubview(secondItemView)
                 secondItemView.center = self.view.center

                 secondItemView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
                 secondItemView.alpha = 0
                scrollViewController.delegate = self

                 
                 UIView.animate(withDuration: 0.4) {
                    // Background Blur
                     //self.visualEffectView.effect = self.effect
                     self.secondItemView.alpha = 1
                     self.secondItemView.transform = CGAffineTransform.identity
                 }
    }
    
    func setupForViewControllerB() {
        let vc = ImageViewController()
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
    
//    func animateIn() {
//        self.view.addSubview(firstItemView)
//        firstItemView.center = self.view.center
//
//        firstItemView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
//        firstItemView.alpha = 0
//
//        UIView.animate(withDuration: 0.4) {
//            self.visualEffectView.effect = self.effect
//            self.firstItemView.alpha = 1
//            self.firstItemView.transform = CGAffineTransform.identity
//        }
//    }
    
    func animateOut () {
        UIView.animate(withDuration: 0.3, animations: {
            self.firstItemView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.firstItemView.alpha = 0
            
            self.visualEffectView.effect = nil
            
        }) { (success:Bool) in
            self.firstItemView.removeFromSuperview()
        }
    }

    func NoLabel() {
        // Hide the label initially
        self.noLabel.isHidden = true
        
        self.noLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.noLabel.widthAnchor.constraint(equalToConstant: 414).isActive = true
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
    
     func processImages(image: CVPixelBuffer) {
        let sourceObservation = featureprintObservationForCVPixelBuffer(image: image)
        
        _ = arrayStoredImageURLs.enumerated().map { (i,m) in
             if let contestantFPO = featureprintObservationForURL(atURL: m) {
                do {
                    var distance = Float(0)
                    try contestantFPO.computeDistance(&distance, to: sourceObservation!)
                        
                         DispatchQueue.main.asyncAfter(deadline: .now()) {
                             self.showCaptureButton()
                             let distanceTwo = String(format:"%.2f",(distance))
                             self.captureButton.setTitle(distanceTwo, for: .normal)
                            
                             if distance < 15.5 {
                                 print(distance)
                                //print(contestantFPO.elementCount)
                                 print ("match")
                                 self.hideCaptureButton()
                        }
                    }
                    
                } catch {
                    print("errror occurred..")
                }
             }
         }
     }
   
     func getRank() {
         
         guard let originalURL = lastImageURL else {return}
         guard let originalFPO = featureprintObservationForURL(atURL: originalURL) else {return}
        
        let temp = arrayStoredImageURLs.dropLast()
        for idx in temp.indices {
             let contestantImageURL = temp[idx]
             if let contestantFPO = featureprintObservationForURL(atURL: contestantImageURL) {
                 do {
                     var distance = Float(0)
                     try contestantFPO.computeDistance(&distance, to: originalFPO)
                     ranking.append((contestantIndex: idx, featureprintDistance: distance))
                 } catch {
                     print("Error computing distance between featureprints.")
                 }
             }
         }
          //Sort results based on distance
        
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
            print("Vision error CVP: \(error)")
            return nil
        }
    }


    func featureprintObservationForURL(atURL url: URL) -> VNFeaturePrintObservation? {
        let requestHandler = VNImageRequestHandler(url: url, options: [:])
              let request = VNGenerateImageFeaturePrintRequest()
              do {
                  try requestHandler.perform([request])
                  return request.results?.first as? VNFeaturePrintObservation
              } catch {
                print(requestHandler)
                  print("Vision error URL: \(error)")
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

