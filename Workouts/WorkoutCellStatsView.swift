//
//  WorkoutCellStatsView.swift
//  Workouts
//
//  Created by Axel Rivera on 11/12/21.
//

import SwiftUI

//struct WorkoutCellStatsView: View {
//    let viewModel: WorkoutViewModel
//
//    var body: some View {
//        HStack {
//            Text(viewModel.distanceString)
//                .font(.fixedBody)
//                .foregroundColor(.distance)
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//            Text(viewModel.durationString)
//                .font(.fixedBody)
//                .foregroundColor(.time)
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//            Text(viewModel.speedOrPaceString)
//                .font(.fixedBody)
//                .foregroundColor(viewModel.speedOrPaceColor)
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//            if viewModel.sport == .cycling && !viewModel.indoor {
//                Text(viewModel.elevationString)
//                    .font(.fixedBody)
//                    .foregroundColor(.elevation)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//        }
//    }
//}
//
//struct WorkoutCellStatsView_Previews: PreviewProvider {
//    static let viewModel: WorkoutCellViewModel = {
//        WorkoutCellViewModel(
//            id: UUID(),
//            sport: .cycling,
//            indoor: false,
//            coordinates: [],
//            title: "Outdoor Cycling",
//            date: Date(),
//            distance: milesToMeters(for: 10),
//            duration: hoursToSeconds(for: 1),
//            avgSpeed: 0,
//            avgPace: 0,
//            calories: 0,
//            elevation: 0,
//            includesLocation: true,
//            isLocationPending: false
//        )
//    }()
//
//
//    static var previews: some View {
//        WorkoutCellStatsView(viewModel: viewModel)
//            .padding()
//    }
//}
