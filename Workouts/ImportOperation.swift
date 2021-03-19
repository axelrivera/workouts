//
//  ImportOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 2/1/21.
//

import Foundation

class ImportOperation: SyncOperation {
    
    var workout: WorkoutImport
    
    init(workout: WorkoutImport) {
        self.workout = workout
        super.init()
    }
        
    override func start() {
        super.start()
        
        WorkoutDataStore.saveWorkoutImport(workout) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.workout.status = .processed
                case .failure:
                    self.workout.status = .failed
                }
                                    
                self.finish()
            }
        }
    }
    
}
