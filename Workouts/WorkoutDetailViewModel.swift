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
    
    let elevationAscended: Double
    let elevationDescended: Double
    
    let minElevation: Double
    let maxElevation: Double
    
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
    
    var outdoor: Bool {
        !indoor
    }
    
    var includesLocation: Bool {
        outdoor && sport.hasDistanceSamples
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
    
    static func empty() -> WorkoutDetailViewModel {
        WorkoutDetailViewModel(
            id: UUID(),
            sport: .cycling,
            indoor: false,
            title: "",
            coordinates: [],
            start: Date(),
            end: Date(),
            movingTime: 0,
            duration: 0,
            distance: 0,
            avgMovingSpeed: 0,
            avgSpeed: 0,
            maxSpeed: 0,
            avgCyclingCadence: 0,
            maxCyclingCadence: 0,
            avgPace: 0,
            elevationAscended: 0,
            elevationDescended: 0,
            minElevation: 0,
            maxElevation: 0,
            energyBurned: 0,
            avgHeartRate: 0,
            maxHeartRate: 0,
            trimp: 0,
            avgHeartRateReserve: 0,
            zoneMaxHeartRate: 0,
            zoneValues: [],
            source: "",
            device: nil,
            appIdentifier: nil
        )
    }
    
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
            minElevation: workout.minElevation,
            maxElevation: workout.maxElevation,
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
