//
//  ShareView.swift
//  ShareView
//
//  Created by Axel Rivera on 8/23/21.
//

import SwiftUI
import MapKit

struct ShareView: View {
    enum ShareStyle: String, Identifiable, CaseIterable {
        case map, color
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }
    
    enum ActiveSheet: Identifiable {
        case activity, detail, paywall
        var id: Int { hashValue }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State private var currentSheet: ActiveSheet?
    
    @State private var style = ShareStyle.map
    @State private var selectedColor: Color = .accentColor
    
    @State private var showLocation = true
    @State private var showRoute = true
    @State private var removeBranding = false
    
    @State private var sharedImage: UIImage?
    @State private var cachedLocationImage: UIImage?
    
    @State private var cachedLocationString: String?
    
    private let geocoder = CLGeocoder()
    
    private var locationImage: UIImage? {
        showRoute ? cachedLocationImage : nil
    }
    
    private var locationString: String? {
        showLocation ? cachedLocationString : nil
    }
    
    let viewModel: WorkoutCardViewModel
    
    func workoutCard(isScreen: Bool) -> some View {
        WorkoutCard(
            viewModel: viewModel,
            color: selectedColor,
            locationString: locationString,
            locationImage: locationImage,
            showBranding: !removeBranding,
            isScreen: isScreen
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: CGFloat(20.0)) {
                Picker("Style", selection: $style.animation()) {
                    ForEach(ShareStyle.allCases, id: \.self) { item in
                        Text(item.title)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                workoutCard(isScreen: true)
                    .aspectRatio(CGFloat(1.0), contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .fixedSize(horizontal: false, vertical: true)
                    .cornerRadius(CGFloat(5.0))
                    .onAppear {
                        loadLocationStringIfNeeded()
                    }
                
                HStack {
                    Text("Remove Branding")
                    Spacer()
                    
                    if purchaseManager.isActive {
                        Toggle(isOn: $removeBranding.animation()) {
                            EmptyView()
                        }
                        .onChange(of: removeBranding) { _ in
                            reloadImage()
                        }
                    } else {
                        Button(action: { currentSheet = .paywall }) {
                            Image(systemName: "lock.fill")
                        }
                        .buttonStyle(PaywallLockButtonStyle())
                    }
                }
                
                Spacer()
                                
                if style == .color {
                    Button(action: { currentSheet = .detail }) {
                        Label("Details", systemImage: "slider.horizontal.3")
                            .padding([.top, .bottom], CGFloat(10.0))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .onAppear { loadLocationStringIfNeeded() }
            .padding()
            .navigationTitle("Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done", action: {
                        presentationMode.wrappedValue.dismiss()
                    })
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share", action: sheetAction)
                        .disabled(sharedImage == nil)
                }
            }
            .sheet(item: $currentSheet, onDismiss: { dismissAction() }) { sheet in
                switch sheet {
                case .activity:
                    sheetView()
                case .detail:
                    ShareDetailView(color: $selectedColor, showLocation: $showLocation, showRoute: $showRoute)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.reloadImage()
        }
    }
    
    func reloadImage() {
        sharedImage = nil
        let width = 540.0
        sharedImage = workoutCard(isScreen: false)
            .frame(width: width, height: width, alignment: .top)
            .takeScreenshot(origin: .zero, size: CGSize(width: CGFloat(width), height: CGFloat(width)))
    }
    
    func sheetAction() {
        currentSheet = .activity
    }
    
    func sheetView() -> AnyView {
        if let image = sharedImage {
            return AnyView(ActivitySheet(items: [image]))
        } else {
            return AnyView(EmptyView())
        }
    }
    
    func loadLocationStringIfNeeded() {
        guard let coordinate = viewModel.coordinates.first else {
            reloadImage()
            return
        }
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var strings = [String]()
                
                if let city = placemark.locality {
                    strings.append(city)
                }
                
                if let state = placemark.administrativeArea {
                    strings.append(state)
                }
                
                withAnimation {
                    self.cachedLocationString = strings.joined(separator: ", ")
                    self.loadLocationImageIfNeeded()
                }
            } else {
                withAnimation {
                    self.loadLocationImageIfNeeded()
                }
            }
            
        }
    }
    
    func loadLocationImageIfNeeded() {
        MKMapView.routeMapOutline(coordinates: viewModel.coordinates) { image in
            withAnimation {
                self.cachedLocationImage = image
                self.reloadImage()
            }
        }
    }
    
}

struct ShareView_Previews: PreviewProvider {
    static let purchaseManager = IAPManagerPreview.manager(isActive: false)
    
    static var previews: some View {
        ShareView(viewModel: WorkoutCardViewModel.preview())
            .environmentObject(purchaseManager)
            .preferredColorScheme(.dark)
    }
}
