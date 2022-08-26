//
//  ImportRow.swift
//  Workouts
//
//  Created by Axel Rivera on 2/1/21.
//

import SwiftUI

struct ImportRow: View {
    @ObservedObject var workout: WorkoutImport
    
    var imageName: String {
        if workout.status == .processing {
            return WorkoutImport.Status.new.imageName
        } else {
            return workout.status.imageName
        }
    }
    
    var imageColor: Color {
        if workout.status == .processing {
            return WorkoutImport.Status.new.color
        } else {
            return workout.status.color
        }
    }
    
    var body: some View {
        HStack(spacing: 10.0) {
            Image(systemName: imageName)
                .foregroundColor(imageColor)
            
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
            
            if workout.status == .processing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
}

struct ImportRow_Previews: PreviewProvider {
    static var workout: WorkoutImport = WorkoutImport(status: .processing, sport: .cycling)
    
    static var previews: some View {
        ImportRow(workout: workout)
            .padding()
    }
}
