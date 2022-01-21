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
        case activity, detail, library
        var id: Int { hashValue }
    }
    
    enum ActiveFullSheet: Identifiable {
        case camera
        var id: Int { hashValue }
    }
    
    private static let PREVIEW_WIDTH: CGFloat = 75.0
    
    @Environment(\.presentationMode) var presentationMode
        
    @StateObject var shareManager = ShareManager()
    @State private var currentSheet: ActiveSheet?
    @State private var currentFullSheet: ActiveFullSheet?
    
    let viewModel: WorkoutCardViewModel
    private let rows: [GridItem] = [.init(.fixed(Self.PREVIEW_WIDTH))]
    
    @State private var showingPhotoSelection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20.0) {
                if viewModel.includesLocation {
                    Picker("Style", selection: $shareManager.style) {
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
                        .border(Color.divider, width: 1.0)
                        .transition(.move(edge: .leading))
                        .overlay {
                            if shareManager.style == .photo && shareManager.backgroundOriginalImage == nil {
                                VStack(spacing: 10.0) {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                    Text("No Photo")
                                }
                                .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .overlay {
                            if shareManager.isGeneratingImage {
                                HUDView()
                            }
                        }
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
                
                switch shareManager.style {
                case .map:
                    mapButtons()
                case .photo:
                    filterButtons()
                }
                
                Spacer()
                
                HStack {
                    if shareManager.style == .photo {
                        Button(action: { showingPhotoSelection = true }) {
                            Label("Add Photo", systemImage: "photo")
                                .padding([.top, .bottom], CGFloat(10.0))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .confirmationDialog(
                            "Add Background Photo",
                            isPresented: $showingPhotoSelection,
                            titleVisibility: .visible) {
                                Button("Open Camera", action: { currentFullSheet = .camera })
                                Button("Choose Photo", action: { currentSheet = .library })
                                Button("Cancel", role: .cancel, action: {})
                        }
                    }
                    
                    Button(action: { currentSheet = .detail }) {
                        Label("Details", systemImage: "slider.horizontal.3")
                            .padding([.top, .bottom], CGFloat(10.0))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .task {
                await shareManager.loadValues(viewModel: viewModel)
            }
            .navigationTitle("Sharing Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: { presentationMode.wrappedValue.dismiss() })
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
                case .library:
                    ImagePicker(sourceType: .photoLibrary, selectedImage: $shareManager.backgroundOriginalImage)
                }
            }
            .fullScreenCover(item: $currentFullSheet, onDismiss: { dismissAction() }) { item in
                switch item {
                case .camera:
                    ImagePicker(sourceType: .camera, selectedImage: $shareManager.backgroundOriginalImage)
                }
            }
        }
    }
    
    @ViewBuilder
    func mapButtons() -> some View {
        if let region = MKCoordinateRegion(coordinates: viewModel.coordinates) {
            VStack(alignment: .leading) {
                Text("Select Map Color")
                
                HStack(spacing: 20.0) {
                    Button(action: { shareManager.selectMapColor(.dark)} ) {
                        Map(coordinateRegion: .constant(region), interactionModes: [])
                            .accessibilityHint("Dark")
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12.0)
                                    .stroke(shareManager.mapColor == .dark ? Color.yellow : Color.secondary, lineWidth: 4.0)
                            )
                            .colorScheme(.dark)
                    }
                
                    Button(action: { shareManager.selectMapColor(.light) }) {
                        Map(coordinateRegion: .constant(region), interactionModes: [])
                            .accessibilityHint("Light")
                            .disabled(true)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12.0)
                                    .stroke(shareManager.mapColor == .light ? Color.yellow : Color.secondary, lineWidth: 4.0)
                            )
                            .colorScheme(.light)
                    }
                }
                .frame(height: 100.0)
            }
        }
    }
    
    @ViewBuilder
    func filterButtons() -> some View {
        if shareManager.filterPreviews.isPresent {
            VStack(alignment: .leading) {
                Text("Select Filter")
                
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: rows, alignment: .center, spacing: 10.0) {
                            ForEach((shareManager.filterPreviews), id: \.self) { viewModel in
                                VStack {
                                    Text(viewModel.filter.name)
                                        .font(.fixedCaption1)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: { shareManager.selectFilter(viewModel.filter) }) {
                                        Image(uiImage: viewModel.preview)
                                            .resizable()
                                            .frame(width: Self.PREVIEW_WIDTH, height: Self.PREVIEW_WIDTH, alignment: .center)
                                            .border(shareManager.isFilterSelected(viewModel.filter) ? Color.yellow : Color.white, width: 2.0)
                                    }
                                }
                                .id(viewModel.filter.id)
                            }
                        }
                    }
                    .frame(height: 100.0, alignment: .center)
                    .onAppear {
                        proxy.scrollTo(withAnimation { shareManager.filter.id }, anchor: nil)
                    }
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
    static var previews: some View {
        ShareView(viewModel: WorkoutCardViewModel.preview())
            .preferredColorScheme(.light)
    }
}
