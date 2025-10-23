//
//  AIImageService.swift
//  AppIconMaker
//
//  AI-powered image processing service using Vision framework
//

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Cross-Platform Image Extensions
#if canImport(AppKit)
extension NSImage {
    var cgImage: CGImage? {
        var rect = CGRect(origin: .zero, size: self.size)
        return self.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }
    
    convenience init?(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
#endif

enum AIImageServiceError: LocalizedError {
    case imageConversionFailed
    case subjectDetectionFailed
    case backgroundRemovalFailed
    case enhancementFailed
    case saliencyAnalysisFailed
    case noSubjectDetected
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image format"
        case .subjectDetectionFailed:
            return "Could not detect a clear subject in the image"
        case .backgroundRemovalFailed:
            return "Failed to remove background"
        case .enhancementFailed:
            return "Failed to enhance image"
        case .saliencyAnalysisFailed:
            return "Failed to analyze image composition"
        case .noSubjectDetected:
            return "No clear subject detected in the image"
        }
    }
}

@MainActor
class AIImageService {
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private let cache = ImageCache.shared
    
    // Performance optimization: Maximum image size for AI processing
    private let maxProcessingDimension: CGFloat = 2048
    
    // MARK: - Performance Optimization
    
    /// Downscales an image if it exceeds the maximum processing dimension
    private func optimizeImageForProcessing(_ image: UIImage) -> UIImage {
        let maxDimension = max(image.size.width, image.size.height)
        
        // If image is already small enough, return as-is
        guard maxDimension > maxProcessingDimension else {
            return image
        }
        
        // Calculate scale factor
        let scale = maxProcessingDimension / maxDimension
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        // Resize using high-quality rendering
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { context in
            context.cgContext.interpolationQuality = .high
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - Subject Detection
    
    /// Detects the main subject in an image using Vision framework
    /// - Parameter image: The input image
    /// - Returns: A mask image highlighting the detected subject
    func detectSubject(in image: UIImage) async throws -> UIImage {
        // Optimize image size for faster processing
        let optimizedImage = optimizeImageForProcessing(image)
        
        guard let cgImage = optimizedImage.cgImage else {
            throw AIImageServiceError.imageConversionFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: AIImageServiceError.subjectDetectionFailed)
                    return
                }
                
                guard let result = request.results?.first as? VNInstanceMaskObservation else {
                    continuation.resume(throwing: AIImageServiceError.noSubjectDetected)
                    return
                }
                
                do {
                    let maskImage = try self.createMaskImage(from: result, originalImage: cgImage)
                    continuation.resume(returning: maskImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AIImageServiceError.subjectDetectionFailed)
            }
        }
    }
    
    /// Creates a mask image from Vision observation
    private func createMaskImage(from observation: VNInstanceMaskObservation, originalImage: CGImage) throws -> UIImage {
        let maskPixelBuffer = observation.instanceMask
        
        // Convert pixel buffer to CIImage
        let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        
        // Scale mask to match original image size
        let scaleX = CGFloat(originalImage.width) / maskCIImage.extent.width
        let scaleY = CGFloat(originalImage.height) / maskCIImage.extent.height
        let scaledMask = maskCIImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Render to CGImage
        guard let cgMask = ciContext.createCGImage(scaledMask, from: scaledMask.extent) else {
            throw AIImageServiceError.imageConversionFailed
        }
        
        return UIImage(cgImage: cgMask)
    }
    
    // MARK: - Background Removal
    
    /// Removes the background from an image, leaving only the subject with transparency
    /// - Parameter image: The input image
    /// - Returns: Image with transparent background
    func removeBackground(from image: UIImage) async throws -> UIImage {
        // Check cache first
        let cacheKey = ImageCache.backgroundRemovalKey(for: image)
        if let cachedImage = cache.image(forKey: cacheKey) {
            return cachedImage
        }
        
        // Optimize image size for faster processing
        let optimizedImage = optimizeImageForProcessing(image)
        let needsUpscaling = optimizedImage.size != image.size
        
        guard let cgImage = optimizedImage.cgImage else {
            throw AIImageServiceError.imageConversionFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: AIImageServiceError.backgroundRemovalFailed)
                    return
                }
                
                guard let result = request.results?.first as? VNInstanceMaskObservation else {
                    continuation.resume(throwing: AIImageServiceError.noSubjectDetected)
                    return
                }
                
                do {
                    var maskedImage = try self.applyMaskToImage(mask: result, originalImage: cgImage)
                    
                    // If we downscaled, upscale the result back to original size
                    if needsUpscaling {
                        maskedImage = self.upscaleImage(maskedImage, to: image.size)
                    }
                    
                    // Cache the result
                    self.cache.setImage(maskedImage, forKey: cacheKey)
                    continuation.resume(returning: maskedImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AIImageServiceError.backgroundRemovalFailed)
            }
        }
    }
    
    /// Applies a mask to an image to create transparent background
    private func applyMaskToImage(mask: VNInstanceMaskObservation, originalImage: CGImage) throws -> UIImage {
        let maskPixelBuffer = mask.instanceMask
        let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        
        // Scale mask to match original image size
        let scaleX = CGFloat(originalImage.width) / maskCIImage.extent.width
        let scaleY = CGFloat(originalImage.height) / maskCIImage.extent.height
        let scaledMask = maskCIImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Create CIImage from original
        let originalCIImage = CIImage(cgImage: originalImage)
        
        // Apply mask using blend with mask filter
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            throw AIImageServiceError.backgroundRemovalFailed
        }
        
        blendFilter.setValue(originalCIImage, forKey: kCIInputImageKey)
        blendFilter.setValue(CIImage(color: .clear).cropped(to: originalCIImage.extent), forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
        
        guard let outputImage = blendFilter.outputImage,
              let cgOutput = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            throw AIImageServiceError.backgroundRemovalFailed
        }
        
        return UIImage(cgImage: cgOutput)
    }
    
    // MARK: - Image Enhancement
    
    /// Upscales an image back to the target size
    private func upscaleImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            context.cgContext.interpolationQuality = .high
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Enhances an image for optimal icon appearance using Core Image filters
    /// - Parameter image: The input image
    /// - Returns: Enhanced image
    func enhanceImage(_ image: UIImage) async throws -> UIImage {
        // Check cache first
        let cacheKey = ImageCache.enhancementKey(for: image)
        if let cachedImage = cache.image(forKey: cacheKey) {
            return cachedImage
        }
        
        guard let cgImage = image.cgImage else {
            throw AIImageServiceError.imageConversionFailed
        }
        
        let inputImage = CIImage(cgImage: cgImage)
        
        // Apply color controls for brightness, contrast, and saturation
        let colorControlsFilter = CIFilter.colorControls()
        colorControlsFilter.inputImage = inputImage
        colorControlsFilter.brightness = 0.05
        colorControlsFilter.contrast = 1.15
        colorControlsFilter.saturation = 1.1
        
        guard let colorAdjusted = colorControlsFilter.outputImage else {
            throw AIImageServiceError.enhancementFailed
        }
        
        // Apply sharpening for detail enhancement
        let sharpenFilter = CIFilter.sharpenLuminance()
        sharpenFilter.inputImage = colorAdjusted
        sharpenFilter.sharpness = 0.7
        
        guard let sharpened = sharpenFilter.outputImage else {
            throw AIImageServiceError.enhancementFailed
        }
        
        // Apply vibrance for color optimization
        let vibranceFilter = CIFilter.vibrance()
        vibranceFilter.inputImage = sharpened
        vibranceFilter.amount = 0.3
        
        guard let enhanced = vibranceFilter.outputImage,
              let cgOutput = ciContext.createCGImage(enhanced, from: enhanced.extent) else {
            throw AIImageServiceError.enhancementFailed
        }
        
        let enhancedImage = UIImage(cgImage: cgOutput)
        
        // Cache the result
        cache.setImage(enhancedImage, forKey: cacheKey)
        
        return enhancedImage
    }
    
    // MARK: - Saliency Analysis
    
    /// Analyzes image saliency to suggest optimal crop regions
    /// - Parameter image: The input image
    /// - Returns: Array of 2-3 suggested crop rectangles
    func analyzeSaliency(in image: UIImage) async throws -> [CGRect] {
        // Check cache first
        let cacheKey = ImageCache.cropSuggestionsKey(for: image)
        if let cachedSuggestions = cache.cropSuggestions(forKey: cacheKey) {
            return cachedSuggestions
        }
        
        // Optimize image size for faster processing
        let optimizedImage = optimizeImageForProcessing(image)
        let originalSize = image.size
        let optimizedSize = optimizedImage.size
        let scaleRatio = originalSize.width / optimizedSize.width
        
        guard let cgImage = optimizedImage.cgImage else {
            throw AIImageServiceError.imageConversionFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: AIImageServiceError.saliencyAnalysisFailed)
                    return
                }
                
                guard let result = request.results?.first as? VNSaliencyImageObservation else {
                    continuation.resume(throwing: AIImageServiceError.saliencyAnalysisFailed)
                    return
                }
                
                var suggestions = self.generateCropSuggestions(from: result, imageSize: CGSize(width: cgImage.width, height: cgImage.height))
                
                // Scale suggestions back to original image size if we downscaled
                if scaleRatio != 1.0 {
                    suggestions = suggestions.map { rect in
                        CGRect(
                            x: rect.origin.x * scaleRatio,
                            y: rect.origin.y * scaleRatio,
                            width: rect.size.width * scaleRatio,
                            height: rect.size.height * scaleRatio
                        )
                    }
                }
                
                // Cache the suggestions
                self.cache.setCropSuggestions(suggestions, forKey: cacheKey)
                continuation.resume(returning: suggestions)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AIImageServiceError.saliencyAnalysisFailed)
            }
        }
    }
    
    /// Generates crop suggestions based on saliency map
    private func generateCropSuggestions(from observation: VNSaliencyImageObservation, imageSize: CGSize) -> [CGRect] {
        var suggestions: [CGRect] = []
        
        // Get salient objects
        let salientObjects = observation.salientObjects ?? []
        
        if !salientObjects.isEmpty {
            // Suggestion 1: Center on most salient object
            if let primaryObject = salientObjects.first {
                let centerCrop = createSquareCrop(around: primaryObject.boundingBox, imageSize: imageSize)
                suggestions.append(centerCrop)
            }
            
            // Suggestion 2: Rule of thirds composition
            if let primaryObject = salientObjects.first {
                let ruleOfThirdsCrop = createRuleOfThirdsCrop(around: primaryObject.boundingBox, imageSize: imageSize)
                suggestions.append(ruleOfThirdsCrop)
            }
        }
        
        // Suggestion 3: Center crop (fallback or additional option)
        let centerCrop = CGRect(
            x: (imageSize.width - min(imageSize.width, imageSize.height)) / 2,
            y: (imageSize.height - min(imageSize.width, imageSize.height)) / 2,
            width: min(imageSize.width, imageSize.height),
            height: min(imageSize.width, imageSize.height)
        )
        suggestions.append(centerCrop)
        
        // Return up to 3 unique suggestions
        // Note: Using manual uniqueness check for iOS 17 compatibility
        var uniqueSuggestions: [CGRect] = []
        for suggestion in suggestions {
            if !uniqueSuggestions.contains(where: { $0 == suggestion }) {
                uniqueSuggestions.append(suggestion)
            }
        }
        return Array(uniqueSuggestions.prefix(3))
    }
    
    /// Creates a square crop centered on a bounding box
    private func createSquareCrop(around boundingBox: CGRect, imageSize: CGSize) -> CGRect {
        // Convert normalized coordinates to pixel coordinates
        let centerX = boundingBox.midX * imageSize.width
        let centerY = (1 - boundingBox.midY) * imageSize.height
        
        // Determine crop size (use larger dimension of bounding box, with padding)
        let objectWidth = boundingBox.width * imageSize.width
        let objectHeight = boundingBox.height * imageSize.height
        let cropSize = max(objectWidth, objectHeight) * 1.3
        
        // Ensure crop size doesn't exceed image bounds
        let finalSize = min(cropSize, min(imageSize.width, imageSize.height))
        
        // Calculate crop rect
        var cropRect = CGRect(
            x: centerX - finalSize / 2,
            y: centerY - finalSize / 2,
            width: finalSize,
            height: finalSize
        )
        
        // Adjust if crop extends beyond image bounds
        if cropRect.minX < 0 {
            cropRect.origin.x = 0
        }
        if cropRect.minY < 0 {
            cropRect.origin.y = 0
        }
        if cropRect.maxX > imageSize.width {
            cropRect.origin.x = imageSize.width - finalSize
        }
        if cropRect.maxY > imageSize.height {
            cropRect.origin.y = imageSize.height - finalSize
        }
        
        return cropRect
    }
    
    /// Creates a crop following rule of thirds composition
    private func createRuleOfThirdsCrop(around boundingBox: CGRect, imageSize: CGSize) -> CGRect {
        // Convert normalized coordinates
        let centerX = boundingBox.midX * imageSize.width
        let centerY = (1 - boundingBox.midY) * imageSize.height
        
        let cropSize = min(imageSize.width, imageSize.height)
        
        // Position subject at rule of thirds intersection (1/3 from edge)
        let offsetX = cropSize / 6 // 1/3 of half the crop size
        let offsetY = cropSize / 6
        
        var cropRect = CGRect(
            x: centerX - cropSize / 2 + offsetX,
            y: centerY - cropSize / 2 + offsetY,
            width: cropSize,
            height: cropSize
        )
        
        // Adjust if crop extends beyond image bounds
        if cropRect.minX < 0 {
            cropRect.origin.x = 0
        }
        if cropRect.minY < 0 {
            cropRect.origin.y = 0
        }
        if cropRect.maxX > imageSize.width {
            cropRect.origin.x = imageSize.width - cropSize
        }
        if cropRect.maxY > imageSize.height {
            cropRect.origin.y = imageSize.height - cropSize
        }
        
        return cropRect
    }
    
    // MARK: - Color Extraction
    
    /// Extracts dominant colors from an image using histogram analysis
    /// - Parameter image: The input image
    /// - Returns: Array of 5-8 dominant colors
    func extractDominantColors(from image: UIImage) -> [UIColor] {
        guard let cgImage = image.cgImage else {
            return []
        }
        
        // Resize image for faster processing
        let targetSize = CGSize(width: 100, height: 100)
        guard let resizedImage = resizeImageForColorExtraction(cgImage, to: targetSize) else {
            return []
        }
        
        // Extract pixel data
        guard let pixelData = extractPixelData(from: resizedImage) else {
            return []
        }
        
        // Perform k-means clustering to find dominant colors
        let dominantColors = performKMeansClustering(on: pixelData, k: 8)
        
        return dominantColors
    }
    
    /// Resizes image for color extraction
    private func resizeImageForColorExtraction(_ cgImage: CGImage, to size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        return context.makeImage()
    }
    
    /// Extracts pixel data from image
    private func extractPixelData(from cgImage: CGImage) -> [[CGFloat]]? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Convert to array of RGB values
        var pixels: [[CGFloat]] = []
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = CGFloat(pixelData[i]) / 255.0
            let g = CGFloat(pixelData[i + 1]) / 255.0
            let b = CGFloat(pixelData[i + 2]) / 255.0
            let a = CGFloat(pixelData[i + 3]) / 255.0
            
            // Skip transparent pixels
            if a > 0.1 {
                pixels.append([r, g, b])
            }
        }
        
        return pixels
    }
    
    /// Performs k-means clustering to find dominant colors
    private func performKMeansClustering(on pixels: [[CGFloat]], k: Int) -> [UIColor] {
        guard !pixels.isEmpty else { return [] }
        
        // Initialize centroids randomly
        var centroids: [[CGFloat]] = []
        let stride = max(1, pixels.count / k)
        for i in 0..<k {
            let index = min(i * stride, pixels.count - 1)
            centroids.append(pixels[index])
        }
        
        // Perform k-means iterations
        let maxIterations = 10
        for _ in 0..<maxIterations {
            var clusters: [[[CGFloat]]] = Array(repeating: [], count: k)
            
            // Assign pixels to nearest centroid
            for pixel in pixels {
                var minDistance = CGFloat.infinity
                var closestCluster = 0
                
                for (index, centroid) in centroids.enumerated() {
                    let distance = euclideanDistance(pixel, centroid)
                    if distance < minDistance {
                        minDistance = distance
                        closestCluster = index
                    }
                }
                
                clusters[closestCluster].append(pixel)
            }
            
            // Update centroids
            for (index, cluster) in clusters.enumerated() {
                if !cluster.isEmpty {
                    let newCentroid = averageColor(cluster)
                    centroids[index] = newCentroid
                }
            }
        }
        
        // Convert centroids to UIColors and sort by frequency
        var colorCounts: [(color: UIColor, count: Int)] = []
        for centroid in centroids {
            let color = UIColor(red: centroid[0], green: centroid[1], blue: centroid[2], alpha: 1.0)
            
            // Count pixels in this cluster
            var count = 0
            for pixel in pixels {
                if euclideanDistance(pixel, centroid) < 0.3 {
                    count += 1
                }
            }
            
            colorCounts.append((color: color, count: count))
        }
        
        // Sort by frequency and return top colors
        return colorCounts
            .sorted { $0.count > $1.count }
            .prefix(8)
            .map { $0.color }
    }
    
    /// Calculates Euclidean distance between two colors
    private func euclideanDistance(_ color1: [CGFloat], _ color2: [CGFloat]) -> CGFloat {
        let dr = color1[0] - color2[0]
        let dg = color1[1] - color2[1]
        let db = color1[2] - color2[2]
        return sqrt(dr * dr + dg * dg + db * db)
    }
    
    /// Calculates average color from array of colors
    private func averageColor(_ colors: [[CGFloat]]) -> [CGFloat] {
        guard !colors.isEmpty else { return [0, 0, 0] }
        
        var sumR: CGFloat = 0
        var sumG: CGFloat = 0
        var sumB: CGFloat = 0
        
        for color in colors {
            sumR += color[0]
            sumG += color[1]
            sumB += color[2]
        }
        
        let count = CGFloat(colors.count)
        return [sumR / count, sumG / count, sumB / count]
    }
}
