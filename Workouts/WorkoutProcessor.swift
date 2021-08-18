//
//  WorkoutProcessor.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import Foundation
import HealthKit
import CoreLocation
import Polyline

extension WorkoutProcessor {
    struct Object {
        let identifier: UUID
        let sport: Sport
        let indoor: Bool
        let start: Date
        let end: Date
        let duration: Double
        let distance: Double
        let movingTime: Double
        let avgMovingSpeed: Double
        let avgSpeed: Double
        let maxSpeed: Double
        let avgPace: Double
        let avgMovingPace: Double
        let avgCyclingCadence: Double
        let maxCyclingCadence: Double
        let energyBurned: Double
        let avgHeartRate: Double
        let maxHeartRate: Double
        let coordinatesValue: String
        let elevationAscended: Double
        let elevationDescended: Double
        let maxElevation: Double
        let minElevation: Double
        let source: String
        let device: String?
    }
}

final class WorkoutProcessor {
    let workout: HKWorkout
        
    lazy var provider: HealthProvider = {
        HealthProvider.shared
    }()
    
    init(workout: HKWorkout) {
        self.workout = workout
    }
    
    static func object(for workout: HKWorkout) async -> Object {
        let processor = WorkoutProcessor(workout: workout)
        return await processor.object()
    }
    
}

// MARK: Private Methods

extension WorkoutProcessor {
    
    func object() async -> Object {
        var locations: [CLLocation]
        let avgHeartRate: Double
        let maxHeartRate: Double
        
        do {
            locations = try await provider.fetchLocations(for: workout)
            (avgHeartRate, maxHeartRate) = try await provider.fetchHeartRateStats(for: workout)
        } catch {
            locations = []
            avgHeartRate = 0
            maxHeartRate = 0
        }
        
        let coordinates = locations.sorted(by: {$0.timestamp < $1.timestamp}).map({ $0.coordinate })
        let coordinatesValue = Polyline(coordinates: coordinates).encodedPolyline
        
        let altitudes = locations.altitudeValues()
        let minElevation = altitudes.min() ?? 0
        let maxElevation = altitudes.max() ?? 0
        
        let movingTime = workout.duration
        let avgMovingSpeed: Double = totalDistance() / movingTime
        let avgMovingPace: Double = calculateRunningWalkingPace(distanceInMeters: totalDistance(), duration: movingTime) ?? avgPace()
        
        let object = Object(
            identifier: workout.uuid,
            sport: workout.workoutActivityType.sport(),
            indoor: workout.isIndoor,
            start: workout.startDate,
            end: workout.endDate,
            duration: workout.totalElapsedTime,
            distance: totalDistance(),
            movingTime: movingTime,
            avgMovingSpeed: avgMovingSpeed,
            avgSpeed: avgSpeed(),
            maxSpeed: maxSpeed(),
            avgPace: avgPace(),
            avgMovingPace: avgMovingPace,
            avgCyclingCadence: avgCyclingCadence(),
            maxCyclingCadence: maxCyclingCadence(),
            energyBurned: energyBurned(),
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            coordinatesValue: coordinatesValue,
            elevationAscended: elevationAscended(),
            elevationDescended: elevationDescended(),
            maxElevation: minElevation,
            minElevation: maxElevation,
            source: workout.sourceRevision.source.name,
            device: workout.device?.name
        )
        
        return object
    }
    
    
    private func totalDistance() -> Double {
        workout.totalDistance?.doubleValue(for: .meter()) ?? 0
    }
    
    private func avgSpeed() -> Double {
        if let speed = workout.avgSpeed?.doubleValue(for: .metersPerSecond()) {
            return speed
        }
        
        guard workout.totalElapsedTime > 0 else { return 0 }
        let distance = totalDistance()
        return distance / workout.totalElapsedTime
    }
    
    private func maxSpeed() -> Double {
        workout.maxSpeed?.doubleValue(for: .metersPerSecond()) ?? 0
    }
    
    func avgPace() -> Double {
        let sport = workout.workoutActivityType.sport()
        guard sport.isWalkingOrRunning else { return 0 }
        
        let duration = workout.totalElapsedTime
        let distance = totalDistance()
        return calculateRunningWalkingPace(distanceInMeters: distance, duration: duration) ?? 0
    }
    
    func avgCyclingCadence() -> Double {
        workout.avgCyclingCadence ?? 0
    }
    
    func maxCyclingCadence() -> Double {
        workout.maxCyclingCadence ?? 0
    }
    
    private func energyBurned() -> Double {
        workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
    }
    
    private func elevationAscended() -> Double {
        workout.elevationAscended?.doubleValue(for: .meter()) ?? 0
    }
    
    private func elevationDescended() -> Double {
        workout.elevationDescended?.doubleValue(for: .meter()) ?? 0
    }
    
}
