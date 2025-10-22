# App Icon Maker 🎨

[![iOS CI](https://github.com/yanggavin/icon-maker/workflows/iOS%20CI/badge.svg)](https://github.com/yanggavin/icon-maker/actions)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20iPadOS%20%7C%20macOS-lightgrey)](https://developer.apple.com/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0-blue)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A powerful iOS app that uses AI to create professional app icons for iOS, iPadOS, and macOS. Remove backgrounds, enhance images, and generate complete icon sets with just a few taps.

![App Icon Maker Banner](docs/banner.png)

---

## ✨ Features

### 🤖 AI-Powered Tools
- **Background Removal** - Automatically isolate subjects using Vision framework
- **Image Enhancement** - Optimize colors, contrast, and sharpness
- **Smart Crop** - AI-suggested crop regions using saliency analysis
- **Color Extraction** - Extract dominant colors for backgrounds

### 🎨 Customization
- **Background Styles** - Transparent, solid colors, or gradients
- **Manual Adjustments** - Fine-tune crop, rotation, and scale
- **Real-time Preview** - See changes instantly
- **Undo/Redo** - Full editing history

### 📱 Icon Generation
- **Multi-Platform** - iOS, iPadOS, and macOS icons
- **All Sizes** - From 16x16 to 1024x1024
- **Xcode Ready** - Export as AppIcon.appiconset
- **ZIP Export** - Easy sharing and distribution

### ⚡ Performance
- **Fast Processing** - Background removal < 3 seconds
- **Intelligent Caching** - Instant repeated operations
- **Concurrent Generation** - Icons generated in parallel
- **Memory Efficient** - Optimized for all devices

---

## 📸 Screenshots

| Welcome Screen | Image Editor | AI Tools | Preview |
|---------------|--------------|----------|---------|
| ![Welcome](docs/screenshots/welcome.png) | ![Editor](docs/screenshots/editor.png) | ![AI Tools](docs/screenshots/ai-tools.png) | ![Preview](docs/screenshots/preview.png) |

| Background Styles | Export Options | Icon Grid | Final Result |
|------------------|----------------|-----------|--------------|
| ![Backgrounds](docs/screenshots/backgrounds.png) | ![Export](docs/screenshots/export.png) | ![Grid](docs/screenshots/grid.png) | ![Result](docs/screenshots/result.png) |

---

## 🚀 Getting Started

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- iOS 17.0+ device or simulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yanggavin/icon-maker.git
   cd icon-maker
   ```

2. **Open in Xcode**
   ```bash
   open AppIconMaker.xcodeproj
   ```

3. **Select a simulator or device**
   - Choose from the device menu (e.g., iPhone 15 Pro)

4. **Build and run**
   - Press `⌘R` or click the Play button
   - Wait for the app to launch

### Quick Start

1. **Launch the app** and tap "Select Image"
2. **Choose a photo** from your library
3. **Apply AI tools** - Remove background, enhance, or crop
4. **Customize** - Add background colors or gradients
5. **Preview** - Check all icon sizes
6. **Export** - Save as AppIcon.appiconset or ZIP

---

## 🏗️ Architecture

### Tech Stack

- **Language:** Swift 5.9
- **UI Framework:** SwiftUI
- **AI/ML:** Vision Framework, Core Image
- **Architecture:** MVVM
- **Concurrency:** Swift Concurrency (async/await)
- **Testing:** XCTest
- **CI/CD:** GitHub Actions, Fastlane

### Project Structure

```
AppIconMaker/
├── Models/              # Data models
│   ├── IconSize.swift
│   ├── Platform.swift
│   ├── BackgroundStyle.swift
│   └── AppIconSet.swift
├── Views/               # SwiftUI views
│   ├── WelcomeView.swift
│   ├── ImageEditorView.swift
│   ├── AIToolsPanel.swift
│   ├── PreviewView.swift
│   └── ExportView.swift
├── ViewModels/          # View models
│   ├── ImageEditorViewModel.swift
│   └── ExportViewModel.swift
├── Services/            # Business logic
│   ├── AIImageService.swift
│   ├── ImageProcessor.swift
│   ├── IconExporter.swift
│   └── ImageCache.swift
└── Utilities/           # Helper utilities
    ├── ErrorHandling.swift
    ├── HapticFeedback.swift
    ├── ImagePicker.swift
    └── ShareSheet.swift
```

---

## 🧪 Testing

### Running Tests

```bash
# Using xcodebuild
xcodebuild test \
  -project AppIconMaker.xcodeproj \
  -scheme AppIconMaker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Using Fastlane
fastlane test
```

### Test Coverage

- **Unit Tests:** Models, Services, ViewModels
- **Performance Tests:** Image processing, caching
- **Integration Tests:** End-to-end workflows

Current coverage: **TBD** (run `fastlane coverage`)

### Manual Testing

See [SIMULATOR_TESTING_GUIDE.md](SIMULATOR_TESTING_GUIDE.md) for comprehensive manual testing procedures.

---

## 🔧 Development

### Setup Development Environment

```bash
# Install dependencies
brew install swiftlint fastlane

# Run code quality checks
swiftlint

# Auto-fix issues
swiftlint --fix
```

### Code Quality

We use SwiftLint to maintain code quality. Configuration in `.swiftlint.yml`.

**Rules:**
- Line length: 120 characters
- Function body: < 50 lines
- Type body: < 300 lines
- Cyclomatic complexity: < 10

### Git Workflow

1. Create a feature branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make changes and commit
   ```bash
   git add .
   git commit -m "feat: Add your feature"
   ```

3. Push and create PR
   ```bash
   git push origin feature/your-feature-name
   ```

4. Wait for CI to pass
5. Request review
6. Merge after approval

---

## 🤖 CI/CD

### GitHub Actions

Automated workflows run on every push and PR:

- ✅ Build and test on multiple simulators
- ✅ Code quality checks with SwiftLint
- ✅ Performance analysis
- ✅ Code coverage reporting
- ✅ Build archive generation

See [CI_CD_SETUP.md](CI_CD_SETUP.md) for detailed documentation.

### Fastlane

Available lanes:

```bash
fastlane test              # Run all tests
fastlane build             # Build the app
fastlane lint              # Run SwiftLint
fastlane quality           # Run all quality checks
fastlane coverage          # Generate coverage report
fastlane clean             # Clean build artifacts
```

---

## 📚 Documentation

- [Requirements](. kiro/specs/app-icon-maker/requirements.md) - Feature requirements
- [Design](. kiro/specs/app-icon-maker/design.md) - Architecture and design
- [Tasks](.kiro/specs/app-icon-maker/tasks.md) - Implementation tasks
- [CI/CD Setup](CI_CD_SETUP.md) - CI/CD configuration
- [Testing Guide](SIMULATOR_TESTING_GUIDE.md) - Manual testing procedures
- [Xcode Integration](XCODE_INTEGRATION_GUIDE.md) - Xcode integration verification

---

## 🎯 Roadmap

### Version 1.0 (Current)
- ✅ AI-powered background removal
- ✅ Image enhancement
- ✅ Smart crop suggestions
- ✅ Custom backgrounds
- ✅ Multi-platform icon generation
- ✅ AppIcon.appiconset export

### Version 1.1 (Planned)
- [ ] Batch processing
- [ ] Custom icon templates
- [ ] Cloud sync
- [ ] Icon history
- [ ] Advanced editing tools

### Version 2.0 (Future)
- [ ] macOS app
- [ ] Watch app icons
- [ ] Widget icons
- [ ] App Store screenshots
- [ ] Brand kit integration

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Ensure CI passes
6. Submit a pull request

### Code Style

- Follow SwiftLint rules
- Write descriptive commit messages
- Add comments for complex logic
- Update documentation

### Reporting Issues

- Use GitHub Issues
- Provide detailed description
- Include steps to reproduce
- Add screenshots if applicable

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👏 Acknowledgments

- **Apple Vision Framework** - For AI-powered image processing
- **Core Image** - For image enhancement
- **SwiftUI** - For modern UI development
- **Fastlane** - For automation
- **SwiftLint** - For code quality

---

## 📞 Contact

- **GitHub:** [@yanggavin](https://github.com/yanggavin)
- **Repository:** [icon-maker](https://github.com/yanggavin/icon-maker)
- **Issues:** [GitHub Issues](https://github.com/yanggavin/icon-maker/issues)

---

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yanggavin/icon-maker&type=Date)](https://star-history.com/#yanggavin/icon-maker&Date)

---

## 📊 Stats

![GitHub repo size](https://img.shields.io/github/repo-size/yanggavin/icon-maker)
![GitHub code size](https://img.shields.io/github/languages/code-size/yanggavin/icon-maker)
![GitHub last commit](https://img.shields.io/github/last-commit/yanggavin/icon-maker)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/yanggavin/icon-maker)

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/yanggavin">Gavin Yang</a>
</p>

<p align="center">
  <a href="#app-icon-maker-">Back to top</a>
</p>
