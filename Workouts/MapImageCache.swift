//
//  MapImageCache.swift
//  MapImageCache
//
//  Created by Axel Rivera on 8/16/21.
//

import Foundation
import SwiftUI

final class MapImageCache {
    enum Prefix: String {
        case home, feed
    }
    
    private let cache = NSCache<NSString, UIImage>()
    private let lock = NSLock()
    
    init() {
        cache.countLimit = 20
    }
    
    func getMemory(url: URL) -> UIImage? {
        lock.lock(); defer { lock.unlock() }
        return cache.object(forKey: url.path as NSString)
    }
    
    func getDisk(url: URL) -> UIImage? {
        lock.lock(); defer { lock.unlock() }
        return FileManager.localImage(at: url)
    }
    
    func set(image: UIImage, url: URL, memoryOnly: Bool = false) {
        lock.lock(); defer { lock.unlock() }
        
        cache.setObject(image, forKey: url.path as NSString)
        
        if !memoryOnly {
            do {
                try FileManager.createImagesCacheDirectoryIfNeeded()
                try FileManager.writeLocalImage(image, at: url)
            } catch {
                Log.debug("failed to write cached image: \(error.localizedDescription)")
            }
        }
    }
    
    func resetImage(at url: URL) {
        lock.lock(); defer { lock.unlock() }
        cache.removeObject(forKey: url.path as NSString)
        do {
            try FileManager.deleteLocalImage(at: url)
        } catch {
            Log.debug("failed to delete image: \(error.localizedDescription)")
        }
        
    }
    
    func resetAll() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAllObjects()
        FileManager.deleteImageCacheDirectory()
    }
    
}

extension MapImageCache {
    private static var imageCache = MapImageCache()
    
    static func getImageCache() -> MapImageCache {
        imageCache
    }
    
}
