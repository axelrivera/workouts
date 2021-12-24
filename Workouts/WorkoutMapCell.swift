//
//  WorkoutMapCell.swift
//  WorkoutMapCell
//
//  Created by Axel Rivera on 8/13/21.
//

import SwiftUI
import MapKit
import Combine


final class WorkoutMapCellManager: ObservableObject {
    private(set) var viewModel: WorkoutViewModel
    
    init(viewModel: WorkoutViewModel) {
        self.viewModel = viewModel
        isFavorite = viewModel.isFavorite
        tags = viewModel.tags
        isPendingLocation = viewModel.isPendingLocation
        coordinates = viewModel.coordinates
    }
    
    @Published var isFavorite = false
    @Published var tags = [TagLabelViewModel]()
    @Published var coordinates = [CLLocationCoordinate2D]()
    @Published var isPendingLocation = false
    
    func updateViewModel(_ viewModel: WorkoutViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.viewModel = viewModel
            
            withAnimation {
                self.isFavorite = viewModel.isFavorite
                self.tags = viewModel.tags
                self.isPendingLocation = viewModel.isPendingLocation
                self.coordinates = viewModel.coordinates
            }
        }
    }
    
}

struct WorkoutMapCell: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject var manager: WorkoutMapCellManager
    
    var id: UUID {
        manager.viewModel.id
    }
        
    init(viewModel: WorkoutViewModel, isPreview: Bool = false) {
        _manager = StateObject(wrappedValue: WorkoutMapCellManager(viewModel: viewModel))
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 2.0) {
                HStack {
                    Text(manager.viewModel.dateString())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if manager.isFavorite {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                }
                
                Text(manager.viewModel.title)
                    .font(.title)
                    .padding(.bottom, 5.0)
                
                if manager.tags.isPresent {
                    TagLine(tags: manager.tags)
                }
                
                statsView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if manager.isPendingLocation || manager.coordinates.isPresent {
                MapContainer(
                    id: manager.viewModel.id,
                    scheme: colorScheme,
                    coordinates: $manager.coordinates
                )
                    .cornerRadius(12.0)
            }
        }
        .padding([.leading, .trailing])
        .padding([.top, .bottom], CGFloat(10.0))
        .onReceive(NotificationCenter.default.publisher(for: WorkoutStorage.viewModelUpdatedNotification, object: nil)) { notification in
            processNotification(notification)
        }
    }
    
    @ViewBuilder
    func statsView() -> some View {
        HStack {
            if manager.viewModel.distance > 0 {
                Text(manager.viewModel.distanceString)
                    .font(.fixedBody)
                    .foregroundColor(.distance)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text(manager.viewModel.durationString)
                .font(.fixedBody)
                .foregroundColor(.time)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if manager.viewModel.sport.supportsSplits {
                Text(manager.viewModel.speedOrPaceString)
                    .font(.fixedBody)
                    .foregroundColor(manager.viewModel.speedOrPaceColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if manager.viewModel.sport == .cycling && !manager.viewModel.indoor {
                Text(manager.viewModel.elevationString)
                    .font(.fixedBody)
                    .foregroundColor(.elevation)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    func processNotification(_ notification: Notification) {
        guard let viewModel = notification.userInfo?[WorkoutStorage.viewModelKey] as? WorkoutViewModel else { return }
        guard viewModel.id == manager.viewModel.id else { return }
        Log.debug("update view model: \(viewModel.id), date: \(viewModel.dateString()), coordinates: \(viewModel.coordinates.isPresent), pending location: \(viewModel.isPendingLocation)")
        manager.updateViewModel(viewModel)
    }
}

struct WorkoutMapCell_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    static let workout = StorageProvider.sampleWorkout(sport: .cycling, date: Date(), moc: viewContext)
    static let viewModel: WorkoutViewModel = WorkoutViewModel(workout: workout)
    
    static var previews: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0.0) {
                    ForEach(1...5, id: \.self) { _ in
                        WorkoutMapCell(viewModel: viewModel)
                        Divider()
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct MapContainer: View {
    @EnvironmentObject var manager: WorkoutManager
    var id: UUID
    let scheme: ColorScheme
    @Binding var coordinates: [CLLocationCoordinate2D]
    @State private var cachedImage: UIImage?
    
    @State var isFetchingImage = false
    @State var height = CGFloat(200)
    
    var body: some View {
        Group {
            GeometryReader { proxy in
                VStack {
                    if let image = cachedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Color.systemFill
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                            .onAppear { fetchCachedImage() }
                            .onChange(of: coordinates) { newCoordinates in
                                if newCoordinates.isPresent {
                                    Log.debug("coordinates changed - fetching cached image")
                                    cachedImage = nil
                                    fetchCachedImage()
                                }
                            }
                    }
                }
                .onAppear { updateHeight(for: proxy) }
            }
        }
        .frame(height: height)
    }
    
    func updateHeight(for proxy: GeometryProxy) {
        DispatchQueue.main.async {
            height = (proxy.size.width * Constants.cachedWorkoutImageScaleFactor).rounded()
        }
    }
        
    private func fetchCachedImage() {
        if isFetchingImage { return }
        
        if let image = manager.storage.getCachedImage(forID: id, scheme: scheme) {
            cachedImage = image
            isFetchingImage = false
        } else if let image = manager.storage.getDiskImage(forID: id, scheme: scheme) {
            manager.storage.set(image: image, forID: id, scheme: scheme, memoryOnly: true)
            cachedImage = image
            isFetchingImage = false
        } else {
            MKMapView.mapImage(coordinates: coordinates, size: Constants.cachedWorkoutImageSize) { image in
                if let newImage = image {
                    manager.storage.set(image: newImage, forID: id, scheme: scheme)
                    isFetchingImage = false
                    withAnimation {
                        self.cachedImage = newImage
                    }
                }
            }
        }
    }
    
    
}
