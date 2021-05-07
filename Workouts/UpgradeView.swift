//
//  UpgradeView.swift
//  Workouts
//
//  Created by Axel Rivera on 4/2/21.
//

import SwiftUI

struct UpgradeView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var purchaseManager: IAPManager
        
    var body: some View {
        ZStack {
            Color.systemBackground
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 0.0) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.top, .leading])
                
                PaywallView(purchaseManager: purchaseManager) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct UpgradeView_Previews: PreviewProvider {
    static let purchaseManager: IAPManager = {
       let manager = IAPManager()
        manager.isActive = false
        return manager
    }()
    
    static var previews: some View {
        UpgradeView()
            .colorScheme(.dark)
            .environmentObject(purchaseManager)
    }
}
