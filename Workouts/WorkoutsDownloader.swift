//
//  WorkoutsDownloader.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import Foundation
import HealthKit

final class WorkoutsDownloader {
    let healthStore = HealthData.shared.healthStore
    
    func fetchLatestWorkouts(anchor: HKQueryAnchor?, completion: @escaping (_ remoteWorkouts: [HKWorkout], _ deleted: [UUID], _ newAnchor: HKQueryAnchor?) -> Void) {
        let query = HKAnchoredObjectQuery(
            type: .workoutType(),
            predicate: WorkoutDataStore.shared.defaultActivitiesPredicate(),
            anchor: anchor, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deleted, newAnchor, error in
            guard let self = self else { return }
            self.healthStore.stop(query)
            
            if let _ = error {
                completion([], [], nil)
                return
            }

            let workouts = samples as? [HKWorkout] ?? [HKWorkout]()
            let deleted = (deleted ?? [HKDeletedObject]()).map({ $0.uuid })
            
            completion(workouts, deleted, newAnchor)
        }

        healthStore.execute(query)
    }
    
}
