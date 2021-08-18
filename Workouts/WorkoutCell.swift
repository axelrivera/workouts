//
//  WorkoutCell.swift
//  Workouts
//
//  Created by Axel Rivera on 7/31/21.
//

import SwiftUI

struct WorkoutCell: View {
    var workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5.0) {
            HStack {
                Text(workout.title)
                    .font(.fixedTitle2)
                Spacer()
                Text(formattedRelativeDateString(for: workout.start))
                     .font(.fixedBody)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .center, spacing: 5.0) {
                Text(formattedDistanceString(for: workout.distance, zeroPadding: true))
                    .workoutCellLabelStyle(color: .distance)
                                    
                Text(formattedHoursMinutesPrettyString(for: workout.movingTime))
                    .workoutCellLabelStyle(color: .time)
                                
                Text(formattedCaloriesString(for: workout.energyBurned, zeroPadding: true))
                    .workoutCellLabelStyle(color: .calories)
            }
        }
    }
}

struct WorkoutPlainCell: View {
    var workout: Workout
    
    var body: some View {
        WorkoutCell(workout: workout)
            .padding([.top, .bottom], 5)
    }
}

struct WorkoutCell_Previews: PreviewProvider {
    static var workout = StorageProvider.sampleWorkout()
    
    static var previews: some View {
        NavigationView {
            List(1...10, id: \.self) { _ in
                WorkoutCell(workout: workout)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Workout Cell Additions

private struct WorkoutCellLabel: ViewModifier {
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .font(.fixedTitle3)
            .minimumScaleFactor(0.3)
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

private extension View {
    
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
        .background(configuration.isPressed ? Color.selectedCell : Color.clear)
  }

}

