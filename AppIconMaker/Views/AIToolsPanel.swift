//
//  AIToolsPanel.swift
//  AppIconMaker
//
//  AI-powered tools panel for image editing
//

import SwiftUI

struct AIToolsPanel: View {
    @ObservedObject var viewModel: ImageEditorViewModel
    @State private var selectedBackgroundType: BackgroundType = .transparent
    @State private var selectedColor: Color = .blue
    @State private var dominantColors: [Color] = []
    
    enum BackgroundType: String, CaseIterable {
        case transparent = "Transparent"
        case solid = "Solid Color"
        case gradient = "Gradient"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Tools")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Background Removal Toggle
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .foregroundColor(.blue)
                    Text("Remove Background")
                        .font(.subheadline)
                    Spacer()
                    
                    if viewModel.isProcessing && !viewModel.isBackgroundRemoved {
                        InlineLoadingIndicator()
                    } else {
                        Toggle("", isOn: Binding(
                            get: { viewModel.isBackgroundRemoved },
                            set: { newValue in
                                if newValue {
                                    HapticFeedback.medium()
                                    Task {
                                        await viewModel.removeBackground()
                                    }
                                }
                            }
                        ))
                        .labelsHidden()
                        .accessibilityLabel("Remove Background")
                        .accessibilityHint("Automatically removes the background from your image using AI")
                    }
                }
                
                Text("Automatically detect and remove the background")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Auto-Enhance Button
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.purple)
                    Text("Auto-Enhance")
                        .font(.subheadline)
                    Spacer()
                    
                    if viewModel.isProcessing && viewModel.isEnhanced {
                        InlineLoadingIndicator()
                    } else {
                        Button(action: {
                            HapticFeedback.medium()
                            Task {
                                await viewModel.enhanceImage()
                            }
                        }) {
                            Text(viewModel.isEnhanced ? "Enhanced" : "Enhance")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.isEnhanced ? Color.green : Color.purple)
                                .cornerRadius(8)
                        }
                        .disabled(viewModel.isProcessing)
                        .accessibilityLabel(viewModel.isEnhanced ? "Image Enhanced" : "Enhance Image")
                        .accessibilityHint("Automatically optimizes brightness, contrast, and sharpness for icon display")
                    }
                }
                
                if viewModel.isEnhanced {
                    HStack {
                        Text("Before/After")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { viewModel.isEnhanced },
                            set: { _ in
                                viewModel.toggleEnhancement()
                            }
                        ))
                        .labelsHidden()
                        .accessibilityLabel("Toggle Enhancement")
                        .accessibilityHint("Switches between original and enhanced image")
                    }
                }
                
                Text("Optimize brightness, contrast, and sharpness")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Smart Crop Suggestions
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "crop")
                        .foregroundColor(.orange)
                    Text("Smart Crop")
                        .font(.subheadline)
                    Spacer()
                    
                    if viewModel.cropSuggestions.isEmpty {
                        Button(action: {
                            HapticFeedback.medium()
                            Task {
                                await viewModel.generateCropSuggestions()
                            }
                        }) {
                            Text("Analyze")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }
                        .disabled(viewModel.isProcessing)
                        .accessibilityLabel("Analyze for Smart Crop")
                        .accessibilityHint("Uses AI to suggest optimal crop areas for your icon")
                    }
                }
                
                if !viewModel.cropSuggestions.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.cropSuggestions.enumerated()), id: \.offset) { index, cropRect in
                            Button(action: {
                                HapticFeedback.light()
                                viewModel.applyCrop(cropRect)
                            }) {
                                VStack(spacing: 4) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: "crop.rotate")
                                            .foregroundColor(.orange)
                                    }
                                    
                                    Text("Option \(index + 1)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .accessibilityLabel("Crop Option \(index + 1)")
                            .accessibilityHint("Applies AI-suggested crop area \(index + 1) to your image")
                        }
                    }
                }
                
                Text("AI-suggested crop areas for optimal composition")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Background Style Picker
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "paintpalette")
                        .foregroundColor(.pink)
                    Text("Background Style")
                        .font(.subheadline)
                }
                
                // Background type picker
                Picker("Background Type", selection: $selectedBackgroundType) {
                    ForEach(BackgroundType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedBackgroundType) { _, newValue in
                    HapticFeedback.selection()
                    updateBackgroundStyle(for: newValue)
                }
                .accessibilityLabel("Background Type")
                .accessibilityHint("Choose between transparent, solid color, or gradient background")
                
                // Show color palette for solid colors
                if selectedBackgroundType == .solid {
                    VStack(alignment: .leading, spacing: 8) {
                        if dominantColors.isEmpty {
                            Button(action: {
                                extractColors()
                            }) {
                                HStack {
                                    Image(systemName: "eyedropper")
                                    Text("Extract Colors from Image")
                                        .font(.caption)
                                }
                                .foregroundColor(.pink)
                            }
                            .accessibilityLabel("Extract Colors")
                            .accessibilityHint("Analyzes your image to suggest dominant colors for the background")
                        }
                        
                        if !dominantColors.isEmpty {
                            Text("Suggested Colors")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
                                ForEach(Array(dominantColors.enumerated()), id: \.offset) { _, color in
                                    Button(action: {
                                        HapticFeedback.light()
                                        selectedColor = color
                                        viewModel.updateBackgroundStyle(.solid(color))
                                    }) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                    .accessibilityLabel("Suggested Color")
                                    .accessibilityHint("Applies this color as solid background")
                                }
                            }
                        }
                        
                        ColorPicker("Custom Color", selection: $selectedColor)
                            .onChange(of: selectedColor) { _, newColor in
                                viewModel.updateBackgroundStyle(.solid(newColor))
                            }
                            .accessibilityLabel("Custom Color Picker")
                            .accessibilityHint("Choose any custom color for the background")
                    }
                }
                
                // Show gradient options
                if selectedBackgroundType == .gradient {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gradient Presets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(gradientPresets, id: \.id) { preset in
                                    Button(action: {
                                        HapticFeedback.light()
                                        viewModel.updateBackgroundStyle(.gradient(preset.gradientInfo))
                                    }) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(preset.gradientInfo.linearGradient)
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                    .accessibilityLabel("\(preset.id.capitalized) Gradient")
                                    .accessibilityHint("Applies \(preset.id) gradient as background")
                                }
                            }
                        }
                    }
                }
                
                Text("Choose a background style for your icon")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .onAppear {
            // Initialize background type based on current style
            switch viewModel.backgroundStyle {
            case .transparent:
                selectedBackgroundType = .transparent
            case .solid:
                selectedBackgroundType = .solid
            case .gradient:
                selectedBackgroundType = .gradient
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateBackgroundStyle(for type: BackgroundType) {
        switch type {
        case .transparent:
            viewModel.updateBackgroundStyle(.transparent)
        case .solid:
            viewModel.updateBackgroundStyle(.solid(selectedColor))
        case .gradient:
            if let firstPreset = gradientPresets.first {
                viewModel.updateBackgroundStyle(.gradient(firstPreset.gradientInfo))
            }
        }
    }
    
    private func extractColors() {
        let aiService = AIImageService()
        let colors = aiService.extractDominantColors(from: viewModel.processedImage)
        dominantColors = colors.map { Color($0) }
    }
    
    // MARK: - Gradient Presets
    
    private var gradientPresets: [GradientPreset] {
        [
            GradientPreset(
                id: "sunset",
                gradientInfo: GradientInfo(
                    colors: [.orange, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            GradientPreset(
                id: "ocean",
                gradientInfo: GradientInfo(
                    colors: [.blue, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            GradientPreset(
                id: "forest",
                gradientInfo: GradientInfo(
                    colors: [.green, .mint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            GradientPreset(
                id: "purple",
                gradientInfo: GradientInfo(
                    colors: [.purple, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            GradientPreset(
                id: "fire",
                gradientInfo: GradientInfo(
                    colors: [.red, .orange, .yellow],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        ]
    }
}

// MARK: - Supporting Types

struct GradientPreset: Identifiable {
    let id: String
    let gradientInfo: GradientInfo
}

#Preview {
    AIToolsPanel(viewModel: ImageEditorViewModel(image: UIImage(systemName: "photo")!))
}
