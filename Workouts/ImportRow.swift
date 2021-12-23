//
//  ImportRow.swift
//  Workouts
//
//  Created by Axel Rivera on 2/1/21.
//

import SwiftUI

struct ImportRow: View {
    @ObservedObject var workout: WorkoutImport
    
    var importAction = {}
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        HStack(spacing: 10.0) {
            VStack(alignment: .leading) {
                Text(workout.formattedTitle)
                
                if let distance = workout.totalDistance.distanceValue {
                    Text(formattedDistanceString(for: distance))
                        .font(.title)
                        .foregroundColor(.distance)
                }
                
                Text(formattedImportRelativeDateString(for: workout.startDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            switch workout.status {
            case .new:
                Button(action: importAction) {
                    Text("Import")
                }
                .foregroundColor(.accentColor)
            case .processing:
                Image(systemName: "hourglass")
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        let animation = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                        withAnimation(animation) {
                            rotationAngle = 360.0
                        }
                    }
            case .processed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .notSupported:
                Text("Not Supported")
                    .font(.subheadline)
                    .foregroundColor(.red)
            case .failed:
                Text("Import Failed")
                    .font(.subheadline)
                    .foregroundColor(.red)
            case .invalid:
                Text("Invalid")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
    }
}

struct ImportRow_Previews: PreviewProvider {
    static var workout: WorkoutImport = {
        let workout = ImportManager.sampleWorkout()
        workout.status = .processing
        return workout
    }()
    
    static var previews: some View {
        ImportRow(workout: workout)
            .padding()
    }
}
