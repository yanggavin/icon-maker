//
//  WelcomeView.swift
//  AppIconMaker
//
//  Created by App Icon Maker
//

import SwiftUI
import PhotosUI
#if os(macOS)
import AppKit
#endif
import UniformTypeIdentifiers

struct WelcomeView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showImageEditor = false
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @State private var currentError: Error?
    
    var body: some View {
        NavigationStack {
            content
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $cameraImage, sourceType: .camera)
        }
        .errorAlert(error: $currentError)
        .navigationDestination(isPresented: $showImageEditor) {
            if let image = selectedImage {
                ImageEditorView(viewModel: ImageEditorViewModel(image: image))
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                await loadSelectedImage()
            }
        }
        .onChange(of: cameraImage) { oldValue, newValue in
            if let image = newValue {
                selectedImage = image
                showImageEditor = true
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        #if os(macOS)
            // macOS optimized layout - centered with larger elements and drag-and-drop
            VStack(spacing: 40) {
                Spacer()
                
                // App branding
                VStack(spacing: 20) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 100))
                        .imageScale(.large)
                        .foregroundStyle(.blue)
                    
                    Text("App Icon Maker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Transform any photo into a complete app icon set")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                }
                
                Spacer()
                
                // Drag and drop zone
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                            .foregroundStyle(Color.blue.opacity(0.5))
                            .frame(width: 400, height: 200)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.down.doc")
                                .font(.largeTitle)
                                .imageScale(.large)
                                .foregroundStyle(.blue.opacity(0.7))
                            
                            Text("Drop an image here")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            
                            Text("or")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                    
                    // Photo selection button
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Select Photo", systemImage: "photo.on.rectangle")
                            .font(.title3)
                            .frame(minWidth: 300)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 32)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                    .accessibilityLabel("Select Photo")
                    .accessibilityHint("Opens photo picker to choose an image for your app icon")
                }
                
                Spacer()
            }
            .frame(minWidth: 600, minHeight: 500)
            #else
            // iOS/iPadOS layout
            GeometryReader { geometry in
                VStack(spacing: geometry.size.height > 700 ? 40 : 30) {
                    Spacer()
                    
                    // App branding - scale based on device
                    VStack(spacing: geometry.size.width > 600 ? 20 : 16) {
                        Image(systemName: "app.badge")
                            .font(geometry.size.width > 600 ? .system(size: 100) : .largeTitle)
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                        
                        Text("App Icon Maker")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Transform any photo into a complete app icon set")
                            .font(geometry.size.width > 600 ? .title3 : .body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, geometry.size.width > 600 ? 80 : 40)
                    }
                    
                    Spacer()
                    
                    // Photo selection buttons
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Select Photo", systemImage: "photo.on.rectangle")
                                .font(geometry.size.width > 600 ? .title3 : .headline)
                                .frame(maxWidth: geometry.size.width > 600 ? 400 : .infinity)
                                .padding(.vertical, geometry.size.width > 600 ? 16 : 12)
                                .padding(.horizontal, geometry.size.width > 600 ? 32 : 16)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, geometry.size.width > 600 ? 0 : 20)
                        .accessibilityLabel("Select Photo")
                        .accessibilityHint("Opens photo picker to choose an image for your app icon")
                        
                        // Camera button for iOS/iPadOS only
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button {
                                HapticFeedback.medium()
                                showCamera = true
                            } label: {
                                Label("Take Photo", systemImage: "camera")
                                    .font(geometry.size.width > 600 ? .title3 : .headline)
                                    .frame(maxWidth: geometry.size.width > 600 ? 400 : .infinity)
                                    .padding(.vertical, geometry.size.width > 600 ? 16 : 12)
                                    .padding(.horizontal, geometry.size.width > 600 ? 32 : 16)
                                    .background(Color.green)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, geometry.size.width > 600 ? 0 : 20)
                            .accessibilityLabel("Take Photo")
                            .accessibilityHint("Opens camera to capture a new photo for your app icon")
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            #endif
    }
    
    private func loadSelectedImage() async {
        guard let selectedItem = selectedItem else {
            print("DEBUG: No selected item")
            return
        }
        
        print("DEBUG: Loading selected image...")
        
        do {
            if let data = try await selectedItem.loadTransferable(type: Data.self) {
                print("DEBUG: Data loaded, size: \(data.count) bytes")
                
                if let uiImage = UIImage(data: data) {
                    print("DEBUG: UIImage created successfully, size: \(uiImage.size)")
                    
                    await MainActor.run {
                        selectedImage = uiImage
                        showImageEditor = true
                        print("DEBUG: Navigation triggered, showImageEditor = \(showImageEditor)")
                    }
                } else {
                    print("DEBUG: Failed to create UIImage from data")
                    await MainActor.run {
                        currentError = AppIconMakerError.imageLoadFailed
                    }
                }
            } else {
                print("DEBUG: Failed to load data from PhotosPickerItem")
                await MainActor.run {
                    currentError = AppIconMakerError.imageLoadFailed
                }
            }
        } catch {
            print("DEBUG: Error loading image: \(error.localizedDescription)")
            await MainActor.run {
                currentError = AppIconMakerError.imageLoadFailed
            }
        }
    }
    
    #if os(macOS)
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        // Try to load as image
        if provider.hasItemConformingToTypeIdentifier("public.image") {
            provider.loadItem(forTypeIdentifier: "public.image", options: nil) { item, error in
                if let error = error {
                    print("Failed to load dropped image: \(error.localizedDescription)")
                    return
                }
                
                var imageData: Data?
                
                if let url = item as? URL {
                    imageData = try? Data(contentsOf: url)
                } else if let data = item as? Data {
                    imageData = data
                }
                
                if let data = imageData, let nsImage = NSImage(data: data) {
                    // Convert NSImage to UIImage
                    if let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                        let uiImage = UIImage(cgImage: cgImage)
                        
                        DispatchQueue.main.async {
                            self.selectedImage = uiImage
                            self.showImageEditor = true
                        }
                    }
                }
            }
            return true
        }
        
        // Try to load as file URL
        if provider.hasItemConformingToTypeIdentifier("public.file-url") {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                if let error = error {
                    print("Failed to load dropped file: \(error.localizedDescription)")
                    return
                }
                
                if let url = item as? URL,
                   let data = try? Data(contentsOf: url),
                   let nsImage = NSImage(data: data),
                   let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    let uiImage = UIImage(cgImage: cgImage)
                    
                    DispatchQueue.main.async {
                        self.selectedImage = uiImage
                        self.showImageEditor = true
                    }
                }
            }
            return true
        }
        
        return false
    }
    #endif
}

#Preview {
    WelcomeView()
}
