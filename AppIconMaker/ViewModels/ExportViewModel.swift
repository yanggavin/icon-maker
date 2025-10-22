//
//  ExportViewModel.swift
//  AppIconMaker
//
//  Created by App Icon Maker
//

import SwiftUI

enum ExportFormat: String, CaseIterable {
    case folder = "Folder"
    case zip = "ZIP Archive"
}

@MainActor
class ExportViewModel: ObservableObject {
    @Published var selectedPlatforms: Set<Platform> = [.iOS]
    @Published var exportFormat: ExportFormat = .folder
    @Published var isExporting: Bool = false
    @Published var progress: Double = 0.0
    @Published var exportedURL: URL?
    @Published var errorMessage: String?
    
    private let iconExporter: IconExporter
    
    init(iconExporter: IconExporter = IconExporter()) {
        self.iconExporter = iconExporter
    }
    
    /// Generates icons from the source image for selected platforms
    /// - Parameter image: The source image to generate icons from
    /// - Returns: AppIconSet containing all generated icons
    func generateIcons(from image: UIImage) async -> AppIconSet {
        progress = 0.0
        
        // Generate the icon set
        let iconSet = await iconExporter.generateIconSet(from: image, platforms: selectedPlatforms)
        
        progress = 0.5
        
        return iconSet
    }
    
    /// Exports the icon set to a file system location
    /// - Parameter iconSet: The icon set to export
    /// - Returns: URL to the exported AppIcon.appiconset or ZIP file
    /// - Throws: IconExporterError if export fails
    func exportIconSet(_ iconSet: AppIconSet) async throws -> URL {
        progress = 0.5
        
        // Create temporary directory for export
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        progress = 0.6
        
        // Create the AppIcon.appiconset
        try iconExporter.createAppIconSet(iconSet, at: tempDirectory)
        
        progress = 0.8
        
        // Determine final URL based on export format
        let finalURL: URL
        
        if exportFormat == .zip {
            // Create ZIP archive
            finalURL = try iconExporter.createZipArchive(from: tempDirectory)
            progress = 1.0
        } else {
            // Return the appiconset folder
            finalURL = tempDirectory.appendingPathComponent("AppIcon.appiconset")
            progress = 1.0
        }
        
        return finalURL
    }
}
