//
//  ErrorHandling.swift
//  AppIconMaker
//
//  Error handling utilities and view modifiers
//

import SwiftUI

/// App-specific error types
enum AppIconMakerError: LocalizedError {
    case imageLoadFailed
    case subjectDetectionFailed
    case backgroundRemovalFailed
    case enhancementFailed
    case saliencyAnalysisFailed
    case exportFailed(reason: String)
    case insufficientPermissions
    case unsupportedImageFormat
    case fileSystemError(String)
    
    var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return "Failed to load the selected image"
        case .subjectDetectionFailed:
            return "Could not detect a clear subject in the image"
        case .backgroundRemovalFailed:
            return "Failed to remove background"
        case .enhancementFailed:
            return "Failed to enhance image"
        case .saliencyAnalysisFailed:
            return "Failed to analyze image for crop suggestions"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .insufficientPermissions:
            return "Photo library access is required"
        case .unsupportedImageFormat:
            return "This image format is not supported"
        case .fileSystemError(let details):
            return "File system error: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .imageLoadFailed:
            return "Please try selecting a different image"
        case .subjectDetectionFailed:
            return "Try using an image with a clearer subject, or proceed with manual editing"
        case .backgroundRemovalFailed:
            return "You can still edit the image manually"
        case .enhancementFailed:
            return "You can continue with the original image"
        case .saliencyAnalysisFailed:
            return "You can manually crop the image using gestures"
        case .exportFailed:
            return "Please check available storage space and try again"
        case .insufficientPermissions:
            return "Please grant photo library access in Settings"
        case .unsupportedImageFormat:
            return "Please use a JPEG or PNG image"
        case .fileSystemError:
            return "Please check available storage space and permissions"
        }
    }
}

/// View modifier for displaying error alerts
struct ErrorAlert: ViewModifier {
    @Binding var error: Error?
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil), presenting: error) { error in
                Button("OK", role: .cancel) {
                    self.error = nil
                }
                
                if onRetry != nil {
                    Button("Retry") {
                        onRetry?()
                        self.error = nil
                    }
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    if let localizedError = error as? LocalizedError {
                        if let description = localizedError.errorDescription {
                            Text(description)
                        }
                        if let suggestion = localizedError.recoverySuggestion {
                            Text(suggestion)
                                .font(.caption)
                        }
                    } else {
                        Text(error.localizedDescription)
                    }
                }
            }
    }
}

extension View {
    /// Presents an error alert with optional retry action
    func errorAlert(error: Binding<Error?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlert(error: error, onRetry: onRetry))
    }
}

/// Observable object for managing error state
@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: Error?
    
    func handle(_ error: Error) {
        currentError = error
        // Log error for debugging
        print("Error occurred: \(error.localizedDescription)")
    }
    
    func clear() {
        currentError = nil
    }
}
