//
//  PaywallModifier.swift
//  Workouts
//
//  Created by Axel Rivera on 7/9/21.
//

import SwiftUI

struct PaywallButtonModifier: ViewModifier {
    @EnvironmentObject var purchaseManager: IAPManager
    
    let sample: Bool
    @State private var isPaywallShowing: Bool = false
    
    func body(content: Content) -> some View {
        ZStack(alignment: .center) {
            content
                .opacity(purchaseManager.isActive ? 1.0 : 0.75)
                .disabled(!purchaseManager.isActive)
                
            if !purchaseManager.isActive {
                VStack(spacing: 20.0) {
                    PaywallLockButton(sample: sample, action: { isPaywallShowing = true })
                }
             }
        }
        .sheet(isPresented: $isPaywallShowing) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
    }
    
}

extension View {
    
    func paywallButtonOverlay(sample: Bool = true) -> some View {
        modifier(PaywallButtonModifier(sample: sample))
    }
    
}
