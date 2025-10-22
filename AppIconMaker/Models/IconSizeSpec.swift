//
//  IconSizeSpec.swift
//  AppIconMaker
//
//  Created by AppIconMaker
//

import Foundation

struct IconSizeSpec {
    static let iOS: [IconSize] = [
        IconSize(size: 20, scale: 2, idiom: "iphone", filename: "Icon-20@2x.png"),
        IconSize(size: 20, scale: 3, idiom: "iphone", filename: "Icon-20@3x.png"),
        IconSize(size: 29, scale: 2, idiom: "iphone", filename: "Icon-29@2x.png"),
        IconSize(size: 29, scale: 3, idiom: "iphone", filename: "Icon-29@3x.png"),
        IconSize(size: 40, scale: 2, idiom: "iphone", filename: "Icon-40@2x.png"),
        IconSize(size: 40, scale: 3, idiom: "iphone", filename: "Icon-40@3x.png"),
        IconSize(size: 60, scale: 2, idiom: "iphone", filename: "Icon-60@2x.png"),
        IconSize(size: 60, scale: 3, idiom: "iphone", filename: "Icon-60@3x.png"),
        IconSize(size: 1024, scale: 1, idiom: "ios-marketing", filename: "Icon-1024.png")
    ]
    
    static let iPadOS: [IconSize] = [
        IconSize(size: 20, scale: 1, idiom: "ipad", filename: "Icon-20.png"),
        IconSize(size: 20, scale: 2, idiom: "ipad", filename: "Icon-20@2x.png"),
        IconSize(size: 29, scale: 1, idiom: "ipad", filename: "Icon-29.png"),
        IconSize(size: 29, scale: 2, idiom: "ipad", filename: "Icon-29@2x.png"),
        IconSize(size: 40, scale: 1, idiom: "ipad", filename: "Icon-40.png"),
        IconSize(size: 40, scale: 2, idiom: "ipad", filename: "Icon-40@2x.png"),
        IconSize(size: 76, scale: 1, idiom: "ipad", filename: "Icon-76.png"),
        IconSize(size: 76, scale: 2, idiom: "ipad", filename: "Icon-76@2x.png"),
        IconSize(size: 83.5, scale: 2, idiom: "ipad", filename: "Icon-83.5@2x.png")
    ]
    
    static let macOS: [IconSize] = [
        IconSize(size: 16, scale: 1, idiom: "mac", filename: "Icon-16.png"),
        IconSize(size: 16, scale: 2, idiom: "mac", filename: "Icon-16@2x.png"),
        IconSize(size: 32, scale: 1, idiom: "mac", filename: "Icon-32.png"),
        IconSize(size: 32, scale: 2, idiom: "mac", filename: "Icon-32@2x.png"),
        IconSize(size: 128, scale: 1, idiom: "mac", filename: "Icon-128.png"),
        IconSize(size: 128, scale: 2, idiom: "mac", filename: "Icon-128@2x.png"),
        IconSize(size: 256, scale: 1, idiom: "mac", filename: "Icon-256.png"),
        IconSize(size: 256, scale: 2, idiom: "mac", filename: "Icon-256@2x.png"),
        IconSize(size: 512, scale: 1, idiom: "mac", filename: "Icon-512.png"),
        IconSize(size: 512, scale: 2, idiom: "mac", filename: "Icon-512@2x.png")
    ]
}
