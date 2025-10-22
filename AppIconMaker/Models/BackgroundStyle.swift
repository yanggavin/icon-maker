//
//  BackgroundStyle.swift
//  AppIconMaker
//
//  Created by AppIconMaker
//

import SwiftUI

enum BackgroundStyle {
    case transparent
    case solid(Color)
    case gradient(GradientInfo)
    
    var displayName: String {
        switch self {
        case .transparent:
            return "Transparent"
        case .solid:
            return "Solid Color"
        case .gradient:
            return "Gradient"
        }
    }
}

/// Helper struct to store gradient information for rendering
struct GradientInfo {
    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    
    var linearGradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
    }
}
