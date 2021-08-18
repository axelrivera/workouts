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
    let workout: WorkoutData
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 2.0) {
                Text(workout.dateString())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(workout.title)
                    .font(.title)
                    .padding(.bottom, 5.0)
                HStack {
                    Text(workout.distanceString)
                        .font(.fixedBody)
                        .foregroundColor(.distance)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(workout.durationString)
                        .font(.fixedBody)
                        .foregroundColor(.time)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(workout.speedOrPaceString)
                        .font(.fixedBody)
                        .foregroundColor(workout.speedOrPaceColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if workout.sport == .cycling && !workout.indoor {
                        Text(workout.elevationString)
                            .font(.fixedBody)
                            .foregroundColor(.elevation)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if !workout.indoor {
                MapContainer(workout: workout, scheme: colorScheme)
                    .frame(minHeight: 200.0, maxHeight: 200.0)
                    .cornerRadius(12.0)
            }
        }
    }
}

struct WorkoutMapCell_Previews: PreviewProvider {
    static let workoutData: WorkoutData = {
        WorkoutData(
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
            elevation: 0
        )
    }()
    
    static var previews: some View {
        NavigationView {
            List(1 ..< 5, id: \.self) { _ in
                WorkoutMapCell(workout: workoutData)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct MapContainer: View {
    let workout: WorkoutData
    let scheme: ColorScheme
    
    var body: some View {
        GeometryReader { proxy in
            MapImage(
                workoutIdentifier: workout.id,
                coordinates: workout.coordinates,
                imageSize: CGSize(width: proxy.size.width, height: 200),
                cachePrefix: .feed,
                scheme: scheme
            )
        }
    }
}
