//
//  WorkoutOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 8/9/21.
//

import HealthKit

class WorkoutOperation: SyncOperation {
    
    private(set) var uuid: UUID
    private(set) var workout: HKWorkout?
    private let store = WorkoutDataStore.shared
    
    init(uuid: UUID) {
        self.uuid = uuid
    }
    
    override func start() {
        super.start()
        
        store.fetchWorkout(for: uuid) { [weak self] workout in
            guard let self = self else { return }
            self.workout = workout
            self.finish()
        }
        
    }
}
