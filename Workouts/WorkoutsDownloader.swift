//
//  WorkoutsDownloader.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import Foundation
import HealthKit

final class WorkoutsDownloader {
    let healthStore = HealthData.healthStore
    
    func fetchLatestWorkouts(completion: @escaping (_ remoteWorkouts: [HKWorkout], _ deleted: [UUID]) -> Void) {
        Log.debug("fetch latest workouts")
        
        let query = HKAnchoredObjectQuery(
            type: .workoutType(),
            predicate: WorkoutDataStore.defaultActivitiesPredicate(),
            anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, deleted, newAnchor, error in
            if let error = error {
                Log.debug("failed to fetch workouts: \(error.localizedDescription)")
            }

            let workouts = samples as? [HKWorkout] ?? [HKWorkout]()
            let deleted = (deleted ?? [HKDeletedObject]()).map({ $0.uuid })
            completion(workouts, deleted)
        }

        healthStore.execute(query)
    }
    
}
