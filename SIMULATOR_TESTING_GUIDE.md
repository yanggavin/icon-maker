# iOS Simulator Testing Guide

## Quick Start

### 1. Open the Project
```bash
cd /Users/gavinyang/dev/icon-builder
open AppIconMaker.xcodeproj
```

### 2. Select Simulator
In Xcode:
- Click on the device selector (top toolbar, next to the scheme)
- Choose: **iPhone 15 Pro** (or any iOS 17.0+ simulator)

### 3. Build and Run
- Press `⌘R` or click the ▶️ Play button
- Wait for the build to complete
- The simulator will launch automatically

---

## Testing Checklist

### Welcome Screen
- [ ] App launches successfully
- [ ] Welcome screen displays with title and description
- [ ] "Select Image" button is visible and styled correctly
- [ ] Take screenshot: `⌘S` → Save as `01-welcome-screen.png`

### Image Selection
- [ ] Tap "Select Image" button
- [ ] Photo picker appears
- [ ] Select a test image (you may need to add photos to the simulator)
- [ ] Image loads and displays in editor
- [ ] Take screenshot: `⌘S` → Save as `02-image-loaded.png`

**Note:** To add photos to simulator:
1. Drag and drop an image file onto the simulator window
2. Or use: `xcrun simctl addmedia booted /path/to/image.jpg`

### AI Tools Panel
- [ ] AI Tools panel is visible on the left side
- [ ] "Remove Background" button is present
- [ ] "Enhance Image" button is present
- [ ] "Smart Crop" button is present
- [ ] Take screenshot: `⌘S` → Save as `03-ai-tools-panel.png`

### Background Removal
- [ ] Tap "Remove Background" button
- [ ] Loading indicator appears
- [ ] Background is removed (subject isolated)
- [ ] Processing completes within 3 seconds
- [ ] Take screenshot: `⌘S` → Save as `04-background-removed.png`

### Image Enhancement
- [ ] Tap "Enhance Image" button
- [ ] Loading indicator appears
- [ ] Image is enhanced (brighter, more vibrant)
- [ ] Processing completes within 1 second
- [ ] Take screenshot: `⌘S` → Save as `05-image-enhanced.png`

### Smart Crop Suggestions
- [ ] Tap "Smart Crop" button
- [ ] Crop suggestions appear (2-3 options)
- [ ] Can select different crop suggestions
- [ ] Crop is applied correctly
- [ ] Take screenshot: `⌘S` → Save as `06-smart-crop.png`

### Background Style Selection
- [ ] Background style picker is visible
- [ ] Can select "Transparent"
- [ ] Can select "Solid Color"
- [ ] Can select "Gradient"
- [ ] Color picker works for solid colors
- [ ] Gradient options work
- [ ] Take screenshot: `⌘S` → Save as `07-background-styles.png`

### Preview Screen
- [ ] Navigate to Preview tab/screen
- [ ] Icon preview grid displays
- [ ] Multiple icon sizes are shown
- [ ] Icons render correctly at all sizes
- [ ] Can zoom/inspect individual icons
- [ ] Take screenshot: `⌘S` → Save as `08-preview-grid.png`

### Export Screen
- [ ] Navigate to Export tab/screen
- [ ] Platform selection is available (iOS, iPadOS, macOS)
- [ ] Can select multiple platforms
- [ ] Export format options (Folder/ZIP) are available
- [ ] "Export" button is visible
- [ ] Take screenshot: `⌘S` → Save as `09-export-options.png`

### Export Process
- [ ] Tap "Export" button
- [ ] Progress indicator appears
- [ ] Export completes within 5 seconds
- [ ] Success message or share sheet appears
- [ ] Take screenshot: `⌘S` → Save as `10-export-complete.png`

### Error Handling
- [ ] Try with an invalid image (if possible)
- [ ] Error messages display correctly
- [ ] App doesn't crash
- [ ] Can recover from errors
- [ ] Take screenshot: `⌘S` → Save as `11-error-handling.png`

---

## Performance Testing

### Memory Usage
1. Open Xcode's Debug Navigator (⌘7)
2. Select "Memory" gauge
3. Perform operations and monitor memory
4. Expected: < 200MB during normal operation
5. Take screenshot of memory graph

### Processing Times
Use the console logs to verify:
- Background removal: < 3 seconds
- Enhancement: < 1 second
- Icon generation: < 5 seconds

### Caching Test
1. Remove background from an image
2. Note the processing time
3. Undo the operation
4. Remove background again
5. Second operation should be near-instantaneous (cached)

---

## Screenshot Locations

All screenshots taken with `⌘S` are saved to:
```
~/Desktop/
```

They will be named like:
- `Simulator Screenshot - iPhone 15 Pro - 2024-10-22 at 14.30.45.png`

---

## Troubleshooting

### Build Errors
If you encounter build errors:

1. **Clean Build Folder**
   ```
   ⌘⇧K (Product → Clean Build Folder)
   ```

2. **Reset Package Caches** (if using SPM)
   ```
   File → Packages → Reset Package Caches
   ```

3. **Check Signing**
   - Select project in navigator
   - Select target "AppIconMaker"
   - Go to "Signing & Capabilities"
   - Ensure "Automatically manage signing" is checked
   - Select your team

### Simulator Issues

1. **Simulator Won't Launch**
   ```bash
   # Reset simulator
   xcrun simctl shutdown all
   xcrun simctl erase all
   ```

2. **App Won't Install**
   ```bash
   # Delete app from simulator
   xcrun simctl uninstall booted tech.newtree.icon-maker
   ```

3. **Photos Not Available**
   ```bash
   # Add sample photos
   xcrun simctl addmedia booted ~/Pictures/sample.jpg
   ```

### Performance Issues

If the app is slow in the simulator:
- Try a different simulator (newer iPhone models)
- Check "Debug → Graphics Quality Override → High Quality"
- Ensure your Mac has sufficient resources

---

## Command Line Testing

### Build Only (No Run)
```bash
xcodebuild -project AppIconMaker.xcodeproj \
  -scheme AppIconMaker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

### Run Tests (if tests exist)
```bash
xcodebuild test \
  -project AppIconMaker.xcodeproj \
  -scheme AppIconMaker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Install on Simulator
```bash
# Build and get app path
xcodebuild -project AppIconMaker.xcodeproj \
  -scheme AppIconMaker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -derivedDataPath ./build

# Install
xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/AppIconMaker.app
```

---

## Screenshot Organization

Suggested folder structure for screenshots:
```
Screenshots/
├── 01-welcome-screen.png
├── 02-image-loaded.png
├── 03-ai-tools-panel.png
├── 04-background-removed.png
├── 05-image-enhanced.png
├── 06-smart-crop.png
├── 07-background-styles.png
├── 08-preview-grid.png
├── 09-export-options.png
├── 10-export-complete.png
├── 11-error-handling.png
└── 12-memory-usage.png
```

---

## Next Steps After Testing

1. **Review Screenshots**
   - Check UI layout and styling
   - Verify all features are visible
   - Look for any visual bugs

2. **Document Issues**
   - Note any crashes or errors
   - Record performance problems
   - List UI/UX improvements

3. **Update Testing Results**
   - Fill out `TESTING_RESULTS.md`
   - Mark completed test cases
   - Add notes and observations

4. **Share Results**
   - Create a folder with all screenshots
   - Write a summary of findings
   - Report any bugs or issues

---

## Sample Test Images

For comprehensive testing, use images with:
1. **Portrait photo** - Person with clear background
2. **Landscape photo** - Scenic view
3. **Complex background** - Busy pattern or gradient
4. **Large image** - High resolution (>10MB)
5. **Small image** - Low resolution
6. **Transparent PNG** - Already has transparency
7. **Logo/Icon** - Simple graphic design

---

## Expected Results

### Performance Targets
- ✅ Background removal: < 3 seconds
- ✅ Enhancement: < 1 second
- ✅ Icon generation: < 5 seconds
- ✅ Memory usage: < 200MB
- ✅ Cached operations: Near-instant

### Quality Targets
- ✅ Icons clear at all sizes (16x16 to 1024x1024)
- ✅ No pixelation or artifacts
- ✅ Proper transparency handling
- ✅ Accurate background removal
- ✅ Professional appearance

---

## Contact & Support

If you encounter issues during testing:
1. Check the console logs in Xcode
2. Review the troubleshooting section above
3. Document the issue with screenshots
4. Check the error handling implementation

---

**Happy Testing! 🚀**
