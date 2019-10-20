//
//  AssetSelectionViewController.swift
//  PryntTrimmerView
//
//  Created by Henry on 25/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import AVKit

class AssetSelectionViewController: UIViewController {
    
    typealias TrimCompletion = (Error?) -> ()
    typealias TrimPoints = [(CMTime, CMTime)]
    
    var fetchResult: PHFetchResult<PHAsset>?
    var videoTrimmerDelegate:VideoTrimmerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadLibrary()
    }
    
    func loadLibrary() {
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized {
                self.fetchResult = PHAsset.fetchAssets(with: .video, options: nil)
            }
        }
    }
    
    func loadAssetRandomly() {
        guard let fetchResult = fetchResult, fetchResult.count > 0 else {
            print("Error loading assets.")
            return
        }
        
        let randomAssetIndex = Int(arc4random_uniform(UInt32(fetchResult.count - 1)))
        let asset = fetchResult.object(at: randomAssetIndex)
        
        
        
        PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, _, _) in
            DispatchQueue.main.async {
                if let avAsset = avAsset {
                    self.loadAsset(avAsset)
                }
            }
        }
    }
    
    func loadCustom(asset:PHAsset){
        PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, _, _) in
            DispatchQueue.main.async {
                if let avAsset = avAsset {
                    self.loadAsset(avAsset)
                }
            }
        }
    }
    
    func loadAsset(_ asset: AVAsset) {
        // override in subclass
    }
    
    func verifyPresetForAsset(preset: String, asset: AVAsset) -> Bool {
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        let filteredPresets = compatiblePresets.filter { $0 == preset }
        return filteredPresets.count > 0 || preset == AVAssetExportPresetPassthrough
    }
    
    func removeFileAtURLIfExists(url: URL) {
        
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            try fileManager.removeItem(at: url)
        }
        catch let error {
            print("TrimVideo - Couldn't remove existing destination file: \(String(describing: error))")
        }
    }
    
    
    func trimVideo(sourceURL: URL, destinationURL: URL, trimPoints: TrimPoints, completion: TrimCompletion?) {
        
        guard sourceURL.isFileURL else { return }
        guard destinationURL.isFileURL else { return }
        
        let options = [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ]
        
        let asset = AVURLAsset(url: sourceURL, options: options)
        let preferredPreset = AVAssetExportPresetPassthrough
        
        if  verifyPresetForAsset(preset: preferredPreset, asset: asset) {
            
            let composition = AVMutableComposition()
            let videoCompTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: CMPersistentTrackID())
            let audioCompTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID())
            
            guard let assetVideoTrack: AVAssetTrack = asset.tracks(withMediaType: .video).first else { return }
            guard let assetAudioTrack: AVAssetTrack = asset.tracks(withMediaType: .audio).first else { return }
            
            let size = assetVideoTrack.naturalSize
            let txf = assetVideoTrack.preferredTransform
            
            var recordType = ""
            if (size.width == txf.tx && size.height == txf.ty){
                recordType = "UIInterfaceOrientationLandscapeRight"
            }else if (txf.tx == 0 && txf.ty == 0){
                recordType = "UIInterfaceOrientationLandscapeLeft"
            }else if (txf.tx == 0 && txf.ty == size.width){
                recordType = "UIInterfaceOrientationPortraitUpsideDown"
            }else{
                recordType = "UIInterfaceOrientationPortrait"
            }
            
            if recordType == "UIInterfaceOrientationPortrait" {
                let t1: CGAffineTransform = CGAffineTransform(translationX: assetVideoTrack.naturalSize.height, y: -(assetVideoTrack.naturalSize.width - assetVideoTrack.naturalSize.height)/2)
                let t2: CGAffineTransform = t1.rotated(by: CGFloat(Double.pi / 2))
                let finalTransform: CGAffineTransform = t2
                videoCompTrack!.preferredTransform = finalTransform
            }else if recordType == "UIInterfaceOrientationLandscapeRight" {
                let t1: CGAffineTransform = CGAffineTransform(translationX: assetVideoTrack.naturalSize.height, y: -(assetVideoTrack.naturalSize.width - assetVideoTrack.naturalSize.height)/2)
                let t2: CGAffineTransform = t1.rotated(by: -CGFloat(Double.pi))
                let finalTransform: CGAffineTransform = t2
                videoCompTrack!.preferredTransform = finalTransform
            }else if recordType == "UIInterfaceOrientationPortraitUpsideDown" {
                let t1: CGAffineTransform = CGAffineTransform(translationX: assetVideoTrack.naturalSize.height, y: -(assetVideoTrack.naturalSize.width - assetVideoTrack.naturalSize.height)/2)
                let t2: CGAffineTransform = t1.rotated(by: -CGFloat(Double.pi/2))
                let finalTransform: CGAffineTransform = t2
                videoCompTrack!.preferredTransform = finalTransform
            }
            
            var accumulatedTime = CMTime.zero
            for (startTimeForCurrentSlice, endTimeForCurrentSlice) in trimPoints {
                let durationOfCurrentSlice = CMTimeSubtract(endTimeForCurrentSlice, startTimeForCurrentSlice)
                let timeRangeForCurrentSlice = CMTimeRangeMake(start: startTimeForCurrentSlice, duration: durationOfCurrentSlice)
                
                do {
                    try videoCompTrack!.insertTimeRange(timeRangeForCurrentSlice, of: assetVideoTrack, at: accumulatedTime)
                    try audioCompTrack!.insertTimeRange(timeRangeForCurrentSlice, of: assetAudioTrack, at: accumulatedTime)
                    accumulatedTime = CMTimeAdd(accumulatedTime, durationOfCurrentSlice)
                }
                catch let compError {
                    completion?(compError)
                }
            }
            
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: preferredPreset) else { return }
            
            exportSession.outputURL = destinationURL as URL
            exportSession.outputFileType = AVFileType.m4v
            exportSession.shouldOptimizeForNetworkUse = true
            
            removeFileAtURLIfExists(url: destinationURL as URL)
            
            exportSession.exportAsynchronously {
                completion?(exportSession.error)
            }
        }
        else {
            print("TrimVideo - Could not find a suitable export preset for the input video")
            let error = NSError(domain: "com.bighug.ios", code: -1, userInfo: nil)
            completion?(error)
        }
    }
    
    
    func trim(originalURL:URL,startTime:Float64,endTime:Float64){
        var outputURL = URL(fileURLWithPath:NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!)
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
        } catch {}
        outputURL.appendPathComponent("output.mp4")
        
        // Remove existing file
        do {
            try fileManager.removeItem(at: outputURL)
        }
        catch{}
        let asset = AVAsset(url: originalURL)
        let playerTimescale = asset.duration.timescale
        //        let startPoint =  ASVideoTrimmerView.shared.config.endPoint!-ASVideoTrimmerView.shared.config.limit!
        let start = CMTime(seconds: startTime, preferredTimescale: playerTimescale)
        let duration =  CMTime(seconds: endTime, preferredTimescale: playerTimescale)
        
        trimVideo(sourceURL: originalURL, destinationURL: outputURL, trimPoints: [(start,duration)]) { (error) in
            if error != nil{
                print("Sorry, video not trimmed due to some reason. Please retry with another file or same.")
            }else{
                print("Succesfully croped")
                print(outputURL.absoluteString)
                DispatchQueue.main.async {
                    self.videoTrimmerDelegate?.videoCropped(url: outputURL)
                    self.navigationController?.popViewController(animated: true)
                }
                
            }
        }
    }
}
