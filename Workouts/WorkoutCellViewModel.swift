//
//  WorkoutCellViewModel.swift
//  WorkoutData
//
//  Created by Axel Rivera on 8/13/21.
//

import Foundation
import CoreLocation
import SwiftUI

struct WorkoutCellViewModel: Identifiable, Hashable {
    static func == (lhs: WorkoutCellViewModel, rhs: WorkoutCellViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: UUID
    let sport: Sport
    let indoor: Bool
    let coordinates: [CLLocationCoordinate2D]
    let title: String
    let date: Date
    let distance: Double
    let duration: Double
    let avgSpeed: Double
    let avgPace: Double
    let calories: Double
    let elevation: Double
    let includesLocation: Bool
}

extension WorkoutCellViewModel {
    
    func dateString(shortDay: Bool = false) -> String {
        formattedRelativeDateString(for: date, shortDay: shortDay, showTime: true)
    }
    
    var distanceString: String {
        formattedDistanceString(for: distance, zeroPadding: true)
    }
    
    var durationString: String {
        formattedHoursMinutesPrettyString(for: duration)
    }
    
    var speedOrPaceString: String {
        if sport == .cycling {
            return formattedSpeedString(for: avgSpeed)
        } else {
            return formattedRunningWalkingPaceString(for: avgPace)
        }
    }
    
    var speedOrPaceColor: Color {
        if sport == .cycling {
            return .speed
        } else {
            return .cadence
        }
    }
    
    var calorieString: String {
        formattedCaloriesString(for: calories, zeroPadding: true)
    }
    
    var elevationString: String {
        formattedElevationString(for: elevation, zeroPadding: true)
    }
    
}

extension Workout {
    
    var cellViewModel: WorkoutCellViewModel {
        WorkoutCellViewModel(
            id: remoteIdentifier!,
            sport: sport,
            indoor: indoor,
            coordinates: coordinates,
            title: title,
            date: start,
            distance: distance,
            duration: movingTime,
            avgSpeed: avgSpeed,
            avgPace: avgPace,
            calories: energyBurned,
            elevation: elevationAscended,
            includesLocation: coordinates.isPresent
        )
    }
    
}
