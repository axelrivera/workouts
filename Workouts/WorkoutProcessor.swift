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

fileprivate let gregorianCalendar = Calendar.init(identifier: .gregorian)

extension WorkoutProcessor {
    struct InsertObject {
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
        let elevationAscended: Double
        let elevationDescended: Double
        let source: String
        let device: String?
        
        var weekday: Int {
            gregorianCalendar.component(.weekday, from: start)
        }
    }
    
    struct UpdateObject {
        let coordinatesValue: String
        let minElevation: Double
        let maxElevation: Double
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
    
    static func insertObject(for workout: HKWorkout) async -> InsertObject {
        let processor = WorkoutProcessor(workout: workout)
        return await processor.insertObject()
    }
    
    static func updateObject(for workout: HKWorkout) async -> UpdateObject {
        let processor = WorkoutProcessor(workout: workout)
        return await processor.updateObject()
    }
    
}

// MARK: Private Methods

extension WorkoutProcessor {
    
    func insertObject() async -> InsertObject {
        let avgHeartRate: Double
        let maxHeartRate: Double
        let activeEnergy: Double
        
        do {
            (avgHeartRate, maxHeartRate) = try await provider.fetchHeartRateStats(for: workout)
        } catch {
            Log.debug("fetching heart rate stats failed for workout: \(workout.uuid) - \(error.localizedDescription)")
            avgHeartRate = 0
            maxHeartRate = 0
            
        }
        
        do {
            activeEnergy = try await provider.fetchActiveEnergy(for: workout)
        } catch {
            Log.debug("fetching energy failed for workout: \(workout.uuid) - \(error.localizedDescription)")
            activeEnergy = energyBurned()
        }
        
        let movingTime = workout.duration
        let avgMovingSpeed: Double = totalDistance() / movingTime
        let avgMovingPace: Double = calculateRunningWalkingPace(distanceInMeters: totalDistance(), duration: movingTime) ?? avgPace()
        
        // calculated values
        // coordinatesValue, minElevation, maxElevation, avgHeartRate, maxHeartRage
        
        let object = InsertObject(
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
            energyBurned: activeEnergy,
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            elevationAscended: elevationAscended(),
            elevationDescended: elevationDescended(),
            source: workout.sourceRevision.source.name,
            device: workout.device?.name
        )
        
        return object
    }
    
    func updateObject() async -> UpdateObject {
        var locations: [CLLocation]
        
        do {
            locations = try await provider.fetchLocations(for: workout)
        } catch {
            locations = []
        }
        
        var coordinates = [CLLocationCoordinate2D]()
        var altitudes = [Double]()
        
        for location in locations {
            coordinates.append(location.coordinate)
            altitudes.append(location.altitude)
        }
        
        let coordinatesValue = Polyline(coordinates: coordinates).encodedPolyline
        let minElevation = altitudes.min() ?? 0
        let maxElevation = altitudes.max() ?? 0
        
        let object = UpdateObject(
            coordinatesValue: coordinatesValue,
            minElevation: minElevation,
            maxElevation: maxElevation
        )
        return object
    }
    
    private func totalDistance() -> Double {
        workout.totalDistance?.doubleValue(for: .meter()) ?? 0
    }
    
    private func avgSpeed() -> Double {        
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
        workout.totalEnergyBurned?.doubleValue(for: .largeCalorie()) ?? 0
    }
    
    private func elevationAscended() -> Double {
        workout.elevationAscended?.doubleValue(for: .meter()) ?? 0
    }
    
    private func elevationDescended() -> Double {
        workout.elevationDescended?.doubleValue(for: .meter()) ?? 0
    }
    
}
