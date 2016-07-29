//
//  ViewController.swift
//  TesseractOCRTest
//
//  Created by Diy2210 on 01.07.16.
//  Copyright © 2016 Diy2210. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation

class ViewController: UIViewController, UINavigationControllerDelegate, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var activityIndicator: UIActivityIndicatorView!
    
    // Camera Function
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        
        if error == nil && captureSession!.canAddInput(input) {
            captureSession!.addInput(input)
       
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if captureSession!.canAddOutput(stillImageOutput) {
                captureSession!.addOutput(stillImageOutput)
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
                previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                previewView.layer.addSublayer(previewLayer!)
                captureSession!.startRunning()
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer!.frame = previewView.bounds
}
    
    //Take Photo Function
    @IBAction func takePhotoButton(sender: AnyObject) {
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                    
                    let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    self.capturedImage.image = image
                }
            })
        }
    }

    // Add Image Function
    @IBAction func addButton(sender: AnyObject) {
        view.endEditing(true)
        
        let imagePickerActionSheet = UIAlertController(title: "Add Image", message: nil, preferredStyle: .ActionSheet)
        
        // Photo Button
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let takePhotoButton = UIAlertAction(title: "Take Photo", style: .Default)
        {
            (alert) -> Void in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .Camera
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
            imagePickerActionSheet.addAction(takePhotoButton)
    }
        
        // Library Button
        let libraryButton = UIAlertAction(title: "From the gallery", style: .Default)
        {
            (alert) -> Void in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        imagePickerActionSheet.addAction(libraryButton)
        
        // Cancel Button
        let cancelButton = UIAlertAction(title: "Cancel", style: .Cancel)
        {
            (alert) -> Void in
        }
        imagePickerActionSheet.addAction(cancelButton)
        presentViewController(imagePickerActionSheet, animated: true, completion: nil)
    }
    
    
    // Scale Image Function
    func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSizeMake(maxDimension, maxDimension)
        var scaleFactor:CGFloat
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.drawInRect(CGRectMake(0, 0, scaledSize.width, scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    // Activity Indicator Function
    func addActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: view.bounds)
        activityIndicator.activityIndicatorViewStyle = .WhiteLarge
        activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.25)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }
    
    func removeActivityIndicator() {
        activityIndicator.removeFromSuperview()
        activityIndicator = nil
    }

    // Tesseract OCR Function
    func performImageRecognition(image: UIImage) {
    
    let  tesseract = G8Tesseract()
    tesseract.language = "eng"
    tesseract.engineMode = .CubeOnly//
    tesseract.pageSegmentationMode = .Auto //
    tesseract.maximumRecognitionTime = 60.0
    tesseract.image = image.g8_blackAndWhite() //
    tesseract.recognize()
    textLabel.text = tesseract.recognizedText
        
    removeActivityIndicator()
    
    }
}

extension ViewController: UIImagePickerControllerDelegate {

  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[String : AnyObject]) {
    let selectedPhoto = info[UIImagePickerControllerOriginalImage] as! UIImage
    let scaledImage = scaleImage(selectedPhoto, maxDimension: 640)
    
    addActivityIndicator()
    
    dismissViewControllerAnimated(true, completion: {
      self.performImageRecognition(scaledImage)
        
    })
  }
}

