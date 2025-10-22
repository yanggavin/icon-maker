//
//  LoadingView.swift
//  AppIconMaker
//
//  Reusable loading view with animations
//

import SwiftUI

/// A reusable loading view with animated progress indicator
struct LoadingView: View {
    let message: String
    let progress: Double?
    
    init(message: String = "Processing...", progress: Double? = nil) {
        self.message = message
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let progress = progress {
                ProgressView(value: progress) {
                    Text(message)
                        .font(.headline)
                }
                .progressViewStyle(.linear)
                .frame(width: 200)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.bottom, 8)
                
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

/// View modifier for showing a loading overlay
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String
    let progress: Double?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                LoadingView(message: message, progress: progress)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

extension View {
    /// Shows a loading overlay when isLoading is true
    func loadingOverlay(isLoading: Bool, message: String = "Processing...", progress: Double? = nil) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message, progress: progress))
    }
}

/// Inline loading indicator for buttons and small spaces
struct InlineLoadingIndicator: View {
    var body: some View {
        ProgressView()
            .scaleEffect(0.8)
            .frame(width: 20, height: 20)
    }
}

#Preview {
    VStack(spacing: 40) {
        LoadingView(message: "Processing image...")
        
        LoadingView(message: "Exporting icons...", progress: 0.65)
        
        InlineLoadingIndicator()
    }
    .padding()
}
