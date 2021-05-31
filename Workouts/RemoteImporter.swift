//
//  RemoteImporter.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import CoreData
import HealthKit

class RemoteImporter {
    private let context: NSManagedObjectContext
    private lazy var downloader = WorkoutsDownloader()
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func importLatestWorkouts() {
        downloader.fetchLatestWorkouts { [unowned self] workouts, deleted in
            self.context.perform { [unowned self] in
                let workoutChunks = workouts.sliced(size: 5)
                for chunk in workoutChunks {
                    self.insert(chunk)
                    context.saveOrRollback()
                }
                
                self.deleteWorkouts(with: deleted)
                context.saveOrRollback()
                context.refreshAllObjects()
            }
        }
    }
    
}

extension RemoteImporter {
    
    fileprivate func insert(_ remoteWorkouts: [HKWorkout]) {
        let existingWorkouts = { () -> [UUID: Workout] in
            let ids = remoteWorkouts.map { $0.uuid }
            let workouts = Workout.fetchWorkoutsWithRemoteIdentifiers(ids, in: self.context)
            
            var result: [UUID: Workout] = [:]
            for workout in workouts {
                result[workout.remoteIdentifier!] = workout
            }
            return result
        }()
        
        for remoteWorkout in remoteWorkouts {
            guard existingWorkouts[remoteWorkout.uuid] == nil else { continue }
            Workout.insert(into: context, remoteWorkout: remoteWorkout)
        }
    }
    
    fileprivate func deleteWorkouts(with ids: [UUID]) {
        if ids.isEmpty { return }
        
        let workouts = Workout.fetchWorkoutsWithRemoteIdentifiers(ids, in: context)
        workouts.forEach { $0.markForLocalDeletion() }
    }
    
}


