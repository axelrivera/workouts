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
    
    func fethLatestWorkouts(anchor: HKQueryAnchor?) async -> (remoteWorkouts: [HKWorkout], deleted: [UUID], newAnchor: HKQueryAnchor?) {
        return await withCheckedContinuation { continuation in
            fetchLatestWorkouts(anchor: anchor) { remoteWorkouts, deleted, newAnchor in
                continuation.resume(returning: (remoteWorkouts, deleted, newAnchor))
            }
        }
    }
    
    private func fetchLatestWorkouts(anchor: HKQueryAnchor?, completion: @escaping (_ remoteWorkouts: [HKWorkout], _ deleted: [UUID], _ newAnchor: HKQueryAnchor?) -> Void) {
        let query = HKAnchoredObjectQuery(
            type: .workoutType(),
            predicate: HealthProvider.shared.defaultActivitiesPredicate(),
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
