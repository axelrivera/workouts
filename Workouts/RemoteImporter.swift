//
//  RemoteImporter.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import CoreData
import HealthKit

class RemoteImporter {
    static let BATCH_SIZE = 50
    
    private let context: NSManagedObjectContext
    private lazy var downloader = WorkoutsDownloader()
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func importLatestWorkouts(anchor: HKQueryAnchor?, regenerate: Bool) async -> HKQueryAnchor? {
        let (remoteWorkouts, deleted, newAnchor) = await downloader.fethLatestWorkouts(anchor: anchor)
        
        var responseAnchor: HKQueryAnchor? = newAnchor
        let totalWorkouts = remoteWorkouts.count
        
        Log.debug("total workouts: \(totalWorkouts)")
        
        if deleted.isPresent {
            deleteWorkouts(with: deleted, context: context)
            context.saveOrRollback()
        }
        
        if totalWorkouts > 0 {
            let userInfo = [Notification.totalRemoteWorkoutsKey: totalWorkouts]
            NotificationCenter.default.post(
                name: .willBeginProcessingRemoteData,
                object: nil,
                userInfo: userInfo
            )
            
            for remoteWorkout in remoteWorkouts {
                if let workout = Workout.find(using: remoteWorkout.uuid, in: context) {
                    if regenerate {
                        Log.debug("regenerating existing workout: \(remoteWorkout.uuid)")
                        let object = await WorkoutProcessor.object(for: remoteWorkout)
                        Workout.updateValues(for: workout, object: object, in: context)
                    } else {
                        Log.debug("skipping existing workout: \(remoteWorkout.uuid)")
                    }
                } else {
                    Log.debug("inserting workout: \(remoteWorkout.uuid)")
                    let object = await WorkoutProcessor.object(for: remoteWorkout)
                    Workout.insert(into: context, object: object, regenerate: regenerate)
                }
                
                NotificationCenter.default.post(name: .didInsertRemoteData, object: nil)
            }
            
            do {
                try context.save()
            } catch {
                context.rollback()
                responseAnchor = nil
            }
            
            context.refreshAllObjects()
            
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


