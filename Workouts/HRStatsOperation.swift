//
//  HeartRateOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 3/19/21.
//

import HealthKit

final class HRStatsOperation: SyncOperation {
    private var workout: HKWorkout
    
    private(set) var avgHeartRate: Double = 0
    private(set) var maxHeartRate: Double = 0
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
                self.avgHeartRate = sample.avg ?? 0
                self.maxHeartRate = sample.max ?? 0
            case .failure(let error):
                Log.debug("fetching heart rate failed: \(error.localizedDescription)")
                self.error = error
            }
            self.finish()
        }
    }
}
