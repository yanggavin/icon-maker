//
//  IconExporter.swift
//  AppIconMaker
//
//  Created by App Icon Maker
//

import UIKit
import Foundation

/// Errors that can occur during icon export
enum IconExporterError: LocalizedError {
    case imageEncodingFailed(filename: String)
    case fileSystemError(reason: String)
    case permissionDenied
    case zipCreationFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed(let filename):
            return "Failed to encode image: \(filename)"
        case .fileSystemError(let reason):
            return "File system error: \(reason)"
        case .permissionDenied:
            return "Permission denied. Please check file access permissions."
        case .zipCreationFailed(let reason):
            return "Failed to create ZIP archive: \(reason)"
        }
    }
}

/// Service responsible for generating icon sets and exporting AppIcon.appiconset bundles
class IconExporter {
    
    private let imageProcessor: ImageProcessor
    private let cache = ImageCache.shared
    
    init(imageProcessor: ImageProcessor = ImageProcessor()) {
        self.imageProcessor = imageProcessor
    }
    
    // MARK: - Icon Set Generation
    
    /// Generates a complete icon set for the specified platforms
    /// - Parameters:
    ///   - image: The source image to generate icons from
    ///   - platforms: Set of platforms to generate icons for
    ///   - progressHandler: Optional closure to report progress (0.0 to 1.0)
    /// - Returns: AppIconSet containing all generated icons
    func generateIconSet(from image: UIImage, platforms: Set<Platform>, progressHandler: ((Double) -> Void)? = nil) async -> AppIconSet {
        var selectedPlatforms = platforms
        
        // If "all" is selected, expand to all specific platforms
        if platforms.contains(.all) {
            selectedPlatforms = [.iOS, .iPadOS, .macOS]
        }
        
        // Collect all icon sizes for selected platforms
        var iconSizes: [IconSize] = []
        
        if selectedPlatforms.contains(.iOS) {
            iconSizes.append(contentsOf: IconSizeSpec.iOS)
        }
        
        if selectedPlatforms.contains(.iPadOS) {
            iconSizes.append(contentsOf: IconSizeSpec.iPadOS)
        }
        
        if selectedPlatforms.contains(.macOS) {
            iconSizes.append(contentsOf: IconSizeSpec.macOS)
        }
        
        // Generate icons concurrently using TaskGroup for better performance
        let totalCount = iconSizes.count
        let icons = await withTaskGroup(of: (IconSize, UIImage).self) { group in
            var result: [IconSize: UIImage] = [:]
            var completedCount = 0
            
            for iconSize in iconSizes {
                group.addTask {
                    let targetSize = CGSize(width: iconSize.size, height: iconSize.size)
                    
                    // Check cache first
                    let cacheKey = ImageCache.iconKey(for: image, size: targetSize, scale: iconSize.scale)
                    if let cachedIcon = self.cache.image(forKey: cacheKey) {
                        return (iconSize, cachedIcon)
                    } else {
                        let generatedIcon = self.imageProcessor.resize(image, to: targetSize, scale: iconSize.scale)
                        self.cache.setImage(generatedIcon, forKey: cacheKey)
                        return (iconSize, generatedIcon)
                    }
                }
            }
            
            // Collect results and report progress
            for await (iconSize, icon) in group {
                result[iconSize] = icon
                completedCount += 1
                
                // Report progress
                if let progressHandler = progressHandler {
                    let progress = Double(completedCount) / Double(totalCount)
                    await MainActor.run {
                        progressHandler(progress)
                    }
                }
            }
            
            return result
        }
        
        return AppIconSet(icons: icons, platforms: selectedPlatforms)
    }
    
    // MARK: - AppIcon.appiconset Creation
    
    /// Creates an AppIcon.appiconset directory structure with all icons and Contents.json
    /// - Parameters:
    ///   - iconSet: The icon set to export
    ///   - url: The directory URL where the .appiconset should be created
    /// - Throws: IconExporterError if creation fails
    func createAppIconSet(_ iconSet: AppIconSet, at url: URL) throws {
        let fileManager = FileManager.default
        
        // Verify we have write permissions to the target directory
        guard fileManager.isWritableFile(atPath: url.path) else {
            throw IconExporterError.permissionDenied
        }
        
        // Create AppIcon.appiconset directory
        let appiconsetURL = url.appendingPathComponent("AppIcon.appiconset")
        
        do {
            // Remove existing directory if it exists
            if fileManager.fileExists(atPath: appiconsetURL.path) {
                try fileManager.removeItem(at: appiconsetURL)
            }
            
            // Create the directory
            try fileManager.createDirectory(at: appiconsetURL, withIntermediateDirectories: true)
        } catch {
            throw IconExporterError.fileSystemError(reason: "Failed to create directory: \(error.localizedDescription)")
        }
        
        // Write each icon image file
        for (iconSize, image) in iconSet.icons {
            let imageURL = appiconsetURL.appendingPathComponent(iconSize.filename)
            
            guard let imageData = image.pngData() else {
                throw IconExporterError.imageEncodingFailed(filename: iconSize.filename)
            }
            
            do {
                try imageData.write(to: imageURL)
            } catch {
                throw IconExporterError.fileSystemError(reason: "Failed to write \(iconSize.filename): \(error.localizedDescription)")
            }
        }
        
        // Generate and write Contents.json
        let contentsData = iconSet.contentsJSON()
        let contentsURL = appiconsetURL.appendingPathComponent("Contents.json")
        
        do {
            try contentsData.write(to: contentsURL)
        } catch {
            throw IconExporterError.fileSystemError(reason: "Failed to write Contents.json: \(error.localizedDescription)")
        }
    }
    
    // MARK: - ZIP Archive Creation
    
    /// Creates a ZIP archive from the AppIcon.appiconset directory
    /// - Parameter url: The URL of the directory containing AppIcon.appiconset
    /// - Returns: URL to the created ZIP file
    /// - Throws: IconExporterError if ZIP creation fails
    func createZipArchive(from url: URL) throws -> URL {
        let fileManager = FileManager.default
        let appiconsetURL = url.appendingPathComponent("AppIcon.appiconset")
        
        // Verify the appiconset directory exists
        guard fileManager.fileExists(atPath: appiconsetURL.path) else {
            throw IconExporterError.fileSystemError(reason: "AppIcon.appiconset directory not found")
        }
        
        // Create ZIP file URL
        let zipURL = url.appendingPathComponent("AppIcon.zip")
        
        // Remove existing ZIP if it exists
        if fileManager.fileExists(atPath: zipURL.path) {
            try fileManager.removeItem(at: zipURL)
        }
        
        // Use Compression framework to create ZIP
        do {
            try fileManager.zipItem(at: appiconsetURL, to: zipURL)
            return zipURL
        } catch {
            throw IconExporterError.zipCreationFailed(reason: error.localizedDescription)
        }
    }
}

// MARK: - FileManager Extension for ZIP

extension FileManager {
    /// Creates a ZIP archive of a directory
    func zipItem(at sourceURL: URL, to destinationURL: URL) throws {
        // Use the Compression framework via NSFileCoordinator for safe file operations
        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?
        var localError: NSError?
        
        coordinator.coordinate(readingItemAt: sourceURL, options: .forUploading, error: &coordinatorError) { zipURL in
            do {
                // The system creates a temporary ZIP for us
                try self.copyItem(at: zipURL, to: destinationURL)
            } catch {
                localError = error as NSError
            }
        }
        
        if let error = coordinatorError ?? localError {
            throw error
        }
    }
}
