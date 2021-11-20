//
//  HomeWorkoutCell.swift
//  Workouts
//
//  Created by Axel Rivera on 8/16/21.
//

import SwiftUI
import MapKit

struct HomeWorkoutCell: View {
    @Environment(\.colorScheme) var colorScheme
    let viewModel: WorkoutCellViewModel
    
    private let mapWidth: CGFloat = 80
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(viewModel.dateString(shortDay: true))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 2.0)
            
            Text(viewModel.title)
                .font(.title3)
                .padding(.bottom, 5.0)
            HStack {
                Text(viewModel.distanceString)
                    .font(.fixedTitle2)
                    .foregroundColor(.distance)
                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                Text(viewModel.durationString)
                    .font(.fixedTitle2)
                    .foregroundColor(.time)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(viewModel.speedOrPaceString)
                    .font(.fixedTitle2)
                    .foregroundColor(viewModel.speedOrPaceColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
            }
        }
        .padding([.top, .bottom], CGFloat(10.0))
    }
}

struct HomeWorkoutCell_Previews: PreviewProvider {
    static let viewModel: WorkoutCellViewModel = {
        WorkoutCellViewModel(
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
            calories: 500,
            elevation: 0,
            includesLocation: false
        )
    }()
    
    static var previews: some View {
        NavigationView {
            List(1 ..< 5, id: \.self) { _ in
                NavigationLink(destination: Text("Workout")) {
                    HomeWorkoutCell(viewModel: viewModel)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
