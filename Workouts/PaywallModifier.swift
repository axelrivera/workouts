//
//  PaywallModifier.swift
//  Workouts
//
//  Created by Axel Rivera on 7/9/21.
//

import SwiftUI

struct PaywallButtonModifier: ViewModifier {
    @EnvironmentObject var purchaseManager: IAPManager
    
    let source: AnalyticsManager.PaywallSource
    let buttonType: PaywallLockButton.ButtonType
    let sample: Bool
    @State private var isPaywallShowing: Bool = false
    
    func body(content: Content) -> some View {
        ZStack(alignment: .center) {
            content
                .opacity(purchaseManager.isActive ? 1.0 : 0.75)
                .disabled(!purchaseManager.isActive)
                
            if !purchaseManager.isActive {
                VStack(spacing: 20.0) {
                    PaywallLockButton(sample: sample, type: buttonType, action: { isPaywallShowing = true })
                }
             }
        }
        .sheet(isPresented: $isPaywallShowing) {
            PaywallView(source: source)
                .environmentObject(purchaseManager)
        }
    }
    
}

extension View {
    
    func paywallButtonOverlay(source: AnalyticsManager.PaywallSource, type: PaywallLockButton.ButtonType = .default, sample: Bool = true) -> some View {
        modifier(PaywallButtonModifier(source: source, buttonType: type, sample: sample))
    }
    
}
