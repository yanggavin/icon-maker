---
status: draft
---

# App Icon Maker - iOS/iPadOS/macOS App

## Overview
A native Apple platform app that converts any photo into properly formatted app icons for iOS, iPadOS, and macOS development. The app will generate all required icon sizes and export them in the correct format.

## Requirements

### Functional Requirements
- Import photos from photo library or camera
- Crop and adjust photos to square format
- **AI-powered photo editing:**
  - Automatic background removal
  - Subject detection and auto-centering
  - Smart crop suggestions
  - AI-based image enhancement
  - Generate background variations (solid colors, gradients)
- Preview icon at different sizes
- Generate all required icon sizes for iOS/iPadOS/macOS
- Export as AppIcon.appiconset with Contents.json
- Support for light and dark mode icons
- Share/export functionality

### Technical Requirements
- SwiftUI for UI
- Support iOS 17+, iPadOS 17+, macOS 14+ (for Vision framework features)
- Universal app (iPhone, iPad, Mac)
- Photo picker integration
- Image processing with Core Graphics
- **Vision framework for AI features:**
  - VNGenerateForegroundInstanceMaskRequest for subject detection
  - Subject lifting API (iOS 17+)
  - Saliency analysis for smart cropping
- **Core Image for image enhancement**
- File export with proper directory structure

### Icon Sizes to Generate
**iOS/iPadOS:**
- 20x20 @2x, @3x (iPhone Notification)
- 29x29 @2x, @3x (iPhone Settings)
- 40x40 @2x, @3x (iPhone Spotlight)
- 60x60 @2x, @3x (iPhone App)
- 20x20 @1x, @2x (iPad Notification)
- 29x29 @1x, @2x (iPad Settings)
- 40x40 @1x, @2x (iPad Spotlight)
- 76x76 @1x, @2x (iPad App)
- 83.5x83.5 @2x (iPad Pro)
- 1024x1024 @1x (App Store)

**macOS:**
- 16x16 @1x, @2x
- 32x32 @1x, @2x
- 128x128 @1x, @2x
- 256x256 @1x, @2x
- 512x512 @1x, @2x

## Design

### Architecture
```
AppIconMaker/
├── App/
│   └── AppIconMakerApp.swift
├── Views/
│   ├── ContentView.swift
│   ├── ImagePickerView.swift
│   ├── ImageEditorView.swift
│   └── PreviewView.swift
├── Models/
│   ├── IconSize.swift
│   └── AppIconSet.swift
├── Services/
│   ├── ImageProcessor.swift
│   ├── AIImageService.swift
│   └── IconExporter.swift
└── Resources/
    └── Assets.xcassets
```

### User Flow
1. Launch app → Welcome screen with "Select Photo" button
2. Select photo → Photo picker opens
3. **AI Processing** → Automatic subject detection and background removal
4. Edit photo → Crop/adjust interface with:
   - Square crop guide
   - Toggle background removal on/off
   - Background color/gradient picker
   - AI enhancement toggle
   - Manual adjustments (zoom, pan, rotate)
5. Preview → See icon at various sizes with different backgrounds
6. Export → Generate and save AppIcon.appiconset

### UI Components
- Photo picker button
- **AI tools panel:**
  - Remove background toggle
  - Auto-enhance button
  - Smart crop suggestions
  - Background style picker (transparent, solid, gradient)
- Image crop/zoom controls
- Size preview grid
- Export button
- Platform selector (iOS/macOS/All)

## Implementation Tasks

### Task 1: Project Setup
- [ ] Create Xcode project with SwiftUI
- [ ] Configure multi-platform target
- [ ] Set up project structure
- [ ] Add required capabilities (Photo Library access)

### Task 2: Core Models
- [ ] Create IconSize model with all required sizes
- [ ] Create AppIconSet model for Contents.json structure
- [ ] Define platform-specific icon configurations

### Task 3: Image Selection
- [ ] Implement PhotosPicker integration
- [ ] Handle image import
- [ ] Add camera support for iOS/iPadOS

### Task 4: AI Image Processing
- [ ] Create AIImageService with Vision framework
- [ ] Implement subject detection using VNGenerateForegroundInstanceMaskRequest
- [ ] Add background removal functionality
- [ ] Implement saliency analysis for smart crop suggestions
- [ ] Add AI-based image enhancement with Core Image filters
- [ ] Create background generation (solid colors, gradients)

### Task 5: Image Editing UI
- [ ] Build crop interface with square aspect ratio
- [ ] Add zoom/pan controls
- [ ] Implement AI tools panel:
  - [ ] Background removal toggle
  - [ ] Auto-enhance button
  - [ ] Smart crop suggestions UI
  - [ ] Background style picker
- [ ] Show grid overlay for composition
- [ ] Add undo/redo functionality

### Task 6: Image Processing & Rendering
- [ ] Create ImageProcessor service
- [ ] Implement image resizing with high quality
- [ ] Composite subject with background
- [ ] Generate all required icon sizes
- [ ] Handle @1x, @2x, @3x scaling
- [ ] Preserve transparency when needed

### Task 7: Preview
- [ ] Build preview grid showing different sizes
- [ ] Display icons in context (home screen mockup)
- [ ] Show size labels

### Task 8: Export
- [ ] Create IconExporter service
- [ ] Generate Contents.json file
- [ ] Create AppIcon.appiconset directory structure
- [ ] Implement file export with ShareSheet
- [ ] Add option to export as ZIP

### Task 9: Polish
- [ ] Add app icon for the app itself
- [ ] Implement dark mode support
- [ ] Add haptic feedback
- [ ] Error handling and user feedback
- [ ] Add onboarding/help screen

## Testing Plan
- Test on iPhone (various sizes)
- Test on iPad
- Test on Mac (Apple Silicon and Intel)
- Verify exported icons work in Xcode
- Test with various photo types (portrait, landscape, square)

## AI Features Details

### Background Removal
- Uses Vision framework's subject lifting API (iOS 17+)
- Fallback to VNGenerateForegroundInstanceMaskRequest for older versions
- Real-time preview of subject extraction
- Option to refine edges manually

### Smart Crop Suggestions
- Analyzes image saliency to find optimal crop areas
- Suggests multiple crop options
- Auto-centers detected subjects
- Respects rule of thirds for composition

### AI Enhancement
- Auto-adjusts brightness, contrast, and saturation
- Sharpens details for small icon sizes
- Optimizes colors for visibility
- Preserves subject prominence

### Background Generation
- Solid colors extracted from image palette
- Gradient generation based on image colors
- Preset backgrounds (popular app icon styles)
- Custom color picker

## Future Enhancements
- Batch processing multiple icons
- Templates and presets
- AI-generated icon variations
- Style transfer for artistic effects
- Icon design tools (shapes, text overlay)
- Cloud sync of icon projects
- ML model for icon quality scoring
