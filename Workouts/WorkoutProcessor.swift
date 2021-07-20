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
        let avgHeartRate: Double
        let maxHeartRate: Double
        let showMap: Bool
    }
}

final class WorkoutProcessor {
    let workout: HKWorkout
    
    var locations = [CLLocation]()
    var heartRateSamples = [Quantity]()
    var cadenceSamples = [Quantity]()
    var paceSamples = [Pace]()
    
    private(set) var object: Object
    
    private var avgHeartRate: Double = 0
    private var maxHeartRate: Double = 0
    
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
        if workout.isOutdoor {
            fetchLocations()
        }
        
        fetchHeartRateStats()
        fetchHeartRateSamples()
        
        if workout.workoutActivityType.isCycling {
            fetchCadenceSamples()
        }
        
        if workout.workoutActivityType.isRunningWalking {
            fetchPaceSamples()
        }
        
        let shouldGenerateRecords = locations.isPresent || heartRateSamples.isPresent ||
            cadenceSamples.isPresent || paceSamples.isPresent
        
        if shouldGenerateRecords {
            let generator = SampleProcessor(
                workout: self.workout,
                locations: locations,
                heartRateSamples: heartRateSamples,
                cadenceSamples: cadenceSamples,
                paceSamples: paceSamples
            )
            generator.process()
            
            let showMap = !workout.isIndoor && locations.isPresent
            
            object = Object(
                records: generator.validRecords,
                duration: generator.duration,
                distance: totalDistance(),
                movingTime: generator.movingTime,
                avgMovingSpeed: generator.avgMovingSpeed,
                avgSpeed: generator.avgSpeed(),
                maxSpeed: generator.maxSpeed(),
                avgHeartRate: self.avgHeartRate,
                maxHeartRate: self.maxHeartRate,
                showMap: showMap
            )
        } else {
            object = Object(
                records: [],
                duration: workout.duration,
                distance: totalDistance(),
                movingTime: workout.duration,
                avgMovingSpeed: avgSpeed(),
                avgSpeed: avgSpeed(),
                maxSpeed: maxSpeed(),
                avgHeartRate: self.avgHeartRate,
                maxHeartRate: self.maxHeartRate,
                showMap: false
            )
        }
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
    
    private func fetchLocations() {
        let semaphore = DispatchSemaphore(value: 0)
        
        WorkoutDataStore.shared.fetchRoute(for: workout) { [weak self] (result) in
            guard let self = self else {
                semaphore.signal()
                return
            }
            
            switch result {
            case .success(let locations):
                self.locations = locations
            case .failure(let error):
                Log.debug("fetching route failed: \(error.localizedDescription)")
            }
                        
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    private func fetchHeartRateStats() {
        let semaphore = DispatchSemaphore(value: 0)
        
        WorkoutDataStore.shared.fetchHeartRateStatsValue(workout: workout) { [weak self] result in
            guard let self = self else {
                semaphore.signal()
                return
            }
            
            switch result {
            case .success(let sample):
                self.avgHeartRate = sample.avg ?? 0
                self.maxHeartRate = sample.max ?? 0
            case .failure(let error):
                Log.debug("fetching heart rate failed: \(error.localizedDescription)")
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    private func fetchHeartRateSamples() {
        let semaphore = DispatchSemaphore(value: 0)
        
        WorkoutDataStore.shared.fetchHeartRateSamples(workout: workout) { [weak self] result in
            guard let self = self else {
                semaphore.signal()
                return
            }
            if let samples = try? result.get() as? [Quantity] {
                self.heartRateSamples = samples
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    private func fetchCadenceSamples() {
        let semaphore = DispatchSemaphore(value: 0)
        
        WorkoutDataStore.shared.fetchCyclingCadenceSamples(workout: workout) { [weak self] result in
            guard let self = self else {
                semaphore.signal()
                return
            }
            if let samples = try? result.get() as? [Quantity] {
                self.cadenceSamples = samples
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    private func fetchPaceSamples() {
        let semaphore = DispatchSemaphore(value: 0)
        
        WorkoutDataStore.shared.fetchRunningWalkingPaceSamples(workout: workout) { [weak self] result in
            guard let self = self else {
                semaphore.signal()
                return
            }
            
            if let samples = try? result.get() as? [Pace] {
                self.paceSamples = samples
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
}
