//
//  View+Snapshot.swift
//  View+Snapshot
//
//  Created by Axel Rivera on 8/23/21.
//

import SwiftUI

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
        let rect = self.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 2.0)
        let renderer = UIGraphicsImageRenderer(bounds: rect, format: UIGraphicsImageRendererFormat())
        let image = renderer.image { (context) in
            self.drawHierarchy(in: rect, afterScreenUpdates: true)
        }
        UIGraphicsEndImageContext()
        return image
    }
    
}
