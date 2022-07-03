//
//  WorkoutDetailViewModel.swift
//  WorkoutDetailViewModel
//
//  Created by Axel Rivera on 9/1/21.
//

import Foundation
import CoreLocation

struct WorkoutDetailViewModel {
    static func == (lhs: WorkoutDetailViewModel, rhs: WorkoutDetailViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: UUID
    let sport: Sport
    let indoor: Bool
    let title: String
    let coordinates: [CLLocationCoordinate2D]
    
    let start: Date
    let end: Date

    let movingTime: Double
    let duration: Double
    
    let distance: Double
    
    let avgMovingSpeed: Double
    let avgSpeed: Double
    let maxSpeed: Double
    
    let avgCyclingCadence: Double
    let maxCyclingCadence: Double
    
    let avgPace: Double
    
    var elevationAscended: Double
    var elevationDescended: Double
    
    let energyBurned: Double
    let avgHeartRate: Double
    let maxHeartRate: Double
    
    let trimp: Int
    let avgHeartRateReserve: Double
    
    let zoneMaxHeartRate: Int
    let zoneValues: [Int]
        
    let source: String
    let device: String?
    let appIdentifier: String?
    
}

extension WorkoutDetailViewModel {
    
    var includesLocation: Bool {
        !coordinates.isEmpty
    }
    
    var shouldUseMovingTime: Bool {
        movingTime < duration
    }
    
    var totalTimeLabel: String {
        shouldUseMovingTime ? "Moving Time" : "Time"
    }
    
    var totalTime: Double {
        shouldUseMovingTime ? movingTime : duration
    }
    
    var pausedTime: Double {
        duration - movingTime
    }
    
    var detailTitle: String {
        switch sport {
        case .cycling:
            return "Ride"
        case .running:
            return "Run"
        case .walking:
            return "Walk"
        default:
            return ""
        }
    }
    
    var analysisTitle: String {
        let distanceStr = formattedDistanceString(for: distance)
        return String(format: "%@ %@", distanceStr, title)
    }
    
}

extension WorkoutDetailViewModel {
    
    static func model(for workout: Workout) -> WorkoutDetailViewModel {
        WorkoutDetailViewModel(
            id: workout.workoutIdentifier,
            sport: workout.sport,
            indoor: workout.indoor,
            title: workout.title,
            coordinates: workout.coordinates,
            start: workout.start,
            end: workout.end,
            movingTime: workout.movingTime,
            duration: workout.duration,
            distance: workout.distance,
            avgMovingSpeed: workout.avgMovingSpeed,
            avgSpeed: workout.avgSpeed,
            maxSpeed: workout.maxSpeed,
            avgCyclingCadence: workout.avgCyclingCadence,
            maxCyclingCadence: workout.maxCyclingCadence,
            avgPace: workout.avgMovingPace,
            elevationAscended: workout.elevationAscended,
            elevationDescended: workout.elevationDescended,
            energyBurned: workout.energyBurned,
            avgHeartRate: workout.avgHeartRate,
            maxHeartRate: workout.maxHeartRate,
            trimp: workout.trimp,
            avgHeartRateReserve: workout.avgHeartRateReserve,
            zoneMaxHeartRate: workout.zoneMaxHeartRate,
            zoneValues: workout.zoneValues,
            source: workout.source,
            device: workout.deviceString,
            appIdentifier: workout.appIdentifier
        )
    }
    
}

extension Workout {
    
    var detailViewModel: WorkoutDetailViewModel {
        WorkoutDetailViewModel.model(for: self)
    }
    
}
