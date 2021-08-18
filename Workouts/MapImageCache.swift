//
//  MapImageCache.swift
//  MapImageCache
//
//  Created by Axel Rivera on 8/16/21.
//

import Foundation
import SwiftUI

class MapImageCache {
    enum Prefix: String {
        case home, feed
    }
    
    var cache = NSCache<NSString, UIImage>()
    
    func get(forKey: String, prefix: Prefix, scheme: ColorScheme) -> UIImage? {
        cache.object(forKey: NSString(string: keyFor(id: forKey, imagePrefix: prefix, scheme: scheme)))
    }
    
    func set(forKey: String, image: UIImage, prefix: Prefix, scheme: ColorScheme) {
        cache.setObject(image, forKey: NSString(string: keyFor(id: forKey, imagePrefix: prefix, scheme: scheme)))
    }
    
    private func keyFor(id: String, imagePrefix: Prefix, scheme: ColorScheme) -> String {
        String(format: "%@_%@_%@", id, imagePrefix.rawValue, stringForColorScheme(scheme))
    }
    
    private func stringForColorScheme(_ scheme: ColorScheme) -> String {
        switch scheme {
        case .light:
            return "light"
        case .dark:
            return "dark"
        @unknown default:
            return "light"
        }
    }
}

extension MapImageCache {
    private static var imageCache = MapImageCache()
    
    static func getImageCache() -> MapImageCache {
        imageCache
    }
    
}
