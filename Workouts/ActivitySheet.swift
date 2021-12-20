//
//  ActivitySheet.swift
//  ActivitySheet
//
//  Created by Axel Rivera on 8/23/21.
//

import SwiftUI

struct ActivitySheet: UIViewControllerRepresentable {
    
    let items: [Any]
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
}

