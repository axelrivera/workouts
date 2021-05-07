//
//  PaceOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 3/19/21.
//

import HealthKit

class PaceOperation: SyncOperation {
    private var workout: HKWorkout
    
    private(set) var paceValues = [TimeAxisValue]()
    private(set) var bestPace: Double = 0
    
    init(workout: HKWorkout) {
        self.workout = workout
        super.init()
    }
    
    override func start() {
        super.start()
        
        WorkoutDataStore.fetchRunningWalkingPaceSamples(workout: workout) { result in
            guard let samples = try? result.get(), !samples.isEmpty else {
                self.finish()
                return
            }
            
            let bestPace = samples.map({ $0.value }).min() ?? 0
            let startDate = samples[0].timestamp
            let values = samples.map { quantity in
                TimeAxisValue(duration: quantity.timestamp.timeIntervalSince(startDate), value: quantity.value)
            }
            
            self.paceValues = values
            self.bestPace = bestPace
            self.finish()
        }
    }
    
}
