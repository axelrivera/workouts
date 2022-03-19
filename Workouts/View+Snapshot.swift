//
//  View+Snapshot.swift
//  View+Snapshot
//
//  Created by Axel Rivera on 8/23/21.
//

import SwiftUI

extension CGSize {
    
    var scaledSize: CGSize {
        let scale = UIScreen.main.scale
        let newWidth = trunc(width / scale)
        let newHeight = trunc(height / scale)
        return CGSize(width: newWidth, height: newHeight)
    }
    
}

extension View {
    
    func takeScreenshot(origin: CGPoint, size: CGSize) -> UIImage {
        // Wrap the SwiftUI view into a UIKit view hierarchy.
        let hosting = UIHostingController(rootView: self.ignoresSafeArea())
        hosting.view.frame = CGRect(origin: origin, size: size)
        return hosting.view.renderedImage
    }
}

extension UIView {
    
    var renderedImage: UIImage {
        let newSize = self.bounds.size.scaledSize
        let newRect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        let renderer = UIGraphicsImageRenderer(bounds: newRect, format: UIGraphicsImageRendererFormat())
        let image = renderer.image { (context) in
            self.drawHierarchy(in: newRect, afterScreenUpdates: true)
        }
        UIGraphicsEndImageContext()
        return image
    }
    
}
