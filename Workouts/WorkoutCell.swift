//
//  WorkoutCell.swift
//  Workouts
//
//  Created by Axel Rivera on 7/31/21.
//

import SwiftUI

struct WorkoutCell: View {
    var viewModel: WorkoutDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            HStack {
                Text(viewModel.title)
                    .font(.fixedTitle2)
                Spacer()
                Text(DateFormatter.medium.string(from: viewModel.start))
                     .font(.fixedBody)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .center, spacing: 5.0) {
                Text(formattedDistanceString(for: viewModel.distance, zeroPadding: true))
                    .workoutCellLabelStyle(color: .distance)
                                    
                Text(formattedHoursMinutesPrettyString(for: viewModel.movingTime))
                    .workoutCellLabelStyle(color: .time)
                                
                Text(formattedCaloriesString(for: viewModel.energyBurned, zeroPadding: true))
                    .workoutCellLabelStyle(color: .calories)
                
                Text(formattedElevationString(for: viewModel.elevationAscended, zeroPadding: true))
                    .workoutCellLabelStyle(color: .elevation)
            }
        }
    }
}

struct WorkoutPlainCell: View {
    var viewModel: WorkoutDetailViewModel
    
    var body: some View {
        WorkoutCell(viewModel: viewModel)
            .padding([.top, .bottom], 5)
    }
}

struct WorkoutCell_Previews: PreviewProvider {
    static var workout = StorageProvider.sampleWorkout()
    
    static var previews: some View {
        NavigationView {
            List(1...10, id: \.self) { _ in
                WorkoutCell(viewModel: workout.detailViewModel)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Workouts")
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Workout Cell Additions

struct WorkoutCellLabel: ViewModifier {
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .font(.fixedBody)
            .minimumScaleFactor(0.3)
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

extension View {
    
    func workoutCellLabelStyle(color: Color) -> some View {
        modifier(WorkoutCellLabel(color: color))
    }
    
}

struct WorkoutButtonStyle: ButtonStyle {

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
        .padding()
        .background(configuration.isPressed ? Color.selectedCell : Color.secondarySystemBackground)
        .cornerRadius(12.0)
  }

}

struct WorkoutAnalysisButtonStyle: ButtonStyle {

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
          .foregroundColor(.white)
          .padding()
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 120.0, alignment: .leading)
          .background(configuration.isPressed ? Color.selectedCell : Color.accentColor)
          .cornerRadius(12.0)
  }

}

struct WorkoutMapButtonStyle: ButtonStyle {

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 200.0, alignment: .center)
          .overlay(configuration.isPressed ? Color.black.opacity(0.3) : Color.clear)
          .cornerRadius(12.0)
  }

}

struct WorkoutPlainButtonStyle: ButtonStyle {

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
          .background(configuration.isPressed ? Color.selectedCell : .systemBackground)
  }

}

