//
//  ViewController.swift
//  VideoTrimmer
//
//  Created by Koronä on 10/20/19.
//  Copyright © 2019 Koronä. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices
import Photos

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    
    @IBAction func pickMediaOnTapped(_ sender: UIButton) {
        
        let mediaPickerAlertController = UIAlertController(title: "Select Video", message: "Please select an option", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .camera)
        }
        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { _ in
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .photoLibrary)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        mediaPickerAlertController.addAction(cameraAction)
        mediaPickerAlertController.addAction(galleryAction)
        mediaPickerAlertController.addAction(cancelAction)
        
        //for iPad
        if let popoverController = mediaPickerAlertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = CGRect(x: sender.bounds.midX, y: sender.bounds.midY, width: 0, height: 0)
        }
        self.present(mediaPickerAlertController, animated: true, completion: nil)
    }
}

typealias ViewControllerDelegates = ViewController
extension ViewControllerDelegates:UIImagePickerControllerDelegate,UINavigationControllerDelegate,VideoTrimmerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        switch picker.sourceType{
        case .camera:
            guard
                let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
                mediaType == (kUTTypeMovie as String),
                let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
                else {return}
            
            
            VideoHelper.getPHAssetfromURL(url: url) { (phAsset) in
                DispatchQueue.main.async {
                    let videoTrimmerViewController = UIHelper.makeVideoTrimmerViewController()
                    videoTrimmerViewController.videoTrimmerDelegate = self
                    videoTrimmerViewController.assetURL = url.path
                    videoTrimmerViewController.phAsset = phAsset
                    self.dismiss(animated: true) {
                        self.present(videoTrimmerViewController, animated: true, completion: nil)
                    }
                }
            }
            
        case .photoLibrary:
            guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
                mediaType == (kUTTypeMovie as String),
                let phAsset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset,
                let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
                else {return}
            DispatchQueue.main.async {
                let videoTrimmerViewController = UIHelper.makeVideoTrimmerViewController()
                videoTrimmerViewController.videoTrimmerDelegate = self
                videoTrimmerViewController.assetURL = url.path
                videoTrimmerViewController.phAsset = phAsset
                self.dismiss(animated: true) {
                    self.present(videoTrimmerViewController, animated: true, completion: nil)
                }
            }
        default:()
        }
    }
    
    func videoCropped(url: URL) {
        dismiss(animated: true) {
            let player = AVPlayer(url: url)
            let vcPlayer = AVPlayerViewController()
            vcPlayer.player = player
            self.present(vcPlayer, animated: true, completion: nil)
        }
    }
}

