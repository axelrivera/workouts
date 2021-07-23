//
//  ProView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/24/21.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var purchaseManager: IAPManager
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
        
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Not Now", action: { presentationMode.wrappedValue.dismiss() })
                        .padding()
                }
                
                VStack(spacing: 15.0) {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50.0, height: 50.0)
                    
                    VStack {
                        Text("Better Workouts Pro")
                            .font(.title)
                        
                        Text(purchaseManager.packageSupportString)
                            .foregroundColor(.yellow)
                    }
                    
                    Button(action: purchase) {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text(purchaseManager.packageBuyString)
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow.opacity(isPurchasing ? 0.5 : 1.0))
                        .cornerRadius(Constants.cornerRadius)
                        .shadow(radius: 1)
                    }
                    .disabled(isProcessing)
                    
                    Button(action: restore) {
                        Text("Restore Purchases")
                            .underline()
                    }
                    .disabled(isProcessing)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .cornerRadius(12.0)
                .padding()
                
                Divider()
                
                ScrollView {
                    Text("Upgrade Better Workouts to unlock all these PRO features.")
                        .padding(.all, 15.0)
                    
                    ForEach(PaywallItem.items()) { item in
                        HStack(alignment: .top, spacing: 15.0) {
                            Image(systemName: item.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28, alignment: .center)
                                .foregroundColor(item.imageColor)
                                .padding(.top, 5.0)
                            
                            VStack(alignment: .leading, spacing: 5.0) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text(item.description)
                            }
                        }
                        .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                        
                        Divider()
                    }
                }
            }
            .navigationBarHidden(true)
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
                presentationMode.wrappedValue.dismiss()
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
                presentationMode.wrappedValue.dismiss()
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
        PaywallView()
            .environmentObject(purchaseManager)
            .colorScheme(.dark)
    }
}

struct PaywallItem: Identifiable {
    let id = UUID().uuidString
    let imageName: String
    let imageColor: Color
    let title: String
    let description: String
}

extension PaywallItem {
    
    static func items() -> [PaywallItem] {
        [heartRate, progress, files, more]
    }
    
    static var heartRate: PaywallItem {
        PaywallItem(
            imageName: "heart.fill",
            imageColor: .red,
            title: "Heart Rate Zones",
            description: "Train smarter not harder! Use heart rate zones to monitor your effort on individual workouts."
        )
    }
    
    static var progress: PaywallItem {
        PaywallItem(
            imageName: "chart.bar.fill",
            imageColor: .green,
            title: "Progress Charts",
            description: "Keep track of your progress using weekly and monthly charts."
        )
    }
    
    static var files: PaywallItem {
        PaywallItem(
            imageName: "square.and.arrow.down",
            imageColor: .purple,
            title: "File Imports",
            description: "Manually import FIT files recorded from your cycling computer or smartwatch."
        )
    }
    
    static var more: PaywallItem {
        PaywallItem(
            imageName: "star.fill",
            imageColor: .orange,
            title: "Support Indie Work",
            description: "Purchasing supports current and future development of Better Workouts."
        )
    }
    
}
