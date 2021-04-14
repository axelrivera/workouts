//
//  ProView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/24/21.
//

import SwiftUI

struct PaywallView: View {
    @ObservedObject var purchaseManager: IAPManager
    @State private var isProcessing = false
    
    @State private var isPurchasing = false {
        didSet {
            isProcessing = isPurchasing
        }
    }
    
    @State private var isRestoring = false {
        didSet {
            isProcessing = isRestoring
        }
    }
    
    var onSuccess = {}
            
    var body: some View {
        ZStack {
            Color.systemBackground
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 10.0) {
                Spacer()
                
                VStack(alignment: .center, spacing: 10.0) {
                    Text("Better Workouts Pro")
                        .font(.title)
                        .foregroundColor(.orange)
                                        
                    Text("Upgrade to Better Workouts Pro to support further development and gain access to some great extra features:")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(spacing: 15.0) {
                    HStack(alignment: .center, spacing: 15.0) {
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, alignment: .center)
                            .foregroundColor(.green)
                        Text("Manually import FIT files recorded from your cycling computer or smartwatch.")
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack(alignment: .center, spacing: 15.0) {
                        Image(systemName: "chart.bar")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, alignment: .center)
                            .foregroundColor(.green)
                        Text("Get a summary of your cycling and running stats for the current week, month and year.")
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack(alignment: .center, spacing: 15.0) {
                        Image(systemName: "star.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, alignment: .center)
                            .foregroundColor(.green)
                        Text("Additional activities and features coming soon!")
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding([.leading, .trailing], 10.0)
                .padding([.top, .bottom])
                                            
                Spacer()
                
                VStack(spacing: 10.0) {
                    Text(purchaseManager.packageSupportString)
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    
                    Button(action: purchase) {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(DefaultProgressViewStyle())
                            } else {
                                Text(purchaseManager.packageBuyString)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(Constants.cornerRadius)
                    }
                    .disabled(isProcessing)
                    
                    
                    Button(action: restore) {
                        Group {
                            if isRestoring {
                                ProgressView()
                                    .progressViewStyle(DefaultProgressViewStyle())
                            } else {
                                Text("Restore Purchase")
                            }
                        }
                        .padding([.top, .bottom], 10)
                    }.disabled(isProcessing)
                }
                .padding([.leading, .trailing])
                
            }
            .padding()
        }
    }
}

extension PaywallView {
    
    func purchase() {
        withAnimation { isPurchasing = true }
        purchaseManager.purchase { result in
            withAnimation { self.isPurchasing = false }
            switch result {
            case .success:
                Log.debug("purchase is active")
                onSuccess()
            case .failure(let error):
                Log.debug("purchase failed: \(error.localizedDescription)")
            }
        }
    }
    
    func restore() {
        withAnimation { isRestoring = true }
        purchaseManager.restore { result in
            withAnimation { self.isRestoring = false }
            switch result {
            case .success:
                Log.debug("restore purchase is active")
                onSuccess()
            case .failure(let error):
                Log.debug("restore failed: \(error.localizedDescription)")
            }
        }
    }
    
}

struct PaywallView_Previews: PreviewProvider {
    static let purchaseManager: IAPManager = {
        let manager = IAPManager()
        manager.isActive = false
        return manager
    }()
    
    static var previews: some View {
        PaywallView(purchaseManager: purchaseManager)
            .colorScheme(.dark)
    }
}
