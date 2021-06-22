//
//  RemoteImporter.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import CoreData
import HealthKit

class RemoteImporter {
    static let BATCH_SIZE = 25
    
    private let context: NSManagedObjectContext
    private lazy var downloader = WorkoutsDownloader()
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func importLatestWorkouts(anchor: HKQueryAnchor?, regenerate: Bool, completion: @escaping (_ newAnchor: HKQueryAnchor?) -> Void) {
        downloader.fetchLatestWorkouts(anchor: anchor) { [unowned self] workouts, deleted, newAnchor in
            self.context.perform { [unowned self] in
                var responseAnchor: HKQueryAnchor? = newAnchor
                
                let totalWorkouts = workouts.count
                DispatchQueue.main.async {
                    let userInfo = [Notification.totalRemoteWorkoutsKey: totalWorkouts]
                    NotificationCenter.default.post(
                        name: .willBeginProcessingRemoteData,
                        object: nil,
                        userInfo: userInfo
                    )
                }
                
                let workoutChunks = workouts.sliced(size: Self.BATCH_SIZE)
                for chunk in workoutChunks {
                    self.insert(chunk, regenerate: regenerate)
                    
                    do {
                        try context.save()
                    } catch {
                        context.rollback()
                        responseAnchor = nil
                    }
                    context.refreshAllObjects()
                }
                
                self.deleteWorkouts(with: deleted)
                
                do {
                    try context.save()
                } catch {
                    context.rollback()
                    responseAnchor = nil
                }
                
                context.refreshAllObjects()
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .didFinishProcessingRemoteData,
                        object: nil
                    )
                }
                completion(responseAnchor)
            }
        }
    }
    
}

extension RemoteImporter {
    
    fileprivate func insert(_ remoteWorkouts: [HKWorkout], regenerate: Bool) {
        for remoteWorkout in remoteWorkouts {
            Workout.insert(into: context, remoteWorkout: remoteWorkout, regenerate: regenerate)
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didInsertRemoteData, object: nil)
            }
        }
    }
    
    fileprivate func deleteWorkouts(with ids: [UUID]) {
        if ids.isEmpty { return }
        
        let workouts = Workout.fetchWorkoutsWithRemoteIdentifiers(ids, in: context)
        workouts.forEach { $0.markForLocalDeletion() }
    }
    
}


