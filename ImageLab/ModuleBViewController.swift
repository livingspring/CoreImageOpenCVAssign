//
//  ModuleBViewController.swift
//  ImageLab
//
//  Created by RongWei Ji on 10/29/23.
//  Copyright © 2023 Eric Larson. All rights reserved.
//

import UIKit
import MetalKit

class ModuleBViewController: UIViewController {

    //Properties
    var videoManager:VisionAnalgesic!=nil
    var detector:CIDetector!=nil
    let bridge = OpenCVBridge()
    var fingerFlashFlag=false;
    
    @IBOutlet weak var cameraView: MTKView!
    
    @IBOutlet weak var colorChartView: ColorLineChartView!  // use a custom chart view to show the color value
    
    @IBOutlet weak var heartBeatView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup the OpenCV, video manager, call the block func to detect the finger cover
        self.bridge.loadHaarCascade(withFilename: "nose")
        
        self.videoManager=VisionAnalgesic(view: self.cameraView)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        self.videoManager.setProcessingBlock(newProcessBlock: processFinger)
        if !videoManager.isRunning{
            videoManager.start()
        }
    }
    
    
    // block for processing finger cover camera
    func processFinger(inputImage:CIImage)->CIImage{
        var returnImage=inputImage
        self.bridge.setImage(returnImage, withBounds: returnImage.extent, andContext: self.videoManager.getCIContext())
        let processFingerResult=self.bridge.processFinger()
        returnImage=self.bridge.getImage()
        fingerCoverDectect(coveringBoolFlag: processFingerResult)
        print("here is the count\(self.bridge.redArray.count) and here is the last value\(String(describing: self.bridge.redArray.lastObject))");
      
        return returnImage
    }
    
    
    // use the red color for update the color chart for mozhonitorting the red
    func updateColorChart(inputArray: [Double] , type:Int){ //type 0 for main color , 1 for the peak
        if inputArray.count>0 {
            if type==0, let lastValue=inputArray.last {
                self.colorChartView.addDataPoint(lastValue)
            }else if type==1, let lastVaule=inputArray.last{
                self.colorChartView.addPeakPoint(dataP: lastVaule)
            }
        }
    }
    
    
    // check the finger cover satus for show chart
    // and generate the hearbeat rate
    func fingerCoverDectect(coveringBoolFlag:Bool){
        // finger cover happen, turn on/off flash, avoid running everytime.
        if self.bridge.coverStatus==1{
            
            updateColorChart(inputArray: self.bridge.redArray as! [Double],type:0)// when finger is covering the chart show the data update the main color
            findPeakArray(self.bridge.redArray.lastObject as! Double)
            updateColorChart(inputArray: peaks, type:1)
            
            if(self.fingerFlashFlag==false){ // this is for the flash
               _ = self.videoManager.turnOnFlashwithLevel(1.0)
                self.fingerFlashFlag=true;
                print("finger cover,flash on.")
            }
          
        }else if self.bridge.coverStatus==2{
              print("something cover rather than finger")
        }else{
            if self.fingerFlashFlag{
                self.videoManager.turnOffFlash()
                self.fingerFlashFlag=false;
            }
        }
    }

    
    // find out the peak of the color data
    private var windowSize = 60
    private var currentWindow: [Double] = []
    var peaks: [Double] = []
    private var currentIndex = 0
    private var lastPeakindex = -1
    
    func findPeakArray2(_newData:Double){
        currentWindow.append(_newData)
        
        if currentWindow.count>windowSize{
            currentWindow.removeFirst()
        }
        currentIndex+=1
        
        if currentIndex>=windowSize{
            if let peak = currentWindow.max() ,  peak == currentWindow[windowSize/2] {
                peaks.append(peak)
                 // this is the peak and in the middel of
                // 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 4 0 0 0 0 0
                // 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 4
            }else{
                peaks.append(0)
            }
        }else{
            peaks.append(0)
        }
        
    }
    
    
    
    func findPeakArray(_ newData: Double) {
        currentWindow.append(newData)

        if currentWindow.count > windowSize {
            currentWindow.removeFirst()
        }

        currentIndex += 1

        if currentIndex >= windowSize {
            if let peak = currentWindow.max(), peak==newData, currentIndex-lastPeakindex>10{ // only one peak in small period
                print(peak)
                peaks.append(peak)
                print("indexDif:\(currentIndex-lastPeakindex)")
                lastPeakindex=currentIndex
            }else{
                peaks.append(0.0)
            }
        }else{
            peaks.append(0.0)
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
