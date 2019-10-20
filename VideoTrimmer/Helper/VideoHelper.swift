//
//  VideoHelper.swift
//  VideoTrimmer
//
//  Created by Koronä on 10/20/19.
//  Copyright © 2019 Koronä. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import AVFoundation
import Photos

class VideoHelper {
    static func startMediaBrowser(delegate: UIViewController & UINavigationControllerDelegate & UIImagePickerControllerDelegate, sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
        
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = sourceType
        mediaUI.mediaTypes = [kUTTypeMovie as String]
        mediaUI.allowsEditing = false
        mediaUI.delegate = delegate
        delegate.present(mediaUI, animated: true, completion: nil)
    }
    
    static func getPHAssetfromURL(url:URL,onCompleted:@escaping (_ phAsset:PHAsset)->Void){
        var phAsset:PHAsset?
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            if saved {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                phAsset = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                onCompleted(phAsset!)
                
            }
        }
    }
}

