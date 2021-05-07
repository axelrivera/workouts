//
//  HeartRateOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 3/19/21.
//

import HealthKit

class HeartRateOperation: SyncOperation {
    private var workout: HKWorkout
    
    private(set) var heartRateValues = [TimeAxisValue]()
    
    init(workout: HKWorkout) {
        self.workout = workout
        super.init()
    }
    
    override func start() {
        super.start()
        
        WorkoutDataStore.fetchHeartRateSamples(workout: workout) { result in
            guard let samples = try? result.get(), !samples.isEmpty else {
                self.finish()
                return
            }
            
            let startDate = samples[0].timestamp
            let values = samples.map { quantity in
                TimeAxisValue(duration: quantity.timestamp.timeIntervalSince(startDate), value: quantity.value)
            }
            
            self.heartRateValues = values
            self.finish()
        }
    }
}
