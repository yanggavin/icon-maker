//
//  ImageProcessor.swift
//  AppIconMaker
//
//  Created by App Icon Maker
//

import UIKit
import CoreGraphics
import SwiftUI

/// Service responsible for image transformations and compositing
class ImageProcessor {
    
    // MARK: - Resize Functionality
    
    /// Resizes an image to the specified size with high-quality interpolation
    /// - Parameters:
    ///   - image: The source image to resize
    ///   - size: The target size in points
    ///   - scale: The scale factor (e.g., 1.0, 2.0, 3.0)
    /// - Returns: The resized image
    func resize(_ image: UIImage, to size: CGSize, scale: CGFloat) -> UIImage {
        let pixelSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        let resizedImage = renderer.image { context in
            // Set high-quality interpolation
            context.cgContext.interpolationQuality = .high
            
            // Draw the image scaled to the target size
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        return resizedImage
    }
    
    // MARK: - Crop Functionality
    
    /// Crops an image to the specified rectangle
    /// - Parameters:
    ///   - image: The source image to crop
    ///   - rect: The crop rectangle in the image's coordinate system
    /// - Returns: The cropped image
    func crop(_ image: UIImage, to rect: CGRect) -> UIImage {
        // Convert UIImage to CGImage for processing
        guard let cgImage = image.cgImage else {
            return image
        }
        
        // Handle coordinate system conversion
        // UIKit uses top-left origin, but we need to account for image scale and orientation
        let scale = image.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )
        
        // Perform the crop
        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else {
            return image
        }
        
        // Create UIImage from cropped CGImage, maintaining scale and orientation
        let croppedImage = UIImage(
            cgImage: croppedCGImage,
            scale: image.scale,
            orientation: image.imageOrientation
        )
        
        return croppedImage
    }
    
    // MARK: - Image Compositing
    
    /// Composites a subject image with a background style at the specified size
    /// - Parameters:
    ///   - subject: The subject image (typically with transparent background)
    ///   - background: The background style to apply
    ///   - size: The target size for the composite
    /// - Returns: The composited image
    func composite(subject: UIImage, background: BackgroundStyle, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = subject.scale
        format.opaque = false // Preserve alpha channel
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        let compositedImage = renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: size)
            
            // Render background based on style
            switch background {
            case .transparent:
                // No background - just transparent
                break
                
            case .solid(let color):
                // Render solid color background
                cgContext.setFillColor(UIColor(color).cgColor)
                cgContext.fill(rect)
                
            case .gradient(let gradientInfo):
                // Render gradient background
                renderGradient(gradientInfo, in: rect, context: cgContext)
            }
            
            // Draw the subject image on top
            subject.draw(in: rect)
        }
        
        return compositedImage
    }
    
    /// Helper method to render a gradient using Core Graphics
    private func renderGradient(_ gradientInfo: GradientInfo, in rect: CGRect, context: CGContext) {
        // Convert SwiftUI Colors to CGColors
        let cgColors = gradientInfo.colors.map { UIColor($0).cgColor } as CFArray
        
        // Create evenly spaced locations
        let count = gradientInfo.colors.count
        let locations: [CGFloat] = (0..<count).map { CGFloat($0) / CGFloat(count - 1) }
        
        guard let cgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: locations) else {
            return
        }
        
        // Convert UnitPoint to CGPoint
        let startPoint = CGPoint(
            x: rect.minX + rect.width * gradientInfo.startPoint.x,
            y: rect.minY + rect.height * gradientInfo.startPoint.y
        )
        let endPoint = CGPoint(
            x: rect.minX + rect.width * gradientInfo.endPoint.x,
            y: rect.minY + rect.height * gradientInfo.endPoint.y
        )
        
        context.drawLinearGradient(
            cgGradient,
            start: startPoint,
            end: endPoint,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }
    
    // MARK: - Transform Application
    
    /// Applies a CGAffineTransform to an image
    /// - Parameters:
    ///   - transform: The transform to apply (rotation, scale, translation)
    ///   - image: The source image
    /// - Returns: The transformed image
    func applyTransform(_ transform: CGAffineTransform, to image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else {
            return image
        }
        
        // Calculate the bounding box of the transformed image
        let originalSize = CGSize(width: cgImage.width, height: cgImage.height)
        let transformedBounds = CGRect(origin: .zero, size: originalSize).applying(transform)
        let outputSize = transformedBounds.size
        
        // Create a context with the output size
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        
        let transformedImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // Move the origin to account for the transform's effect on position
            cgContext.translateBy(x: -transformedBounds.origin.x, y: -transformedBounds.origin.y)
            
            // Apply the transform
            cgContext.concatenate(transform)
            
            // Set high-quality interpolation
            cgContext.interpolationQuality = .high
            
            // Draw the image
            let drawRect = CGRect(origin: .zero, size: originalSize)
            cgContext.draw(cgImage, in: drawRect)
        }
        
        return transformedImage
    }
}
