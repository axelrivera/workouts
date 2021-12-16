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
        showLocation = Self.showLocation(viewModel: viewModel)
        isFavorite = viewModel.isFavorite
        tags = viewModel.tags
        isPendingLocation = viewModel.isPendingLocation
        coordinates = viewModel.coordinates
    }
    
    @Published var isFavorite = false
    @Published var tags = [TagLabelViewModel]()
    @Published var coordinates = [CLLocationCoordinate2D]()
    @Published var isPendingLocation = false
    @Published var showLocation = true
    
    func updateViewModel(_ viewModel: WorkoutViewModel) {
        self.viewModel = viewModel
        withAnimation {
            showLocation = Self.showLocation(viewModel: viewModel)
            isFavorite = viewModel.isFavorite
            tags = viewModel.tags
            isPendingLocation = viewModel.isPendingLocation
            coordinates = viewModel.coordinates
        }
    }
    
    static func showLocation(viewModel: WorkoutViewModel) -> Bool {
        if viewModel.indoor {
            return false
        } else if viewModel.isPendingLocation {
            return true
        } else {
            return viewModel.coordinates.isPresent
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
    
    init(viewModel: WorkoutViewModel) {
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
                    TagGrid(tags: manager.tags)
                }
                
                statsView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if manager.showLocation {
                MapContainer(id: manager.viewModel.id, scheme: colorScheme, coordinates: manager.coordinates)
                    .frame(minHeight: 200.0, maxHeight: 200.0)
                    .background(Color.systemFill)
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
            Text(manager.viewModel.distanceString)
                .font(.fixedBody)
                .foregroundColor(.distance)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(manager.viewModel.durationString)
                .font(.fixedBody)
                .foregroundColor(.time)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(manager.viewModel.speedOrPaceString)
                .font(.fixedBody)
                .foregroundColor(manager.viewModel.speedOrPaceColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
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
        Log.debug("update view model: \(viewModel.id), date: \(viewModel.dateString())")
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
    var coordinates: [CLLocationCoordinate2D]
        
    @State var cachedImage: UIImage?
    
    var body: some View {
        GeometryReader { proxy in
            if let image = cachedImage {
                Image(uiImage: image)
            } else {
                Color.systemFill
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
                    .onAppear { fetchCachedImage(for: proxy.size) }
                    .onReceive(NotificationCenter.default.publisher(for: WorkoutStorage.viewModelUpdatedNotification, object: nil)) { notification in
                        fetchCachedImage(for: proxy.size)
                    }
            }
        }
    }
        
    private func fetchCachedImage(for size: CGSize) {
        if let image = manager.storage.getCachedImage(forID: id, scheme: scheme) {
            cachedImage = image
        } else if let image = manager.storage.getDiskImage(forID: id, scheme: scheme) {
            manager.storage.set(image: image, forID: id, scheme: scheme, memoryOnly: true)
            cachedImage = image
        } else {
            MKMapView.mapImage(coordinates: coordinates, size: size) { image in
                if let newImage = image {
                    manager.storage.set(image: newImage, forID: id, scheme: scheme)
                    withAnimation {
                        self.cachedImage = newImage
                    }
                }
            }
        }
    }
    
    
}
