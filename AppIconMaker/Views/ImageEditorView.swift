//
//  ImageEditorView.swift
//  AppIconMaker
//
//  Created by App Icon Maker
//

import SwiftUI

struct ImageEditorView: View {
    @StateObject var viewModel: ImageEditorViewModel
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var rotation: Angle = .zero
    @State private var showGrid: Bool = true
    @State private var showAITools: Bool = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main canvas area
                VStack {
                    // Image canvas with overlays
                    ZStack {
                        // Background checkerboard pattern for transparency
                        CheckerboardPattern()
                            .frame(width: canvasSize(in: geometry), height: canvasSize(in: geometry))
                        
                        // The edited image
                        Image(uiImage: viewModel.processedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: canvasSize(in: geometry), height: canvasSize(in: geometry))
                            .scaleEffect(scale)
                            .rotationEffect(rotation)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = value
                                    }
                                    .onEnded { value in
                                        // Clamp scale between 0.5x and 5x
                                        scale = min(max(value, 0.5), 5.0)
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = value.translation
                                    }
                                    .onEnded { value in
                                        offset = value.translation
                                    }
                            )
                            .simultaneousGesture(
                                RotationGesture()
                                    .onChanged { value in
                                        rotation = value
                                    }
                                    .onEnded { value in
                                        rotation = value
                                    }
                            )
                            .accessibilityLabel("Icon Image Canvas")
                            .accessibilityHint("Pinch to zoom, drag to move, rotate with two fingers to adjust the image")
                        
                        // Square crop overlay guide
                        CropOverlay()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: canvasSize(in: geometry), height: canvasSize(in: geometry))
                            .shadow(color: .black.opacity(0.3), radius: 2)
                        
                        // Grid overlay for composition
                        if showGrid {
                            GridOverlay()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                .frame(width: canvasSize(in: geometry), height: canvasSize(in: geometry))
                                .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray5))
                    
                    // Bottom toolbar
                    HStack {
                        Button(action: {
                            HapticFeedback.light()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showGrid.toggle()
                            }
                        }) {
                            Image(systemName: showGrid ? "grid" : "grid.circle")
                                .font(.title3)
                        }
                        .accessibilityLabel(showGrid ? "Hide Grid" : "Show Grid")
                        .accessibilityHint("Toggles composition grid overlay")
                        
                        Spacer()
                        
                        Button(action: {
                            HapticFeedback.light()
                            viewModel.undo()
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.title3)
                        }
                        .disabled(!viewModel.canUndo)
                        .accessibilityLabel("Undo")
                        .accessibilityHint("Reverts the last editing action")
                        
                        Button(action: {
                            HapticFeedback.light()
                            viewModel.redo()
                        }) {
                            Image(systemName: "arrow.uturn.forward")
                                .font(.title3)
                        }
                        .disabled(!viewModel.canRedo)
                        .accessibilityLabel("Redo")
                        .accessibilityHint("Reapplies the last undone action")
                        
                        Spacer()
                        
                        NavigationLink(destination: PreviewView(processedImage: viewModel.processedImage)) {
                            HStack {
                                Text("Preview")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .accessibilityLabel("Preview Icons")
                        .accessibilityHint("Shows preview of your icon at different sizes")
                    }
                    .padding()
                }
                
                // AI Tools Panel on the side (for iPad/Mac) or bottom sheet (for iPhone)
                #if os(macOS)
                Divider()
                ScrollView {
                    AIToolsPanel(viewModel: viewModel)
                }
                .frame(width: 320)
                #elseif os(iOS)
                if horizontalSizeClass == .regular {
                    // iPad layout - side panel
                    Divider()
                    ScrollView {
                        AIToolsPanel(viewModel: viewModel)
                    }
                    .frame(width: 320)
                }
                #endif
            }
        }
        .navigationTitle("Edit Icon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            #if os(iOS)
            if horizontalSizeClass == .compact {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedback.light()
                        showAITools.toggle()
                    }) {
                        Image(systemName: "wand.and.stars")
                            .font(.title3)
                    }
                    .accessibilityLabel("AI Tools")
                    .accessibilityHint("Opens AI-powered editing tools")
                }
            }
            #endif
        }
        #if os(iOS)
        .sheet(isPresented: $showAITools) {
            // iPhone layout - bottom sheet
            NavigationStack {
                ScrollView {
                    AIToolsPanel(viewModel: viewModel)
                }
                .navigationTitle("AI Tools")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showAITools = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        #endif
        #if os(macOS)
        .onKeyPress(.init("z", modifiers: .command)) {
            viewModel.undo()
            return .handled
        }
        .onKeyPress(.init("z", modifiers: [.command, .shift])) {
            viewModel.redo()
            return .handled
        }
        .onKeyPress(.init("g", modifiers: .command)) {
            showGrid.toggle()
            return .handled
        }
        #endif
        .errorAlert(error: $viewModel.currentError)
    }
    
    // MARK: - Helper Methods
    
    private func canvasSize(in geometry: GeometryProxy) -> CGFloat {
        let availableWidth = geometry.size.width
        let availableHeight = geometry.size.height - 100 // Account for toolbar
        
        #if os(macOS)
        // macOS - larger canvas with side panel
        let adjustedWidth = availableWidth - 320
        let size = min(adjustedWidth, availableHeight) * 0.85
        return max(size, 400) // Larger minimum for Mac
        #elseif os(iOS)
        // iOS/iPadOS - adaptive based on size class
        let adjustedWidth = horizontalSizeClass == .regular ? availableWidth - 320 : availableWidth
        let multiplier: CGFloat = horizontalSizeClass == .regular ? 0.85 : 0.75
        let size = min(adjustedWidth, availableHeight) * multiplier
        let minSize: CGFloat = horizontalSizeClass == .regular ? 300 : 200
        return max(size, minSize)
        #else
        let adjustedWidth = availableWidth
        let size = min(adjustedWidth, availableHeight) * 0.8
        return max(size, 200)
        #endif
    }
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
}

// MARK: - Supporting Views

/// Checkerboard pattern to indicate transparency
struct CheckerboardPattern: View {
    let squareSize: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let columns = Int(geometry.size.width / squareSize) + 1
            let rows = Int(geometry.size.height / squareSize) + 1
            
            Canvas { context, size in
                for row in 0..<rows {
                    for col in 0..<columns {
                        let isEven = (row + col) % 2 == 0
                        let rect = CGRect(
                            x: CGFloat(col) * squareSize,
                            y: CGFloat(row) * squareSize,
                            width: squareSize,
                            height: squareSize
                        )
                        
                        let lightColor = Color(uiColor: .systemBackground)
                        let darkColor = Color(uiColor: .systemGray5)
                        context.fill(
                            Path(rect),
                            with: .color(isEven ? lightColor : darkColor)
                        )
                    }
                }
            }
        }
    }
}

/// Square crop overlay guide
struct CropOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Draw square border
        path.addRect(rect)
        
        // Add corner markers
        let markerLength: CGFloat = 20
        let markerOffset: CGFloat = 0
        
        // Top-left corner
        path.move(to: CGPoint(x: rect.minX + markerOffset, y: rect.minY + markerLength))
        path.addLine(to: CGPoint(x: rect.minX + markerOffset, y: rect.minY + markerOffset))
        path.addLine(to: CGPoint(x: rect.minX + markerLength, y: rect.minY + markerOffset))
        
        // Top-right corner
        path.move(to: CGPoint(x: rect.maxX - markerLength, y: rect.minY + markerOffset))
        path.addLine(to: CGPoint(x: rect.maxX - markerOffset, y: rect.minY + markerOffset))
        path.addLine(to: CGPoint(x: rect.maxX - markerOffset, y: rect.minY + markerLength))
        
        // Bottom-left corner
        path.move(to: CGPoint(x: rect.minX + markerOffset, y: rect.maxY - markerLength))
        path.addLine(to: CGPoint(x: rect.minX + markerOffset, y: rect.maxY - markerOffset))
        path.addLine(to: CGPoint(x: rect.minX + markerLength, y: rect.maxY - markerOffset))
        
        // Bottom-right corner
        path.move(to: CGPoint(x: rect.maxX - markerLength, y: rect.maxY - markerOffset))
        path.addLine(to: CGPoint(x: rect.maxX - markerOffset, y: rect.maxY - markerOffset))
        path.addLine(to: CGPoint(x: rect.maxX - markerOffset, y: rect.maxY - markerLength))
        
        return path
    }
}

/// Grid overlay for composition (rule of thirds)
struct GridOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Vertical lines (rule of thirds)
        let verticalSpacing = rect.width / 3
        path.move(to: CGPoint(x: rect.minX + verticalSpacing, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + verticalSpacing, y: rect.maxY))
        
        path.move(to: CGPoint(x: rect.minX + verticalSpacing * 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + verticalSpacing * 2, y: rect.maxY))
        
        // Horizontal lines (rule of thirds)
        let horizontalSpacing = rect.height / 3
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + horizontalSpacing))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + horizontalSpacing))
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + horizontalSpacing * 2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + horizontalSpacing * 2))
        
        return path
    }
}

#Preview {
    NavigationStack {
        ImageEditorView(viewModel: ImageEditorViewModel(image: UIImage(systemName: "photo")!))
    }
}
