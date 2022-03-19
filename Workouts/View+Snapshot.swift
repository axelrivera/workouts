//
//  View+Snapshot.swift
//  View+Snapshot
//
//  Created by Axel Rivera on 8/23/21.
//

import SwiftUI

extension View {
    
    func takeScreenshot(origin: CGPoint, size: CGSize, scale: CGFloat? = nil) -> UIImage {
        // Wrap the SwiftUI view into a UIKit view hierarchy.
        let hosting = UIHostingController(rootView: self.ignoresSafeArea())
        hosting.view.frame = CGRect(origin: origin, size: size)
        return hosting.view.renderedImage(scale: scale)
    }
}

extension UIView {
    
    func renderedImage(scale: CGFloat? = nil) ->  UIImage {
        let imageScale = scale ?? 2.0
        let rect = self.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, false, imageScale)
        let renderer = UIGraphicsImageRenderer(bounds: rect, format: UIGraphicsImageRendererFormat())
        let image = renderer.image { (context) in
            self.drawHierarchy(in: rect, afterScreenUpdates: true)
        }
        UIGraphicsEndImageContext()
        return image
    }
    
}
