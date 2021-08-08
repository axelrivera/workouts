//
//  WorkoutProcessor.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import Foundation
import HealthKit
import CoreLocation


extension WorkoutProcessor.Object {
    
    static func empty() -> WorkoutProcessor.Object {
        WorkoutProcessor.Object(
            records: [],
            duration: 0,
            distance: 0,
            movingTime: 0,
            avgMovingSpeed: 0,
            avgSpeed: 0,
            maxSpeed: 0,
            avgPace: 0,
            avgHeartRate: 0,
            maxHeartRate: 0,
            showMap: false
        )
    }
    
}

extension WorkoutProcessor {
    struct Object {
        let records: [SampleProcessor.Record]
        let duration: Double
        let distance: Double
        let movingTime: Double
        let avgMovingSpeed: Double
        let avgSpeed: Double
        let maxSpeed: Double
        let avgPace: Double
        let avgHeartRate: Double
        let maxHeartRate: Double
        let showMap: Bool
    }
}

final class WorkoutProcessor {
    let workout: HKWorkout
    
    private(set) var object: Object
    
    private lazy var processQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(workout: HKWorkout) {
        self.workout = workout
        object = Object.empty()
    }
    
    static func object(for workout: HKWorkout) -> Object {
        let processor = WorkoutProcessor(workout: workout)
        processor.generateRecords()
        return processor.object
    }
    
}

// MARK: Private Methods

extension WorkoutProcessor {
    
    private func generateRecords() {
        var operations = [Operation]()
        
        let locationOperation = LocationOperation(workout: workout)
        if workout.isOutdoor {
            operations.append(locationOperation)
        }
        
        let hrStatsOperation = HRStatsOperation(workout: workout)
        operations.append(hrStatsOperation)
        
        let hrOperation = HRSamplesOperation(workout: workout)
        operations.append(hrOperation)
        
        let cadenceOperation = CadenceSamplesOperation(workout: workout)
        if workout.workoutActivityType.isCycling {
            operations.append(cadenceOperation)
        }
        
        let completionOperation = BlockOperation { [unowned self] in
            let locations = locationOperation.locations
            let heartRateSamples = hrOperation.samples
            let cadenceSamples = cadenceOperation.samples
            let avgHeartRate = hrStatsOperation.avg
            let maxHeartRate = hrStatsOperation.max
            
            let validations = [
                locations.isPresent,
                heartRateSamples.isPresent,
                cadenceSamples.isPresent
            ].compactMap { $0 ? true : nil }
               
            let shouldGenerateRecords = validations.isPresent
            if shouldGenerateRecords {
                let generator = SampleProcessor(
                    workout: self.workout,
                    locations: locations,
                    heartRateSamples: heartRateSamples,
                    cadenceSamples: cadenceSamples
                )
                generator.process()
                
                let showMap = !workout.isIndoor && locations.isPresent
                
                self.object = Object(
                    records: generator.validRecords,
                    duration: generator.duration,
                    distance: totalDistance(),
                    movingTime: generator.movingTime,
                    avgMovingSpeed: generator.avgMovingSpeed,
                    avgSpeed: generator.avgSpeed(),
                    maxSpeed: generator.maxSpeed(),
                    avgPace: generator.avgPace(),
                    avgHeartRate: avgHeartRate,
                    maxHeartRate: maxHeartRate,
                    showMap: showMap
                )
            } else {
                self.object = Object(
                    records: [],
                    duration: workout.duration,
                    distance: totalDistance(),
                    movingTime: workout.duration,
                    avgMovingSpeed: avgSpeed(),
                    avgSpeed: avgSpeed(),
                    maxSpeed: maxSpeed(),
                    avgPace: avgPace(),
                    avgHeartRate: avgHeartRate,
                    maxHeartRate: maxHeartRate,
                    showMap: false
                )
            }
        }
        
        operations.forEach({ completionOperation.addDependency($0) })
        operations.append(completionOperation)
        
        processQueue.addOperations(operations, waitUntilFinished: true)
        processQueue.waitUntilAllOperationsAreFinished()
    }
    
    private func totalDistance() -> Double {
        workout.totalDistance?.doubleValue(for: .meter()) ?? 0
    }
    
    private func avgSpeed() -> Double {
        if let speed = workout.avgSpeed?.doubleValue(for: .metersPerSecond()) {
            return speed
        }
        
        guard workout.duration > 0 else { return 0 }
        let distance = totalDistance()
        return distance / workout.duration
    }
    
    private func maxSpeed() -> Double {
        workout.maxSpeed?.doubleValue(for: .metersPerSecond()) ?? 0
    }
    
    func avgPace() -> Double {
        let sport = workout.workoutActivityType.sport()
        guard sport.isWalkingOrRunning else { return 0 }
        
        let duration = workout.duration
        let distance = totalDistance()
        return calculateRunningWalkingPace(distanceInMeters: distance, duration: duration) ?? 0
    }
    
}
