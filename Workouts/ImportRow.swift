//
//  ImportRow.swift
//  Workouts
//
//  Created by Axel Rivera on 2/1/21.
//

import SwiftUI

struct ImportRow: View {
    @ObservedObject var workout: WorkoutImport
    
    var body: some View {
        HStack(spacing: 10.0) {
            if workout.status == .processing {
                StatsView()
            } else {
                Image(systemName: imageName(for: workout.status))
                    .foregroundColor(imageColor(for: workout.status))
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text(workout.formattedTitle)
                    
                    if workout.status == .notSupported {
                        Spacer()
                        Text("Not Supported")
                            .foregroundColor(.red)
                    } else if workout.status == .failed {
                        Spacer()
                        Text("Import Error")
                            .foregroundColor(.red)
                    }
                }
                HStack {
                    Text(formattedDistanceString(for: workout.totalDistance.distanceValue))
                        .font(.title)
                        .foregroundColor(.accentColor)
                    Spacer()
                    Text(formattedRelativeDateString(for: workout.startDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
        }
    }
}

extension ImportRow {
    
    func imageName(for status: WorkoutImport.Status) -> String {
        switch status {
        case .new:
            return "checkmark.circle"
        case .processed:
            return "checkmark.circle.fill"
        case .failed, .notSupported:
            return "xmark.circle.fill"
        default:
            return ""
        }
    }
    
    func imageColor(for status: WorkoutImport.Status) -> Color {
        switch status {
        case .new:
            return .accentColor
        case .processed:
            return .green
        case .failed, .notSupported:
            return .red
        default:
            return .primary
        }
    }
    
}

struct ImportRow_Previews: PreviewProvider {
    static var previews: some View {
        ImportRow(workout: ImportManager.sampleWorkout())
    }
}
