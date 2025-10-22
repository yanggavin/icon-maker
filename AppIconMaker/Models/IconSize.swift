//
//  IconSize.swift
//  AppIconMaker
//
//  Created by AppIconMaker
//

import Foundation

struct IconSize: Identifiable, Hashable {
    let id = UUID()
    let size: CGFloat
    let scale: CGFloat
    let idiom: String
    let filename: String
    
    var pointSize: CGFloat {
        size
    }
    
    var pixelSize: CGFloat {
        size * scale
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(size)
        hasher.combine(scale)
        hasher.combine(idiom)
        hasher.combine(filename)
    }
    
    static func == (lhs: IconSize, rhs: IconSize) -> Bool {
        lhs.size == rhs.size &&
        lhs.scale == rhs.scale &&
        lhs.idiom == rhs.idiom &&
        lhs.filename == rhs.filename
    }
}
