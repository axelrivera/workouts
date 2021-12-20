//
//  ShareView.swift
//  ShareView
//
//  Created by Axel Rivera on 8/23/21.
//

import SwiftUI
import MapKit

struct ShareView: View {
    typealias ShareStyle = ShareManager.ShareStyle
    
    enum ActiveSheet: Identifiable {
        case activity, detail, paywall
        var id: Int { hashValue }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var purchaseManager: IAPManager
    
    @StateObject var shareManager = ShareManager()
    @State private var currentSheet: ActiveSheet?
    
    let viewModel: WorkoutCardViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: CGFloat(20.0)) {
                if viewModel.includesLocation {
                    Picker("Style", selection: $shareManager.style.animation()) {
                        ForEach(ShareStyle.allCases, id: \.self) { item in
                            Text(item.title)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if let image = shareManager.sharedImage {
                    Image(uiImage: image)
                        .resizable()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(contentMode: .fit)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.move(edge: .leading))
                } else {
                    Color.systemFill
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(contentMode: .fit)
                        .fixedSize(horizontal: false, vertical: true)
                        .overlay {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                }
                
                HStack {
                    Text("Remove Branding")
                    Spacer()
                    
                    if purchaseManager.isActive {
                        Toggle(isOn: $shareManager.removeBranding.animation()) {
                            EmptyView()
                        }
                    } else {
                        Button(action: { currentSheet = .paywall }) {
                            Image(systemName: "lock.fill")
                        }
                        .buttonStyle(PaywallLockButtonStyle())
                    }
                }
                
                Spacer()
                                
                Button(action: { currentSheet = .detail }) {
                    Label("Details", systemImage: "slider.horizontal.3")
                        .padding([.top, .bottom], CGFloat(10.0))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .task {
                await shareManager.loadValues(viewModel: viewModel, colorScheme: colorScheme)
            }
            .navigationTitle("Sharing Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { presentationMode.wrappedValue.dismiss() })
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Share", action: sheetAction)
                }
            }
            .sheet(item: $currentSheet, onDismiss: { dismissAction() }) { sheet in
                switch sheet {
                case .activity:
                    sheetView()
                case .detail:
                    ShareDetailView()
                        .environmentObject(shareManager)
                case .paywall:
                    PaywallView()
                        .environmentObject(purchaseManager)
                }
            }
        }
    }
}

extension ShareView {
    
    func dismissAction() {
        shareManager.reloadImage()
    }
    
    func sheetAction() {
        currentSheet = .activity
    }
    
    func sheetView() -> AnyView {
        if let image = shareManager.sharedImage {
            return AnyView(ActivitySheet(items: [image]))
        } else {
            return AnyView(Text("Image Missing"))
        }
    }
    
}

struct ShareView_Previews: PreviewProvider {
    static let purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    static var previews: some View {
        ShareView(viewModel: WorkoutCardViewModel.preview())
            .environmentObject(purchaseManager)
            .preferredColorScheme(.dark)
    }
}
