//
//  HeartRateOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 3/19/21.
//

import HealthKit

class HeartRateStatsOperation: SyncOperation {
    private var workout: HKWorkout
    
    private(set) var avgHeartRate: Double?
    private(set) var maxHeartRate: Double?
    private(set) var error: Error?
    
    init(workout: HKWorkout) {
        self.workout = workout
        super.init()
    }
    
    override func start() {
        super.start()
        
        WorkoutDataStore.fetchHeartRateStatsValue(workout: workout) { result in
            switch result {
            case .success(let sample):
                self.avgHeartRate = sample.avg
                self.maxHeartRate = sample.max
            case .failure(let error):
                Log.debug("fetching heart rate failed: \(error.localizedDescription)")
                self.error = error
            }
            self.finish()
        }
    }
}
