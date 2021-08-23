//
//  LoadingModifier.swift
//  LoadingModifier
//
//  Created by Axel Rivera on 8/21/21.
//

import SwiftUI

struct LoadingModifier: ViewModifier {
    var isVisible: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isVisible ? 0.0 : 1.0)
            
            if isVisible {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
    
}

extension View {
    
    func loadingView(isVisible: Bool) -> some View {
        modifier(LoadingModifier(isVisible: isVisible))
    }
    
}
