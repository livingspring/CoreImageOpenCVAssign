//
//  FaceDetectionModel.swift
//  ImageLab
//
//  Created by Owen on 10/31/23.
//  Copyright © 2023 Eric Larson. All rights reserved.
//

import UIKit

class FaceDetectionModel: NSObject {
    var detector:CIDetector! = nil
    var videoManager:VisionAnalgesic! = nil
    let bridge = OpenCVBridge()
    let faceDetectionQueue = DispatchQueue(label: "FaceDetectionQueue", attributes: .concurrent)
    var skip = false;
    var lastFaces: [CIFaceFeature]?
    init(videoManager: VisionAnalgesic!) {
        super.init()
        self.videoManager = videoManager
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyHigh,
                      CIDetectorNumberOfAngles:1,
                            CIDetectorTracking:false] as [String : Any]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                   context: self.videoManager.getCIContext(), // perform on the GPU is possible
                                   options: (optsDetector as [String : AnyObject]))
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
    }
    // process frames
    func processImageSwift(inputImage:CIImage) -> (CIImage){
        //let semaphore = DispatchSemaphore(value: 0)
        var retImage = inputImage
        var detected = false
        // detect faces
        if lastFaces == nil{
            lastFaces = self.getFaces(img: inputImage)
            detected = true
        }

        // if no faces, just return original image
        if lastFaces!.count != 0 {
            self.bridge.setImage(retImage,
                                 withBounds: inputImage.extent, // the first face bounds
                                 andContext: self.videoManager.getCIContext())
            
            self.bridge.processFaces(lastFaces!)
            retImage = self.bridge.getImageComposite()
            
        }
        
        if(!detected){
              lastFaces = nil
        }
        return retImage
    }
    
    // detect faces
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation,
                                   CIDetectorSmile:true,
                                CIDetectorEyeBlink:true] as [String : Any]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
}
