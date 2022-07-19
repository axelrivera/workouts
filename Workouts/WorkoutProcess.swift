//
//  WorkoutProcessorOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 7/17/22.
//

import Foundation
import HealthKit

class WorkoutProcess: SyncOperation {
    
    let identifier: UUID
    var workout: HKWorkout?
    private(set) var result = WorkoutProcessor.Result.empty
    
    private let provider = HealthProvider.shared
    
    init(identifier: UUID, workout: HKWorkout? = nil) {
        self.identifier = identifier
        self.workout = workout
    }
    
    override func start() {
        super.start()
        process()
    }
    
    func process() {
        fetchUpdatedValues { result in
            self.result = result
            self.finish()
        }
    }
    
    func fetchUpdatedValues(completionHandler: @escaping (_ result: WorkoutProcessor.Result) -> Void) {
        Task {
            do {
                let remoteWorkout: HKWorkout
                if let workout = workout {
                    remoteWorkout = workout
                } else {
                    remoteWorkout = try await provider.fetchWorkout(uuid: identifier)
                }
                
                Log.debug("SYNC: processing workout \(identifier)")
                
                let processor = WorkoutProcessor(workout: remoteWorkout)
                await processor.process()
                let result = await processor.result
                completionHandler(result)
            } catch {
                Log.debug("SYNC: failed to fetch remote workout \(identifier): \(error.localizedDescription)")
                completionHandler(WorkoutProcessor.Result.empty)
            }
        }
    }
    
}
