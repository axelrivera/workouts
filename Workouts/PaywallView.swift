//
//  ProView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/24/21.
//

import SwiftUI

struct PaywallView: View {
    enum AlertSheet: Identifiable, Hashable {
        case error(message: String)
        var id: Self { self }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
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
    
    @State private var items = PaywallItem.items()
    @State private var activeAlert: AlertSheet?
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 15.0) {
            Image(systemName: "flame.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50.0, height: 50.0)

            VStack {
                Text("Better Workouts Pro")
                    .font(.fixedTitle)

                Text(purchaseManager.packageSupportString)
                    .font(.fixedBody)
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
            }
            .buttonStyle(PaywallButtonStyle())
            .disabled(isProcessing)

            Button(action: restore) {
                Text("Restore Purchases")
                    .font(.fixedBody)
                    .underline()
            }
            .disabled(isProcessing)
        }
        .foregroundColor(.white)
        .padding(.all, CGFloat(25.0))
        .frame(maxWidth: .infinity)
        .background(Color.accentColor)
    }
            
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section(header: headerView()) {
                        Text("Upgrade to unlock all these PRO features.")
                            .font(.fixedHeadline)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.all, CGFloat(15.0))
                        
                        ForEach(items, id: \.self) { item in
                            Divider()
                            HStack(alignment: .top, spacing: CGFloat(15.0)) {
                                Image(systemName: item.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: CGFloat(28.0), height: CGFloat(28.0), alignment: .center)
                                    .foregroundColor(item.imageColor)
                                    .padding(.top, CGFloat(5.0))
                                
                                VStack(alignment: .leading, spacing: CGFloat(5.0)) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(item.description)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.init(top: CGFloat(10.0), leading: CGFloat(20.0), bottom: CGFloat(10.0), trailing: CGFloat(20.0)))
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Not Now", action: { presentationMode.wrappedValue.dismiss() })
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .error(let message):
                    return Alert(
                        title: Text("Purchase Error"),
                        message: Text(message),
                        dismissButton: Alert.Button.cancel(Text("Ok"))
                    )
                }
            }
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
                viewContext.refreshAllObjects()
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                Log.debug("purchase failed: \(error.localizedDescription)")
                activeAlert = .error(message: error.localizedDescription)
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
                activeAlert = .error(message: error.localizedDescription)
            }
        }
    }
    
}

struct PaywallView_Previews: PreviewProvider {
    
    static var previews: some View {
        PaywallView()
            .environmentObject(IAPManagerPreview.manager(isActive: true))
            .colorScheme(.dark)
    }
}
