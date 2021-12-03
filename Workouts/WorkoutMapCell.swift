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
    @Published var isFavorite = false
    @Published var tags = [TagLabelViewModel]()
    
    var cancellable: Cancellable?
    
    let workout: UUID
    let isPreview: Bool
    
    init(workout: UUID, isPreview: Bool = false) {
        self.workout = workout
        self.isPreview = isPreview
        isFavorite = WorkoutCache.shared.isFavorite(identifier: workout)
        tags = WorkoutCache.shared.tags(for: workout)
    }
    
    func reload() {
        // ignore in SwiftUI preview
        if isPreview { return }
        
        isFavorite = WorkoutCache.shared.isFavorite(identifier: workout)
        tags = WorkoutCache.shared.tags(for: workout)
    }
    
}

struct WorkoutMapCell: View {
    let viewModel: WorkoutCellViewModel
    
    init(viewModel: WorkoutCellViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        WorkoutMapCellContainer(
            viewModel: viewModel,
            manager: WorkoutMapCellManager(workout: viewModel.id)
        )
    }
}

struct WorkoutMapCellContainer: View {
    @Environment(\.colorScheme) var colorScheme
    
    let viewModel: WorkoutCellViewModel
    @StateObject var manager: WorkoutMapCellManager
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 2.0) {
                HStack {
                    Text(viewModel.dateString())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if manager.isFavorite {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                }
                
                Text(viewModel.title)
                    .font(.title)
                    .padding(.bottom, 5.0)
                
                if manager.tags.isPresent {
                    TagGrid(tags: manager.tags)
                }
                
                WorkoutCellStatsView(viewModel: viewModel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear { manager.reload() }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.workoutCacheUpdated)) { notification in
                processNotification(notification)
            }
            
            if viewModel.includesLocation {
                MapContainer(viewModel: viewModel, scheme: colorScheme)
                    .frame(minHeight: 200.0, maxHeight: 200.0)
                    .background(Color.systemFill)
                    .cornerRadius(12.0)
            }
        }
        .padding([.leading, .trailing])
        .padding([.top, .bottom], CGFloat(10.0))
    }
    
    func processNotification(_ notification: Notification) {
        if let remoteIdentifier = notification.userInfo?[Notification.remoteWorkoutKey] as? UUID, remoteIdentifier == viewModel.id {
            manager.reload()
        }
    }
}

struct WorkoutMapCell_Previews: PreviewProvider {
    static let viewModel: WorkoutCellViewModel = {
        WorkoutCellViewModel(
            id: UUID(),
            sport: .cycling,
            indoor: false,
            coordinates: [],
            title: "Outdoor Cycling",
            date: Date(),
            distance: milesToMeters(for: 10),
            duration: hoursToSeconds(for: 1),
            avgSpeed: 0,
            avgPace: 0,
            calories: 0,
            elevation: 0,
            includesLocation: true
        )
    }()
    
    static let manager: WorkoutMapCellManager = {
        let manager = WorkoutMapCellManager(workout: viewModel.id, isPreview: true)
        manager.isFavorite = true
        manager.tags = [
            TagLabelViewModel(id: UUID(), name: "Sample Tag", color: .red, gearType: .none, archived: false)
        ]
        
        return manager
    }()
    
    static var previews: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0.0) {
                    ForEach(1...5, id: \.self) { _ in
                        WorkoutMapCellContainer(
                            viewModel: viewModel,
                            manager: manager
                        )
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
    let viewModel: WorkoutCellViewModel
    let scheme: ColorScheme
    private let imageCache = MapImageCache.getImageCache()
    
    @State var cachedImage: UIImage?
    
    var body: some View {
        GeometryReader { proxy in
            if let image = cachedImage {
                Image(uiImage: image)
            } else {
                Color.systemFill
                    .onAppear { fetchCachedImage(for: proxy.size) }
            }
        }
    }
        
    private func fetchCachedImage(for size: CGSize) {
        let url = URL.cachedMapImageURL(id: viewModel.id, scheme: scheme)
        if let image = imageCache.getMemory(url: url) {
            cachedImage = image
        } else if let image = imageCache.getDisk(url: url) {
            imageCache.set(image: image, url: url, memoryOnly: true)
            cachedImage = image
        } else {
            MKMapView.mapImage(coordinates: viewModel.coordinates, size: size) { image in
                if let newImage = image {
                    imageCache.set(image: newImage, url: url)
                    
                    withAnimation {
                        self.cachedImage = newImage
                    }
                }
            }
        }
    }
    
    
}
