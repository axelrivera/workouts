//
//  PaywallModifier.swift
//  Workouts
//
//  Created by Axel Rivera on 7/9/21.
//

import SwiftUI

struct PaywallModifier: ViewModifier {
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State private var isPaywallShowing = false
    
    func body(content: Content) -> some View {
        VStack {
            ZStack(alignment: .topLeading) {
                content
                    .disabled(!purchaseManager.isActive)
                    
                if !purchaseManager.isActive {
                    PaywallOverlay()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            if !purchaseManager.isActive {
                PaywallButton(action: { isPaywallShowing = true })
                    .buttonStyle(PlainButtonStyle())
                    .padding()
            }
        }
        .sheet(isPresented: $isPaywallShowing) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
    }
    
}

extension View {
    func paywallOverlay() -> some View {
        modifier(PaywallModifier())
    }
}
