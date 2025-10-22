//
//  HapticFeedback.swift
//  AppIconMaker
//
//  Utility for providing haptic feedback on iOS/iPadOS
//

#if os(iOS)
import UIKit

enum HapticFeedback {
    /// Provides light impact feedback for button taps
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Provides medium impact feedback for significant actions
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Provides heavy impact feedback for major actions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Provides success feedback
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Provides error feedback
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Provides selection feedback for picker changes
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
#else
// Stub for macOS - no haptic feedback
enum HapticFeedback {
    static func light() {}
    static func medium() {}
    static func heavy() {}
    static func success() {}
    static func error() {}
    static func selection() {}
}
#endif
