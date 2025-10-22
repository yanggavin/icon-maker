//
//  EditingState.swift
//  AppIconMaker
//
//  Created by AppIconMaker
//

import UIKit
import CoreGraphics

struct EditingState {
    let image: UIImage
    let transform: CGAffineTransform
    let backgroundRemoved: Bool
    let enhanced: Bool
    let backgroundStyle: BackgroundStyle
}
