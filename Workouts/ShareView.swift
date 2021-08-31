//
//  ShareView.swift
//  ShareView
//
//  Created by Axel Rivera on 8/23/21.
//

import SwiftUI
import MapKit

struct ShareView: View {
    enum ActiveSheet: Identifiable {
        case activity, detail, paywall
        var id: Int { hashValue }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State private var currentSheet: ActiveSheet?
    
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
            VStack(spacing: 20.0) {
                workoutCard(isScreen: true)
                    .aspectRatio(CGFloat(1.0), contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .fixedSize(horizontal: false, vertical: true)
                    .cornerRadius(CGFloat(5.0))
                    .onAppear {
                        loadLocationStringIfNeeded()
                    }
                                
                VStack(alignment: .leading, spacing: 15.0) {
                    VStack(alignment: .leading) {
                        Text("Background Color")
                        WorkoutColorPicker(selectedColor: $selectedColor.animation()) { newColor in
                            reloadImage()
                        }
                    }
                    
                    Divider()
                    
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
                }
                .padding()
                
                Spacer()
                
                Button(action: { currentSheet = .detail }) {
                    Label("Details", systemImage: "slider.horizontal.3")
                        .padding([.top, .bottom], CGFloat(10.0))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .onChange(of: showLocation, perform: { _ in
                reloadImage()
            })
            .onChange(of: showRoute, perform: { _ in
                reloadImage()
            })
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
                }
            }
            .sheet(item: $currentSheet, onDismiss: {}) { sheet in
                switch sheet {
                case .activity:
                    sheetView()
                case .detail:
                    ShareDetailView(showLocation: $showLocation, showRoute: $showRoute)
                case .paywall:
                    PaywallView()
                        .environmentObject(purchaseManager)
                }
            }
        }
    }
}

extension ShareView {
    
    func reloadImage() {
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
            loadLocationImageIfNeeded()
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

struct WorkoutColorPicker: View {
    private let data = Color.workoutColors

    private let rows = [
        GridItem(.fixed(50.0))
    ]
    
    @Binding var selectedColor: Color
    var selectedAction: (_ color: Color) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: rows, spacing: 20.0) {
                ForEach(data, id: \.self) { color in
                    Button(action: { selectColor(color) }) {
                        Rectangle()
                            .fill(color)
                            .frame(width: CGFloat(50.0), height: CGFloat(50.0))
                            .border(selectedColor == color ? .yellow : .white, width: 2.0)
                    }
                }
            }
        }
        .frame(maxHeight: CGFloat(50.0))
    }
    
    func selectColor(_ color: Color) {
        selectedColor = color
        selectedAction(color)
    }
}
