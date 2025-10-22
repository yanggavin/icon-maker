//
//  AppIconSet.swift
//  AppIconMaker
//
//  Created by AppIconMaker
//

import Foundation
import UIKit

struct AppIconSet {
    let icons: [IconSize: UIImage]
    let platforms: Set<Platform>
    
    func contentsJSON() -> Data {
        var images: [[String: Any]] = []
        
        for (iconSize, _) in icons {
            let imageEntry: [String: Any] = [
                "filename": iconSize.filename,
                "idiom": iconSize.idiom,
                "scale": "\(Int(iconSize.scale))x",
                "size": "\(Int(iconSize.size))x\(Int(iconSize.size))"
            ]
            images.append(imageEntry)
        }
        
        let contents: [String: Any] = [
            "images": images,
            "info": [
                "author": "app-icon-maker",
                "version": 1
            ]
        ]
        
        return try! JSONSerialization.data(withJSONObject: contents, options: .prettyPrinted)
    }
}
