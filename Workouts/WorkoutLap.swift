//
//  WorkoutLap.swift
//  Workouts
//
//  Created by Axel Rivera on 8/8/21.
//

import Foundation
import CoreLocation

// On UI show Duration, Avg Heart Rate, Pace/Cadence

struct WorkoutLap: Identifiable, Equatable, Hashable {
    var id = UUID()
    
    let sport: Sport
    let lapNumber: Int
    let distance: Double
    let duration: Double
    let avgSpeed: Double
    let avgPace: Double
    let avgCadence: Double
    let avgHeartRate: Double
    let maxHeartRate: Double
}

extension WorkoutLap: CustomStringConvertible {

    var description: String {
        let dict: [String: Any] = [
            "sport": sport.rawValue,
            "lapNumber": lapNumber,
            "distance": distance,
            "duration": duration,
            "avgSpeed": avgSpeed,
            "avgPace": avgPace,
            "avgCadence": avgCadence,
            "avgHeartRate": avgHeartRate,
            "maxHeartRate": maxHeartRate
        ]
        return dict.map( { "\($0): \($1)"} ).joined(separator: ", ")
    }
    
}
