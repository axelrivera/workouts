//
//  URL+Maps.swift
//  URL+Maps
//
//  Created by Axel Rivera on 9/2/21.
//

import Foundation
import SwiftUI

enum MapImageError: Error {
    case invalidImage
}

fileprivate let MapImageCacheDirectoryName = "BWMapImages"
fileprivate let MapImageExtension = "data"

fileprivate func stringForColorScheme(_ scheme: ColorScheme) -> String {
    switch scheme {
    case .light:
        return "light"
    case .dark:
        return "dark"
    @unknown default:
        return "light"
    }
}

extension URL {
    
    private static func mapFileName(id: UUID, scheme: ColorScheme) -> String {
        String(format: "%@_%@.%@", id.uuidString, stringForColorScheme(scheme), MapImageExtension)
    }
    
    static func oldMapImagesCacheDirectory() -> URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cacheDirectory.appendingPathComponent(MapImageCacheDirectoryName, isDirectory: true)
    }
    
    static func mapImagesCacheDirectory() -> URL {
        let cacheDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return cacheDirectory.appendingPathComponent(MapImageCacheDirectoryName, isDirectory: true)
    }
    
    static func createImagesCacheDirectoryIfNeeded() throws {
        try FileManager.createImagesCacheDirectoryIfNeeded()
    }
    
    static func cachedMapImageURL(id: UUID, scheme: ColorScheme) -> URL {
        let url = mapImagesCacheDirectory()
        return url.appendingPathComponent(mapFileName(id: id, scheme: scheme))
    }
    
}

extension FileManager {
    
    static func createImagesCacheDirectoryIfNeeded() throws {
        let url = URL.mapImagesCacheDirectory()
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    static let OLD_CACHE_DIRECTORY_KEY = "arn_delete_old_image_cache_directory"
    
    static func deleteOldImageCacheDirectoryIfNeeded() {
        let isDeleted = UserDefaults.standard.bool(forKey: OLD_CACHE_DIRECTORY_KEY)
        guard isDeleted else { return }
        
        deleteOldImageCacheDirectory()
        UserDefaults.standard.set(true, forKey: OLD_CACHE_DIRECTORY_KEY)
    }
    
    static func deleteOldImageCacheDirectory() {
        let url = URL.oldMapImagesCacheDirectory()
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        do {
            try FileManager.default.moveItem(at: url, to: tmpURL)
        } catch {
            Log.debug("failed to delete old image cache directory: \(error.localizedDescription)")
        }
    }
    
    static func deleteImageCacheDirectory() {
        let url = URL.mapImagesCacheDirectory()
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        do {
            try FileManager.default.moveItem(at: url, to: tmpURL)
        } catch {
            Log.debug("failed to delete image cache directory: \(error.localizedDescription)")
        }
    }
    
    static func writeWorkoutImageData(dark: Data, light: Data, workout: UUID) throws {
        let darkURL = URL.cachedMapImageURL(id: workout, scheme: .dark)
        let lightURL = URL.cachedMapImageURL(id: workout, scheme: .light)
        
        try FileManager.createImagesCacheDirectoryIfNeeded()
        try dark.write(to: darkURL, options: .atomic)
        try light.write(to: lightURL, options: .atomic)
    }
    
    static func deleteWorkoutImageData(for workout: UUID) throws {
        let darkURL = URL.cachedMapImageURL(id: workout, scheme: .dark)
        let lightURL = URL.cachedMapImageURL(id: workout, scheme: .light)
        
        try FileManager.default.removeItem(at: darkURL)
        try FileManager.default.removeItem(at: lightURL)
    }
    
    static func writeLocalImage(_ image: UIImage, at url: URL) throws {
        guard let data = image.jpegData(compressionQuality: 0.9) else { throw MapImageError.invalidImage }
        try data.write(to: url, options: .atomic)
    }
    
    static func deleteLocalImage(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    static func localImage(at url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data, scale: UIScreen.main.scale)
    }
    
    static func writeCacheMapImage(id: UUID, scheme: ColorScheme, image: UIImage) throws {
        try createImagesCacheDirectoryIfNeeded()
        
        let url = URL.cachedMapImageURL(id: id, scheme: scheme)
        try writeLocalImage(image, at: url)
    }
    
    static func cachedMapImage(id: UUID, scheme: ColorScheme) -> UIImage? {
        let url = URL.cachedMapImageURL(id: id, scheme: scheme)
        return localImage(at: url)
    }
    
}
