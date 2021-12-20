//
//  LocationOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 8/4/21.
//

import Foundation
import CoreLocation
import HealthKit

class HealthOperation: SyncOperation {
    private(set) var workout: HKWorkout
    
    init(workout: HKWorkout) {
        self.workout = workout
    }
    
}

class LocationOperation: HealthOperation {
    private(set) var locations = [CLLocation]()
    
    override func start() {
        super.start()
        
        WorkoutDataStore.shared.fetchRoute(for: workout) { [unowned self] (result) in
            switch result {
            case .success(let locations):
                self.locations = locations
            case .failure(let error):
                Log.debug("LOCATION - fetching route failed: \(error.localizedDescription)")
            }
            self.finish()
        }
        
    }
    
}

class HRStatsOperation: HealthOperation {
    private(set) var avg: Double = 0
    private(set) var max: Double = 0
    
    override func start() {
        super.start()
        
        WorkoutDataStore.shared.fetchHeartRateStatsValue(workout: workout) { [unowned self] result in
            switch result {
            case .success(let sample):
                self.avg = sample.avg ?? 0
                self.max = sample.max ?? 0
            case .failure(let error):
                Log.debug("fetching heart rate failed: \(error.localizedDescription)")
            }
            self.finish()
        }
    }
    
}

class HRSamplesOperation: HealthOperation {
    private(set) var samples = [Quantity]()
    
    override func start() {
        super.start()
        
        WorkoutDataStore.shared.fetchHeartRateSamples(workout: workout) { [unowned self] result in
            if let samples = try? result.get() as? [Quantity] {
                self.samples = samples
            }
            self.finish()
        }
    }
    
}

class CadenceSamplesOperation: HealthOperation {
    private(set) var samples = [Quantity]()
    
    override func start() {
        super.start()
        
        WorkoutDataStore.shared.fetchCyclingCadenceSamples(workout: workout) { [unowned self] result in
            if let samples = try? result.get() as? [Quantity] {
                self.samples = samples
            }
            self.finish()
        }
    }
    
}
