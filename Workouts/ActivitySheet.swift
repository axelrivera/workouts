//
//  ActivitySheet.swift
//  Workouts
//
//  Created by Axel Rivera on 3/20/22.
//

import Foundation

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

