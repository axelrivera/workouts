//
//  WorkoutMapCell.swift
//  WorkoutMapCell
//
//  Created by Axel Rivera on 8/13/21.
//

import SwiftUI
import MapKit

struct WorkoutMapCell: View {
    @Environment(\.colorScheme) var colorScheme
    let viewModel: WorkoutCellViewModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 2.0) {
                Text(viewModel.dateString())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(viewModel.title)
                    .font(.title)
                    .padding(.bottom, 5.0)
                HStack {
                    Text(viewModel.distanceString)
                        .font(.fixedBody)
                        .foregroundColor(.distance)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(viewModel.durationString)
                        .font(.fixedBody)
                        .foregroundColor(.time)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(viewModel.speedOrPaceString)
                        .font(.fixedBody)
                        .foregroundColor(viewModel.speedOrPaceColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if viewModel.sport == .cycling && !viewModel.indoor {
                        Text(viewModel.elevationString)
                            .font(.fixedBody)
                            .foregroundColor(.elevation)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.coordinates.isPresent && !viewModel.indoor {
                MapContainer(viewModel: viewModel, scheme: colorScheme)
                    .frame(minHeight: 200.0, maxHeight: 200.0)
                    .background(Color.systemFill)
                    .cornerRadius(12.0)
            }
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
            elevation: 0
        )
    }()
    
    static var previews: some View {
        NavigationView {
            List(1 ..< 5, id: \.self) { _ in
                WorkoutMapCell(viewModel: viewModel)
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
            MKMapView.mapImage(coordinates: viewModel.coordinates, size: size, scheme: scheme) { image in
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
