//
//  ImageEditorViewModel.swift
//  AppIconMaker
//
//  ViewModel for managing image editing state and AI-powered operations
//

import UIKit
import SwiftUI

@MainActor
class ImageEditorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var originalImage: UIImage
    @Published var processedImage: UIImage
    @Published var isBackgroundRemoved: Bool = false
    @Published var isEnhanced: Bool = false
    @Published var backgroundStyle: BackgroundStyle = .transparent
    @Published var cropSuggestions: [CGRect] = []
    @Published var isProcessing: Bool = false
    @Published var currentError: Error?
    
    // MARK: - Dependencies
    
    private let aiService: AIImageService
    private let imageProcessor: ImageProcessor
    
    // MARK: - Undo/Redo Support
    
    private var editHistory: [EditingState] = []
    private var currentHistoryIndex: Int = -1
    
    // MARK: - Initialization
    
    init(image: UIImage, aiService: AIImageService? = nil, imageProcessor: ImageProcessor? = nil) {
        self.originalImage = image
        self.processedImage = image
        self.aiService = aiService ?? AIImageService()
        self.imageProcessor = imageProcessor ?? ImageProcessor()
        
        // Save initial state
        saveCurrentState()
    }
    
    // MARK: - Private Helper Methods
    
    /// Saves the current editing state to history
    private func saveCurrentState() {
        // Remove any forward history if we're not at the end
        if currentHistoryIndex < editHistory.count - 1 {
            editHistory.removeSubrange((currentHistoryIndex + 1)...)
        }
        
        let state = EditingState(
            image: processedImage,
            transform: .identity,
            backgroundRemoved: isBackgroundRemoved,
            enhanced: isEnhanced,
            backgroundStyle: backgroundStyle
        )
        
        editHistory.append(state)
        currentHistoryIndex = editHistory.count - 1
    }
    
    // MARK: - Background Removal
    
    /// Removes the background from the image using AI
    func removeBackground() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let imageToProcess = isBackgroundRemoved ? originalImage : processedImage
            let result = try await aiService.removeBackground(from: imageToProcess)
            
            processedImage = result
            isBackgroundRemoved = true
            saveCurrentState()
            HapticFeedback.success()
        } catch {
            currentError = AppIconMakerError.backgroundRemovalFailed
            print("Background removal failed: \(error.localizedDescription)")
            HapticFeedback.error()
        }
    }
    
    // MARK: - Image Enhancement
    
    /// Enhances the image using AI-powered filters
    func enhanceImage() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let result = try await aiService.enhanceImage(processedImage)
            
            processedImage = result
            isEnhanced = true
            saveCurrentState()
            HapticFeedback.success()
        } catch {
            currentError = AppIconMakerError.enhancementFailed
            print("Image enhancement failed: \(error.localizedDescription)")
            HapticFeedback.error()
        }
    }
    
    /// Toggles enhancement on/off for before/after comparison
    func toggleEnhancement() {
        if isEnhanced {
            // Revert to previous state
            if currentHistoryIndex > 0 {
                undo()
            }
        } else {
            Task {
                await enhanceImage()
            }
        }
    }
    
    // MARK: - Crop Suggestions
    
    /// Generates smart crop suggestions using saliency analysis
    func generateCropSuggestions() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let suggestions = try await aiService.analyzeSaliency(in: processedImage)
            cropSuggestions = suggestions
        } catch {
            currentError = AppIconMakerError.saliencyAnalysisFailed
            print("Crop suggestion generation failed: \(error.localizedDescription)")
            cropSuggestions = []
        }
    }
    
    /// Applies a suggested crop to the image
    func applyCrop(_ cropRect: CGRect) {
        let croppedImage = imageProcessor.crop(processedImage, to: cropRect)
        processedImage = croppedImage
        saveCurrentState()
    }
    
    // MARK: - Background Style
    
    /// Applies a background style to the image
    func applyBackground(_ style: BackgroundStyle) async {
        isProcessing = true
        defer { isProcessing = false }
        
        // Only apply background if background has been removed
        guard isBackgroundRemoved else {
            backgroundStyle = style
            return
        }
        
        // Get the current image size for compositing
        let size = processedImage.size
        
        // Composite the subject with the new background
        let result = imageProcessor.composite(
            subject: processedImage,
            background: style,
            size: size
        )
        
        processedImage = result
        backgroundStyle = style
        saveCurrentState()
    }
    
    /// Updates background style with real-time preview
    func updateBackgroundStyle(_ style: BackgroundStyle) {
        Task {
            await applyBackground(style)
        }
    }
    
    // MARK: - Undo/Redo
    
    /// Undoes the last editing action
    func undo() {
        guard canUndo else { return }
        
        currentHistoryIndex -= 1
        restoreState(at: currentHistoryIndex)
    }
    
    /// Redoes the previously undone action
    func redo() {
        guard canRedo else { return }
        
        currentHistoryIndex += 1
        restoreState(at: currentHistoryIndex)
    }
    
    /// Returns true if undo is available
    var canUndo: Bool {
        return currentHistoryIndex > 0
    }
    
    /// Returns true if redo is available
    var canRedo: Bool {
        return currentHistoryIndex < editHistory.count - 1
    }
    
    /// Restores the editing state at the specified history index
    private func restoreState(at index: Int) {
        guard index >= 0 && index < editHistory.count else { return }
        
        let state = editHistory[index]
        processedImage = state.image
        isBackgroundRemoved = state.backgroundRemoved
        isEnhanced = state.enhanced
        backgroundStyle = state.backgroundStyle
    }
}
