# Design Document

## Overview

The App Icon Maker is a SwiftUI-based universal app for iOS 17+, iPadOS 17+, and macOS 14+ that transforms photos into complete app icon sets. The application leverages Apple's Vision framework for AI-powered subject detection and background removal, Core Image for enhancement, and Core Graphics for high-quality icon generation. The architecture follows MVVM pattern with clear separation between UI, business logic, and services.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     SwiftUI Views                        │
│  (ContentView, ImageEditor, Preview, Export)            │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│                    View Models                           │
│  (ImageEditorViewModel, PreviewViewModel)               │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│                      Services                            │
│  AIImageService │ ImageProcessor │ IconExporter         │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│                  Apple Frameworks                        │
│  Vision │ Core Image │ Core Graphics │ PhotosUI         │
└─────────────────────────────────────────────────────────┘
```

### Project Structure

```
AppIconMaker/
├── AppIconMakerApp.swift
├── Views/
│   ├── WelcomeView.swift
│   ├── ImageEditorView.swift
│   ├── AIToolsPanel.swift
│   ├── CropControlsView.swift
│   ├── BackgroundPickerView.swift
│   ├── PreviewView.swift
│   └── ExportView.swift
├── ViewModels/
│   ├── ImageEditorViewModel.swift
│   └── ExportViewModel.swift
├── Models/
│   ├── IconSize.swift
│   ├── AppIconSet.swift
│   ├── Platform.swift
│   ├── BackgroundStyle.swift
│   └── EditingState.swift
├── Services/
│   ├── AIImageService.swift
│   ├── ImageProcessor.swift
│   └── IconExporter.swift
├── Utilities/
│   ├── ImageExtensions.swift
│   └── ColorExtensions.swift
└── Resources/
    └── Assets.xcassets
```

## Components and Interfaces

### 1. Views

#### WelcomeView
- Entry point of the app
- Displays app branding and "Select Photo" button
- Integrates PhotosPicker for image selection
- Handles camera access on iOS/iPadOS

```swift
struct WelcomeView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    var body: some View
    // PhotosPicker integration
    // Navigation to ImageEditorView
}
```

#### ImageEditorView
- Main editing interface
- Displays image with crop overlay
- Hosts AIToolsPanel and CropControlsView
- Manages gesture recognizers (pinch, pan, rotate)
- Shows grid overlay for composition

```swift
struct ImageEditorView: View {
    @StateObject var viewModel: ImageEditorViewModel
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var rotation: Angle = .zero
    
    var body: some View
    // Image canvas with gestures
    // AI tools panel
    // Crop controls
    // Navigation to preview
}
```

#### AIToolsPanel
- Toggle for background removal
- Auto-enhance button
- Smart crop suggestions display
- Background style picker

```swift
struct AIToolsPanel: View {
    @Binding var backgroundRemoved: Bool
    @Binding var enhanced: Bool
    @Binding var backgroundStyle: BackgroundStyle
    let onSmartCrop: (CGRect) -> Void
    
    var body: some View
    // Background removal toggle
    // Enhancement button
    // Crop suggestions
    // Background picker
}
```

#### PreviewView
- Grid of icon previews at various sizes
- Context mockups (home screen simulation)
- Size labels
- Platform filter (iOS/iPadOS/macOS)

```swift
struct PreviewView: View {
    let processedImage: UIImage
    let iconSizes: [IconSize]
    @State private var selectedPlatform: Platform = .all
    
    var body: some View
    // Size filter
    // Icon grid
    // Context previews
}
```

#### ExportView
- Platform selection (iOS/iPadOS/macOS/All)
- Export format options (folder/ZIP)
- Progress indicator
- Share sheet integration

### 2. View Models

#### ImageEditorViewModel
Manages the editing state and coordinates between UI and services.

```swift
@MainActor
class ImageEditorViewModel: ObservableObject {
    @Published var originalImage: UIImage
    @Published var processedImage: UIImage
    @Published var isBackgroundRemoved: Bool = false
    @Published var isEnhanced: Bool = false
    @Published var backgroundStyle: BackgroundStyle = .transparent
    @Published var cropSuggestions: [CGRect] = []
    @Published var isProcessing: Bool = false
    @Published var editHistory: [EditingState] = []
    
    private let aiService: AIImageService
    private let imageProcessor: ImageProcessor
    
    func removeBackground() async
    func enhanceImage() async
    func generateCropSuggestions() async
    func applyBackground(_ style: BackgroundStyle) async
    func undo()
    func redo()
}
```

#### ExportViewModel
Handles icon generation and export process.

```swift
@MainActor
class ExportViewModel: ObservableObject {
    @Published var selectedPlatforms: Set<Platform> = [.iOS]
    @Published var exportFormat: ExportFormat = .folder
    @Published var isExporting: Bool = false
    @Published var progress: Double = 0.0
    
    private let iconExporter: IconExporter
    
    func generateIcons(from image: UIImage) async -> AppIconSet
    func exportIconSet(_ iconSet: AppIconSet) async throws -> URL
}
```

### 3. Models

#### IconSize
Represents a single icon size with metadata.

```swift
struct IconSize: Identifiable {
    let id = UUID()
    let size: CGFloat
    let scale: CGFloat
    let idiom: String // "iphone", "ipad", "mac"
    let filename: String
    
    var pointSize: CGFloat { size }
    var pixelSize: CGFloat { size * scale }
}
```

#### AppIconSet
Container for all generated icons and metadata.

```swift
struct AppIconSet {
    let icons: [IconSize: UIImage]
    let platforms: Set<Platform>
    
    func contentsJSON() -> Data
}
```

#### BackgroundStyle
Enum for background options.

```swift
enum BackgroundStyle {
    case transparent
    case solid(Color)
    case gradient(Gradient)
    
    var displayName: String
}
```

#### EditingState
Captures the state for undo/redo.

```swift
struct EditingState {
    let image: UIImage
    let transform: CGAffineTransform
    let backgroundRemoved: Bool
    let enhanced: Bool
    let backgroundStyle: BackgroundStyle
}
```

### 4. Services

#### AIImageService
Handles all AI-powered image processing using Vision framework.

```swift
class AIImageService {
    func detectSubject(in image: UIImage) async throws -> UIImage
    func removeBackground(from image: UIImage) async throws -> UIImage
    func enhanceImage(_ image: UIImage) async throws -> UIImage
    func analyzeSaliency(in image: UIImage) async throws -> [CGRect]
    func extractDominantColors(from image: UIImage) -> [Color]
}
```

**Implementation Details:**
- Uses `VNGenerateForegroundInstanceMaskRequest` for subject detection
- Leverages iOS 17+ subject lifting API when available
- Falls back to manual masking for older OS versions
- Uses `VNGenerateAttentionBasedSaliencyImageRequest` for crop suggestions
- Applies Core Image filters for enhancement: `CIColorControls`, `CISharpenLuminance`, `CIVibrance`

#### ImageProcessor
Handles image transformations and compositing.

```swift
class ImageProcessor {
    func resize(_ image: UIImage, to size: CGSize, scale: CGFloat) -> UIImage
    func crop(_ image: UIImage, to rect: CGRect) -> UIImage
    func composite(subject: UIImage, background: BackgroundStyle, size: CGSize) -> UIImage
    func applyTransform(_ transform: CGAffineTransform, to image: UIImage) -> UIImage
}
```

**Implementation Details:**
- Uses Core Graphics for high-quality rendering
- Maintains image quality with proper interpolation
- Handles transparency correctly
- Optimizes for performance with image caching

#### IconExporter
Generates icon sets and creates AppIcon.appiconset bundles.

```swift
class IconExporter {
    func generateIconSet(from image: UIImage, platforms: Set<Platform>) async -> AppIconSet
    func createAppIconSet(_ iconSet: AppIconSet, at url: URL) throws
    func createZipArchive(from url: URL) throws -> URL
}
```

**Implementation Details:**
- Generates all required sizes per platform
- Creates proper directory structure
- Generates Contents.json with correct metadata
- Handles file I/O with proper error handling

## Data Models

### Icon Size Specifications

```swift
struct IconSizeSpec {
    static let iOS: [IconSize] = [
        IconSize(size: 20, scale: 2, idiom: "iphone", filename: "Icon-20@2x.png"),
        IconSize(size: 20, scale: 3, idiom: "iphone", filename: "Icon-20@3x.png"),
        IconSize(size: 29, scale: 2, idiom: "iphone", filename: "Icon-29@2x.png"),
        IconSize(size: 29, scale: 3, idiom: "iphone", filename: "Icon-29@3x.png"),
        IconSize(size: 40, scale: 2, idiom: "iphone", filename: "Icon-40@2x.png"),
        IconSize(size: 40, scale: 3, idiom: "iphone", filename: "Icon-40@3x.png"),
        IconSize(size: 60, scale: 2, idiom: "iphone", filename: "Icon-60@2x.png"),
        IconSize(size: 60, scale: 3, idiom: "iphone", filename: "Icon-60@3x.png"),
        IconSize(size: 1024, scale: 1, idiom: "ios-marketing", filename: "Icon-1024.png")
    ]
    
    static let iPadOS: [IconSize] = [
        IconSize(size: 20, scale: 1, idiom: "ipad", filename: "Icon-20.png"),
        IconSize(size: 20, scale: 2, idiom: "ipad", filename: "Icon-20@2x.png"),
        IconSize(size: 29, scale: 1, idiom: "ipad", filename: "Icon-29.png"),
        IconSize(size: 29, scale: 2, idiom: "ipad", filename: "Icon-29@2x.png"),
        IconSize(size: 40, scale: 1, idiom: "ipad", filename: "Icon-40.png"),
        IconSize(size: 40, scale: 2, idiom: "ipad", filename: "Icon-40@2x.png"),
        IconSize(size: 76, scale: 1, idiom: "ipad", filename: "Icon-76.png"),
        IconSize(size: 76, scale: 2, idiom: "ipad", filename: "Icon-76@2x.png"),
        IconSize(size: 83.5, scale: 2, idiom: "ipad", filename: "Icon-83.5@2x.png")
    ]
    
    static let macOS: [IconSize] = [
        IconSize(size: 16, scale: 1, idiom: "mac", filename: "Icon-16.png"),
        IconSize(size: 16, scale: 2, idiom: "mac", filename: "Icon-16@2x.png"),
        IconSize(size: 32, scale: 1, idiom: "mac", filename: "Icon-32.png"),
        IconSize(size: 32, scale: 2, idiom: "mac", filename: "Icon-32@2x.png"),
        IconSize(size: 128, scale: 1, idiom: "mac", filename: "Icon-128.png"),
        IconSize(size: 128, scale: 2, idiom: "mac", filename: "Icon-128@2x.png"),
        IconSize(size: 256, scale: 1, idiom: "mac", filename: "Icon-256.png"),
        IconSize(size: 256, scale: 2, idiom: "mac", filename: "Icon-256@2x.png"),
        IconSize(size: 512, scale: 1, idiom: "mac", filename: "Icon-512.png"),
        IconSize(size: 512, scale: 2, idiom: "mac", filename: "Icon-512@2x.png")
    ]
}
```

### Contents.json Structure

```json
{
  "images": [
    {
      "filename": "Icon-20@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "20x20"
    },
    ...
  ],
  "info": {
    "author": "app-icon-maker",
    "version": 1
  }
}
```

## Error Handling

### Error Types

```swift
enum AppIconMakerError: LocalizedError {
    case imageLoadFailed
    case subjectDetectionFailed
    case backgroundRemovalFailed
    case enhancementFailed
    case exportFailed(reason: String)
    case insufficientPermissions
    case unsupportedImageFormat
    
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
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .insufficientPermissions:
            return "Photo library access is required"
        case .unsupportedImageFormat:
            return "This image format is not supported"
        }
    }
}
```

### Error Handling Strategy

1. **User-Facing Errors**: Display alerts with clear messages and recovery options
2. **Graceful Degradation**: If AI features fail, allow manual editing
3. **Logging**: Use OSLog for debugging without exposing internals to users
4. **Retry Logic**: Implement retry for transient failures
5. **Validation**: Validate inputs before processing

```swift
func removeBackground() async {
    isProcessing = true
    defer { isProcessing = false }
    
    do {
        processedImage = try await aiService.removeBackground(from: originalImage)
        isBackgroundRemoved = true
    } catch {
        // Show error alert
        // Log error
        // Offer manual editing option
    }
}
```

## Testing Strategy

### Unit Tests

1. **Model Tests**
   - IconSize calculations
   - AppIconSet JSON generation
   - BackgroundStyle equality

2. **Service Tests**
   - ImageProcessor resize accuracy
   - Color extraction from images
   - Icon filename generation

3. **ViewModel Tests**
   - State management
   - Undo/redo functionality
   - Background style application

### Integration Tests

1. **AI Service Tests**
   - Subject detection with sample images
   - Background removal quality
   - Saliency analysis accuracy

2. **Export Tests**
   - Complete icon set generation
   - Contents.json validity
   - File structure correctness

### UI Tests

1. **User Flow Tests**
   - Complete icon creation workflow
   - Photo selection and editing
   - Export and share

2. **Platform-Specific Tests**
   - iPhone interface
   - iPad interface
   - Mac interface

### Manual Testing

1. **Image Quality**
   - Test with various photo types (portrait, landscape, complex backgrounds)
   - Verify icon clarity at all sizes
   - Check edge quality after background removal

2. **Performance**
   - Measure AI processing time
   - Test with large images (>10MB)
   - Monitor memory usage

3. **Xcode Integration**
   - Import generated AppIcon.appiconset into test project
   - Verify all sizes display correctly
   - Test on actual devices

## Performance Considerations

### Optimization Strategies

1. **Image Caching**: Cache processed images to avoid reprocessing
2. **Lazy Loading**: Generate icon previews on-demand
3. **Background Processing**: Use async/await for all heavy operations
4. **Memory Management**: Release large images when not needed
5. **Progressive Enhancement**: Show low-res preview while processing high-res

### Performance Targets

- Background removal: < 3 seconds
- Enhancement: < 1 second
- Icon set generation: < 5 seconds
- UI responsiveness: 60 FPS during gestures
- Memory usage: < 200MB for typical workflow

## Accessibility

1. **VoiceOver Support**: All controls properly labeled
2. **Dynamic Type**: Support text scaling
3. **High Contrast**: Ensure visibility in high contrast mode
4. **Keyboard Navigation**: Full keyboard support on macOS
5. **Haptic Feedback**: Provide feedback for actions on iOS/iPadOS

## Privacy and Security

1. **Photo Access**: Request minimal permissions (selected photos only)
2. **On-Device Processing**: All AI processing happens locally
3. **No Data Collection**: No analytics or telemetry
4. **Temporary Files**: Clean up temporary files after export
5. **Secure Export**: Use secure file handling APIs

## Platform-Specific Considerations

### iOS/iPadOS
- Support both portrait and landscape orientations
- Optimize for touch gestures
- Use native photo picker
- Support camera integration
- Implement haptic feedback

### macOS
- Support keyboard shortcuts (Cmd+Z for undo, etc.)
- Implement menu bar items
- Support drag-and-drop for image import
- Use native file save dialog
- Optimize for mouse/trackpad interaction

## Future Extensibility

The architecture supports future enhancements:

1. **Batch Processing**: Process multiple images simultaneously
2. **Templates**: Pre-designed icon styles and layouts
3. **Cloud Sync**: Sync projects across devices (iCloud)
4. **Advanced AI**: Style transfer, generative backgrounds
5. **Collaboration**: Share projects with team members
6. **Plugins**: Third-party filter and effect plugins
