//
//  UIHelper.swift
//  VideoTrimmer
//
//  Created by Koronä on 10/20/19.
//  Copyright © 2019 Koronä. All rights reserved.
//

import Foundation
import UIKit

class UIHelper{
    
    static func makeViewController(storyBoardName:String = "Main", viewControllerName:String) -> UIViewController {
        return UIStoryboard(name: storyBoardName, bundle: nil).instantiateViewController(withIdentifier: viewControllerName)
    }
    
    static func makeVideoTrimmerViewController() -> VideoTrimmerViewController{
        return makeViewController(viewControllerName: "videoTrimmerVC") as! VideoTrimmerViewController
    }
}


