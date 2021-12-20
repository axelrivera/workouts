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
    
    func importLatestWorkouts(anchor: HKQueryAnchor?, regenerate: Bool) async -> HKQueryAnchor? {
        if let anchor = anchor {
            Log.debug("fetch latest workouts with anchor: \(anchor)")
        } else {
            Log.debug("fetch latest workouts -- no anchor")
        }
        
        let (remoteWorkouts, deleted, newAnchor) = await downloader.fethLatestWorkouts(anchor: anchor)
        var responseAnchor: HKQueryAnchor? = newAnchor
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .willBeginProcessingRemoteData,
                object: nil
            )
        }
        
        if deleted.isPresent {
            deleteWorkouts(with: deleted, context: context)
            context.saveOrRollback()
        }
        
        for remoteWorkout in remoteWorkouts {
            if let workout = Workout.find(using: remoteWorkout.uuid, in: context) {
                if regenerate {
                    Log.debug("regenerating existing workout: \(remoteWorkout.uuid)")
                    let object = await WorkoutProcessor.insertObject(for: remoteWorkout)
                    Workout.updateValues(for: workout, object: object, isLocationPending: true, in: context)
                } else {
                    Log.debug("skipping existing workout: \(remoteWorkout.uuid)")
                }
            } else {
                Log.debug("inserting workout: \(remoteWorkout.uuid)")
                let object = await WorkoutProcessor.insertObject(for: remoteWorkout)
                Workout.insert(into: context, object: object)
                
                let tags = Tag.defaultTags(sport: object.sport, in: context)
                tags.forEach { tag in
                    WorkoutTag.insert(into: context, workout: object.identifier, tag: tag)
                }
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didInsertRemoteData, object: nil)
            }
        } 
        
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            context.rollback()
            responseAnchor = nil
        }
        
        context.refreshAllObjects()
                
        DispatchQueue.main.async {
            Log.debug("LOG - send finish processing remote data notification")
            NotificationCenter.default.post(
                name: .didFinishProcessingRemoteData,
                object: nil
            )
        }
        
        return responseAnchor
    }
    
}

extension RemoteImporter {
    
    fileprivate func deleteWorkouts(with ids: [UUID], context: NSManagedObjectContext) {
        let workouts = Workout.fetchWorkoutsWithRemoteIdentifiers(ids, in: context)
        workouts.forEach { $0.markForLocalDeletion() }
    }
    
}


