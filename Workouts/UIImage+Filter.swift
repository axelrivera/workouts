//
//  UIImage+Filter.swift
//  Workouts
//
//  Created by Axel Rivera on 1/20/22.
//

import UIKit

enum PhotoFilterType: String, Hashable, Identifiable,  CaseIterable {
    case original = "original"
    case sephia = "CISepiaTone"
    case chrome = "CIPhotoEffectChrome"
    case fade = "CIPhotoEffectFade"
    case instant = "CIPhotoEffectInstant"
    case mono = "CIPhotoEffectMono"
    case noir = "CIPhotoEffectNoir"
    case process = "CIPhotoEffectProcess"
    case tonal = "CIPhotoEffectTonal"
    case transfer =  "CIPhotoEffectTransfer"
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .original: return "Original"
        case .sephia: return "Sephia"
        case .chrome: return "Chrome"
        case .fade: return "Fade"
        case .instant: return "Instant"
        case .mono: return "Mono"
        case .noir: return "Noir"
        case .process: return "Process"
        case .tonal: return "Tonal"
        case .transfer: return "Transfer"
        }
    }
}

struct PhotoFilterViewModel: Hashable, Identifiable {
    var id: PhotoFilterType { filter }
    
    var filter: PhotoFilterType
    var preview: UIImage
}

extension UIImage {
    
    func addFilter(filter : PhotoFilterType) -> UIImage {
        if filter == .original { return self }
        let filter = CIFilter(name: filter.rawValue)
        
        // convert UIImage to CIImage and set as input
        let ciInput = CIImage(image: self)
        filter?.setValue(ciInput, forKey: kCIInputImageKey)
    
        // get output CIImage, render as CGImage first to retain proper UIImage scale
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
    
        return UIImage(cgImage: cgImage!)
    }
    
}
