# App Icon Setup

This AppIcon.appiconset is configured and ready for your app icon images.

## How to Add Your App Icon

1. Design your app icon (1024x1024 pixels recommended as the source)
2. Use an icon generator tool or the App Icon Maker app itself to generate all required sizes
3. Drag the generated icon files into this folder, or
4. Use Xcode's asset catalog to add your icon:
   - Open the project in Xcode
   - Navigate to Assets.xcassets > AppIcon
   - Drag your 1024x1024 icon into the "App Store" slot
   - Xcode will automatically generate the other sizes

## Icon Design Guidelines

For the App Icon Maker app icon, consider:
- A stylized app icon or badge symbol
- Gradient background (blue to purple works well)
- Simple, recognizable design that works at small sizes
- Follows Apple's Human Interface Guidelines

## Required Sizes

The Contents.json file is already configured with all required sizes for:
- iPhone (iOS 17+)
- iPad (iPadOS 17+)
- Mac (macOS 14+)
- App Store (1024x1024)

## Temporary Placeholder

Until you add your custom icon, the app will use the default SF Symbol "app.badge" as shown in the welcome screen.
