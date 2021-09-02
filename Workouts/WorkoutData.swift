//
//  WorkoutData.swift
//  WorkoutData
//
//  Created by Axel Rivera on 8/13/21.
//

import Foundation
import CoreLocation
import SwiftUI

struct WorkoutData: Identifiable, Hashable {
    static func == (lhs: WorkoutData, rhs: WorkoutData) -> Bool {
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
    let elevation: Double
}

extension WorkoutData {
    
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
    
    var elevationString: String {
        formattedElevationString(for: elevation, zeroPadding: true)
    }
    
}

extension Workout {
    
    func workoutData() -> WorkoutData {
        WorkoutData(
            id: remoteIdentifier!,
            sport: sport,
            indoor: indoor,
            coordinates: coordinates,
            title: title,
            date: start,
            distance: distance,
            duration: duration,
            avgSpeed: avgSpeed,
            avgPace: avgPace,
            elevation: elevationAscended
        )
    }
    
}
