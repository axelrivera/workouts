//
//  HomeMapCell.swift
//  HomeMapCell
//
//  Created by Axel Rivera on 8/16/21.
//

import SwiftUI
import MapKit

struct HomeMapCell: View {
    @Environment(\.colorScheme) var colorScheme
    let workout: WorkoutData
    
    private let mapWidth: CGFloat = 80
    
    var body: some View {
        HStack {
            if workout.indoor {
                Image(systemName: "flame")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .frame(width: mapWidth, height: mapWidth, alignment: .center)
                    .background(Color.systemFill)
                    .cornerRadius(5.0)
                
            } else {
                MapImage(
                    workoutIdentifier: workout.id,
                    coordinates: workout.coordinates,
                    imageSize: CGSize(width: mapWidth, height: mapWidth),
                    cachePrefix: .home,
                    scheme: colorScheme
                )
                    .frame(width: mapWidth, height: mapWidth)
                    .cornerRadius(5.0)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(workout.dateString(shortDay: true))
                    .font(.fixedSubheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2.0)
                
                Text(workout.title)
                    .font(.fixedTitle2)
                    .padding(.bottom, 3.0)
                
                HStack {
                    Text(workout.distanceString)
                        .font(.fixedTitle3)
                        .foregroundColor(.distance)
                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                    Text(workout.durationString)
                        .font(.fixedTitle3)
                        .foregroundColor(.time)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct HomeMapCell_Previews: PreviewProvider {
    static let workoutData: WorkoutData = {
        WorkoutData(
            id: UUID(),
            sport: .cycling,
            indoor: true,
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
                NavigationLink(destination: Text("Workout")) {
                    HomeMapCell(workout: workoutData)
                        .padding([.top, .bottom], 5.0)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
