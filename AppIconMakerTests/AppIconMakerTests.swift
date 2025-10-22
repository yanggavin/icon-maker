//
//  AppIconMakerTests.swift
//  AppIconMakerTests
//
//  Unit tests for App Icon Maker
//

import XCTest
@testable import AppIconMaker

final class AppIconMakerTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Model Tests
    
    func testIconSizeInitialization() throws {
        let iconSize = IconSize(size: 60, scale: 2, idiom: "iphone")
        
        XCTAssertEqual(iconSize.size, 60)
        XCTAssertEqual(iconSize.scale, 2)
        XCTAssertEqual(iconSize.idiom, "iphone")
        XCTAssertEqual(iconSize.filename, "Icon-60@2x.png")
    }
    
    func testPlatformCases() throws {
        XCTAssertEqual(Platform.iOS.rawValue, "iOS")
        XCTAssertEqual(Platform.iPadOS.rawValue, "iPadOS")
        XCTAssertEqual(Platform.macOS.rawValue, "macOS")
        XCTAssertEqual(Platform.all.rawValue, "All Platforms")
    }
    
    func testBackgroundStyleEquality() throws {
        let transparent1 = BackgroundStyle.transparent
        let transparent2 = BackgroundStyle.transparent
        
        XCTAssertEqual(transparent1, transparent2)
    }
    
    // MARK: - IconSizeSpec Tests
    
    func testIOSIconSizes() throws {
        let iosIcons = IconSizeSpec.iOS
        
        XCTAssertFalse(iosIcons.isEmpty, "iOS should have icon sizes")
        XCTAssertTrue(iosIcons.contains { $0.size == 60 && $0.scale == 2 }, "Should contain 60@2x")
        XCTAssertTrue(iosIcons.contains { $0.size == 1024 && $0.scale == 1 }, "Should contain 1024@1x")
    }
    
    func testIPadOSIconSizes() throws {
        let ipadIcons = IconSizeSpec.iPadOS
        
        XCTAssertFalse(ipadIcons.isEmpty, "iPadOS should have icon sizes")
        XCTAssertTrue(ipadIcons.contains { $0.size == 76 && $0.scale == 2 }, "Should contain 76@2x")
    }
    
    func testMacOSIconSizes() throws {
        let macIcons = IconSizeSpec.macOS
        
        XCTAssertFalse(macIcons.isEmpty, "macOS should have icon sizes")
        XCTAssertTrue(macIcons.contains { $0.size == 512 && $0.scale == 2 }, "Should contain 512@2x")
    }
    
    // MARK: - AppIconSet Tests
    
    func testAppIconSetInitialization() throws {
        let iconSize = IconSize(size: 60, scale: 2, idiom: "iphone")
        let testImage = createTestImage()
        let icons: [IconSize: UIImage] = [iconSize: testImage]
        let platforms: Set<Platform> = [.iOS]
        
        let iconSet = AppIconSet(icons: icons, platforms: platforms)
        
        XCTAssertEqual(iconSet.icons.count, 1)
        XCTAssertEqual(iconSet.platforms, platforms)
    }
    
    func testContentsJSONGeneration() throws {
        let iconSize = IconSize(size: 60, scale: 2, idiom: "iphone")
        let testImage = createTestImage()
        let icons: [IconSize: UIImage] = [iconSize: testImage]
        let platforms: Set<Platform> = [.iOS]
        
        let iconSet = AppIconSet(icons: icons, platforms: platforms)
        let jsonData = iconSet.contentsJSON()
        
        XCTAssertFalse(jsonData.isEmpty, "Contents.json should not be empty")
        
        // Verify it's valid JSON
        let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
        XCTAssertNotNil(json, "Should be valid JSON")
    }
    
    // MARK: - ImageCache Tests
    
    func testImageCacheSetAndGet() throws {
        let cache = ImageCache.shared
        let testImage = createTestImage()
        let key = "test-image"
        
        cache.setImage(testImage, forKey: key)
        let retrievedImage = cache.image(forKey: key)
        
        XCTAssertNotNil(retrievedImage, "Should retrieve cached image")
    }
    
    func testImageCacheRemove() throws {
        let cache = ImageCache.shared
        let testImage = createTestImage()
        let key = "test-image-remove"
        
        cache.setImage(testImage, forKey: key)
        cache.removeImage(forKey: key)
        let retrievedImage = cache.image(forKey: key)
        
        XCTAssertNil(retrievedImage, "Should not retrieve removed image")
    }
    
    func testImageCacheClear() throws {
        let cache = ImageCache.shared
        let testImage = createTestImage()
        
        cache.setImage(testImage, forKey: "key1")
        cache.setImage(testImage, forKey: "key2")
        cache.clearCache()
        
        XCTAssertNil(cache.image(forKey: "key1"), "Cache should be cleared")
        XCTAssertNil(cache.image(forKey: "key2"), "Cache should be cleared")
    }
    
    func testCacheKeyGeneration() throws {
        let testImage = createTestImage()
        
        let bgKey = ImageCache.backgroundRemovalKey(for: testImage)
        let enhanceKey = ImageCache.enhancementKey(for: testImage)
        let cropKey = ImageCache.cropSuggestionsKey(for: testImage)
        let iconKey = ImageCache.iconKey(for: testImage, size: CGSize(width: 60, height: 60), scale: 2)
        
        XCTAssertFalse(bgKey.isEmpty)
        XCTAssertFalse(enhanceKey.isEmpty)
        XCTAssertFalse(cropKey.isEmpty)
        XCTAssertFalse(iconKey.isEmpty)
        
        // Keys should be different
        XCTAssertNotEqual(bgKey, enhanceKey)
        XCTAssertNotEqual(enhanceKey, cropKey)
    }
    
    // MARK: - ImageProcessor Tests
    
    func testImageResize() throws {
        let processor = ImageProcessor()
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        let targetSize = CGSize(width: 100, height: 100)
        
        let resizedImage = processor.resize(testImage, to: targetSize, scale: 1.0)
        
        XCTAssertEqual(resizedImage.size.width, targetSize.width, accuracy: 1.0)
        XCTAssertEqual(resizedImage.size.height, targetSize.height, accuracy: 1.0)
    }
    
    func testImageCrop() throws {
        let processor = ImageProcessor()
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        let cropRect = CGRect(x: 100, y: 100, width: 500, height: 500)
        
        let croppedImage = processor.crop(testImage, to: cropRect)
        
        XCTAssertNotNil(croppedImage)
        // Note: Actual size verification depends on scale
    }
    
    // MARK: - Performance Tests
    
    func testImageResizePerformance() throws {
        let processor = ImageProcessor()
        let testImage = createTestImage(size: CGSize(width: 2000, height: 2000))
        let targetSize = CGSize(width: 60, height: 60)
        
        measure {
            _ = processor.resize(testImage, to: targetSize, scale: 2.0)
        }
    }
    
    func testCachePerformance() throws {
        let cache = ImageCache.shared
        let testImage = createTestImage()
        
        measure {
            for i in 0..<100 {
                cache.setImage(testImage, forKey: "perf-test-\(i)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
