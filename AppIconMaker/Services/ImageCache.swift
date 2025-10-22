//
//  ImageCache.swift
//  AppIconMaker
//
//  Memory-efficient image cache with size limits
//

import UIKit

/// Memory-efficient cache for processed images
class ImageCache {
    
    // MARK: - Singleton
    
    static let shared = ImageCache()
    
    // MARK: - Properties
    
    private var cache = NSCache<NSString, UIImage>()
    private let maxMemorySize: Int = 50 * 1024 * 1024 // 50 MB
    private let maxImageCount: Int = 20
    
    // MARK: - Initialization
    
    private init() {
        setupCache()
        registerMemoryWarningObserver()
    }
    
    private func setupCache() {
        cache.totalCostLimit = maxMemorySize
        cache.countLimit = maxImageCount
        cache.name = "com.appiconmaker.imagecache"
    }
    
    // MARK: - Cache Operations
    
    /// Stores an image in the cache with a key
    /// - Parameters:
    ///   - image: The image to cache
    ///   - key: The cache key
    func setImage(_ image: UIImage, forKey key: String) {
        let cost = estimateImageMemorySize(image)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    /// Retrieves an image from the cache
    /// - Parameter key: The cache key
    /// - Returns: The cached image, or nil if not found
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    /// Removes an image from the cache
    /// - Parameter key: The cache key
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    /// Clears all cached images
    func clearCache() {
        cache.removeAllObjects()
    }
    
    // MARK: - Helper Methods
    
    /// Estimates the memory size of an image in bytes
    private func estimateImageMemorySize(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        
        let bytesPerPixel = 4 // RGBA
        let width = cgImage.width
        let height = cgImage.height
        
        return width * height * bytesPerPixel
    }
    
    /// Generates a cache key for background removal
    static func backgroundRemovalKey(for image: UIImage) -> String {
        return "bg_removal_\(image.hashValue)"
    }
    
    /// Generates a cache key for enhancement
    static func enhancementKey(for image: UIImage) -> String {
        return "enhancement_\(image.hashValue)"
    }
    
    /// Generates a cache key for crop suggestions
    static func cropSuggestionsKey(for image: UIImage) -> String {
        return "crop_suggestions_\(image.hashValue)"
    }
    
    /// Generates a cache key for resized icons
    static func iconKey(for image: UIImage, size: CGSize, scale: CGFloat) -> String {
        return "icon_\(image.hashValue)_\(Int(size.width))x\(Int(size.height))@\(Int(scale))x"
    }
    
    // MARK: - Memory Warning Handling
    
    private func registerMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        clearCache()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Cache Key Storage for Crop Suggestions

extension ImageCache {
    
    /// Stores crop suggestions in memory (not as images)
    private static var cropSuggestionsCache: [String: [CGRect]] = [:]
    
    /// Stores crop suggestions for an image
    func setCropSuggestions(_ suggestions: [CGRect], forKey key: String) {
        ImageCache.cropSuggestionsCache[key] = suggestions
    }
    
    /// Retrieves crop suggestions for an image
    func cropSuggestions(forKey key: String) -> [CGRect]? {
        return ImageCache.cropSuggestionsCache[key]
    }
    
    /// Clears crop suggestions cache
    func clearCropSuggestions() {
        ImageCache.cropSuggestionsCache.removeAll()
    }
}
