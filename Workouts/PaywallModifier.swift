//
//  PaywallModifier.swift
//  Workouts
//
//  Created by Axel Rivera on 7/9/21.
//

import SwiftUI

struct PaywallModifier: ViewModifier {
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State var isPaywallShowing: Bool = false
    
    func body(content: Content) -> some View {
        ZStack(alignment: .topLeading) {
            content
                .disabled(!purchaseManager.isActive)
                
            if !purchaseManager.isActive {
                VStack {
                    PaywallOverlay()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    PaywallButton(action: { isPaywallShowing = true })
                        .padding([.bottom, .leading, .trailing])
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
    func paywallOverlay() -> some View {
        modifier(PaywallModifier())
    }
}
