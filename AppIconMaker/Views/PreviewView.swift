//
//  PreviewView.swift
//  AppIconMaker
//
//  Created by AppIconMaker
//

import SwiftUI

struct PreviewView: View {
    let processedImage: UIImage
    @State private var selectedPlatform: Platform = .all
    @State private var generatedIcons: [IconSize: UIImage] = [:]
    @State private var isGenerating = false
    
    private let imageProcessor = ImageProcessor()
    
    // Computed property to get icon sizes based on selected platform
    private var filteredIconSizes: [IconSize] {
        switch selectedPlatform {
        case .iOS:
            return IconSizeSpec.iOS
        case .iPadOS:
            return IconSizeSpec.iPadOS
        case .macOS:
            return IconSizeSpec.macOS
        case .all:
            return IconSizeSpec.iOS + IconSizeSpec.iPadOS + IconSizeSpec.macOS
        }
    }
    
    // Grid columns - adaptive based on platform
    private var gridColumns: [GridItem] {
        #if os(macOS)
        // macOS - more columns for larger screens
        return [
            GridItem(.adaptive(minimum: 120, maximum: 180), spacing: 20)
        ]
        #else
        // iOS/iPadOS - adaptive based on screen size
        return [
            GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
        ]
        #endif
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: platformSpacing) {
                    // Platform filter section
                    platformFilterSection
                    
                    // Context mockups section
                    if !isGenerating {
                        contextMockupsSection
                    }
                    
                    // Icon grid section
                    if isGenerating {
                        ProgressView("Generating previews...")
                            .padding()
                    } else {
                        iconGridSection
                    }
                }
                .padding(platformPadding)
            }
            .navigationTitle("Preview Icons")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: ExportView(processedImage: processedImage)) {
                        HStack {
                            Text("Export")
                                .fontWeight(.semibold)
                            #if os(macOS)
                            Image(systemName: "arrow.right")
                            #endif
                        }
                    }
                    .accessibilityLabel("Export Icons")
                    .accessibilityHint("Proceed to export your icon set for Xcode")
                }
            }
        }
        .task {
            await generatePreviews()
        }
        .onChange(of: selectedPlatform) { _, _ in
            HapticFeedback.selection()
            Task {
                await generatePreviews()
            }
        }
    }
    
    // Platform-specific spacing
    private var platformSpacing: CGFloat {
        #if os(macOS)
        return 32
        #else
        return 24
        #endif
    }
    
    // Platform-specific padding
    private var platformPadding: CGFloat {
        #if os(macOS)
        return 24
        #else
        return 16
        #endif
    }
    
    // MARK: - Platform Filter Section
    
    private var platformFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Platform")
                .font(.headline)
            
            Picker("Platform", selection: $selectedPlatform) {
                ForEach(Platform.allCases, id: \.self) { platform in
                    Text(platform.rawValue).tag(platform)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Platform Filter")
            .accessibilityHint("Filter icon previews by platform: iOS, iPadOS, macOS, or all")
        }
    }
    
    // MARK: - Context Mockups Section
    
    private var contextMockupsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Context Preview")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // iOS Home Screen mockup
                    if selectedPlatform == .iOS || selectedPlatform == .all {
                        HomeScreenMockup(
                            title: "iOS Home Screen",
                            iconSize: 60,
                            scale: 3,
                            image: generatedIcons.first(where: { $0.key.size == 60 && $0.key.scale == 3 })?.value
                        )
                    }
                    
                    // iPad Home Screen mockup
                    if selectedPlatform == .iPadOS || selectedPlatform == .all {
                        HomeScreenMockup(
                            title: "iPad Home Screen",
                            iconSize: 76,
                            scale: 2,
                            image: generatedIcons.first(where: { $0.key.size == 76 && $0.key.scale == 2 })?.value
                        )
                    }
                    
                    // macOS Dock mockup
                    if selectedPlatform == .macOS || selectedPlatform == .all {
                        HomeScreenMockup(
                            title: "macOS Dock",
                            iconSize: 128,
                            scale: 2,
                            image: generatedIcons.first(where: { $0.key.size == 128 && $0.key.scale == 2 })?.value
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Icon Grid Section
    
    private var iconGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Icon Sizes")
                .font(.headline)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(filteredIconSizes) { iconSize in
                    IconPreviewCard(
                        iconSize: iconSize,
                        image: generatedIcons[iconSize]
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Preview Generation
    
    private func generatePreviews() async {
        isGenerating = true
        
        await withTaskGroup(of: (IconSize, UIImage).self) { group in
            for iconSize in filteredIconSizes {
                group.addTask {
                    let size = CGSize(width: iconSize.pointSize, height: iconSize.pointSize)
                    let resizedImage = imageProcessor.resize(processedImage, to: size, scale: iconSize.scale)
                    return (iconSize, resizedImage)
                }
            }
            
            var newIcons: [IconSize: UIImage] = [:]
            for await (iconSize, image) in group {
                newIcons[iconSize] = image
            }
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    generatedIcons = newIcons
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Icon Preview Card

struct IconPreviewCard: View {
    let iconSize: IconSize
    let image: UIImage?
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon preview with background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .systemGray6))
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: iconSize.pointSize > 100 ? 22 : 10))
                        .padding(8)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            
            // Size label
            VStack(spacing: 2) {
                Text("\(Int(iconSize.pointSize))pt")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("@\(Int(iconSize.scale))x")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Icon preview: \(Int(iconSize.pointSize)) points at \(Int(iconSize.scale))x scale")
        .accessibilityHint("Shows how your icon will appear at this size")
    }
}

// MARK: - Home Screen Mockup

struct HomeScreenMockup: View {
    let title: String
    let iconSize: CGFloat
    let scale: CGFloat
    let image: UIImage?
    
    var body: some View {
        VStack(spacing: 12) {
            // Mockup container
            ZStack {
                // Background simulating home screen
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                
                // Icon in context
                VStack(spacing: 8) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize, height: iconSize)
                            .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.2237))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: iconSize * 0.2237)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: iconSize, height: iconSize)
                    }
                    
                    // App name placeholder
                    Text("App Name")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            
            // Label
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(Int(iconSize))pt @\(Int(scale))x")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) mockup: \(Int(iconSize)) points at \(Int(scale))x scale")
        .accessibilityHint("Shows your icon in a simulated \(title.lowercased()) context")
    }
}

#Preview {
    PreviewView(processedImage: UIImage(systemName: "star.fill")!)
}
