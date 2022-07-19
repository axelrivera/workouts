//
//  Synchronizer.swift
//  Workouts
//
//  Created by Axel Rivera on 7/3/22.
//

import Foundation
import CoreData
import HealthKit
import Combine

class Synchronizer {
    let CHUNK_SIZE: Int = 25
    let MAX_OPERATIONS: Int = 1
    
    let context: NSManagedObjectContext
    
    private let storage = SyncronizerStorage()
    private let downloader = WorkoutsDownloader()
    
    private var cancellable: Cancellable?
    
    private lazy var processQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = MAX_OPERATIONS
        return queue
    }()
    
    private lazy var saveQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = MAX_OPERATIONS
        return queue
    }()
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.storage.anchor = AppSettings.workoutsQueryAnchor
        
        cancellable = NotificationCenter.default.publisher(for: .shouldFetchRemoteData).sink { [unowned self] notification in
            fetchRemoteData(withNotification: notification)
        }
    }
    
    deinit {
        cancellable = nil
    }
}

// MARK: Import Workouts

extension Synchronizer {
    
    func fetchRemoteData(withNotification notification: Notification) {
        if let isAuthorized = notification.userInfo?[Notification.isAuthorizedToFetchRemoteDataKey] as? Bool {
            self.storage.isAuthorized = isAuthorized
        }

        // if regenerate is true we want to reset the anchor an fetch all workouts from health kit
        let regenerate = notification.userInfo?[Notification.regenerateDataKey] as? Bool ?? false
        
        let resetAnchor: Bool
        if regenerate {
            resetAnchor = true
        } else {
            resetAnchor = notification.userInfo?[Notification.resetAnchorKey] as? Bool ?? false
        }
        
        self.storage.regenerate = regenerate
        self.storage.resetAnchor = resetAnchor
        
        context.performAndWait {
            fetchLatestWorkouts()
        }
    }
    
    func fetchLatestWorkouts() {
        if storage.resetAnchor {
            storage.anchor = nil
        }
        
        guard storage.isAuthorized else {
            Log.debug("SYNC: not authorized to fetch workouts")
            return
        }
        
        Log.debug("SYNC: fetching remote workouts")
        
        downloader.fetchLatestWorkouts(anchor: storage.anchor) { remoteWorkouts, deleted, newAnchor in
            self.processRemoteWorkouts(remoteWorkouts, deleted: deleted, newAnchor: newAnchor)
        }
    }
    
    typealias WorkoutTagValue = (workout: UUID, tag: UUID)
    
    func processRemoteWorkouts(_ remoteWorkouts: [HKWorkout], deleted: [UUID], newAnchor: HKQueryAnchor?) {
        Log.debug("SYNC: found remote workouts: \(remoteWorkouts.count)")
        
        postNotification(withName: .willBeginProcessingRemoteData)
        
        if deleted.isPresent {
            Log.debug("SYNC: deleting workouts: \(deleted.count)")
            deleteWorkouts(with: deleted)
            context.saveOrRollback()
        }
        
        var inserts = [HKWorkout]()
        var updates = [HKWorkout]()
        var tagValues = [WorkoutTagValue]()
                
        for remoteWorkout in remoteWorkouts {
            if let _ = Workout.find(using: remoteWorkout.uuid, in: context) {
                if storage.regenerate {
                    updates.append(remoteWorkout)
                } else {
                    Log.debug("SYNC: skip workout \(remoteWorkout.uuid)")
                }
            } else {
                inserts.append(remoteWorkout)
                updates.append(remoteWorkout)
                
                let tags = Tag.defaultTags(sport: remoteWorkout.workoutActivityType.sport(), in: context)
                tags.forEach { tagValues.append((remoteWorkout.uuid, $0)) }
            }
        }
        
        insertWorkouts(for: inserts)
        insertWorkoutTags(for: tagValues)
        
        do {
            try context.save()
            storage.anchor = newAnchor
        } catch {
            Log.debug("SYNC: failed to save context: \(error.localizedDescription)")
            context.rollback()
            storage.anchor = nil
        }
        
        postNotification(withName: .didFinishProcessingRemoteData)
        
        let pending = Workout.pendingValues(in: context)
        if updates.isPresent || pending.isPresent {
            updates.forEach { processRemoteWorkout(identifier: $0.uuid, workout: $0) }
            pending.forEach { processRemoteWorkout(identifier: $0) }
        }
    }
    
    func insertWorkouts(for remoteWorkouts: [HKWorkout]) {
        guard remoteWorkouts.isPresent else { return }
        
        for remoteWorkout in remoteWorkouts {
            let workout = Workout(context: context)
            workout.remoteIdentifier = remoteWorkout.uuid
            workout.sport = remoteWorkout.workoutActivityType.sport()
            workout.indoor = remoteWorkout.isIndoor
            workout.start = remoteWorkout.startDate
            workout.end = remoteWorkout.endDate
            workout.duration = remoteWorkout.totalElapsedTime
            workout.movingTime = remoteWorkout.movingTime
            workout.distance = remoteWorkout.totalDistanceValue
            workout.avgSpeed = remoteWorkout.avgSpeedValue
            workout.avgMovingSpeed = remoteWorkout.avgMovingSpeedValue
            workout.maxSpeed = remoteWorkout.maxSpeedValue
            workout.avgPace = remoteWorkout.avgPaceValue
            workout.avgMovingPace = remoteWorkout.avgMovingPaceValue
            workout.avgCyclingCadence = remoteWorkout.avgCyclingCadenceValue
            workout.maxCyclingCadence = remoteWorkout.maxCyclingCadenceValue
            workout.elevationAscended = remoteWorkout.elevationAscendedValue
            workout.elevationDescended = remoteWorkout.elevationDescendedValue
            workout.device = remoteWorkout.device?.name
            workout.source = remoteWorkout.sourceRevision.source.name
            workout.markedForDeletionDate = nil
            
            // these values should be overriden during update
            // but adding them here in case the update fails
            
            workout.avgHeartRate = remoteWorkout.avgHeartRateValue ?? 0
            workout.maxHeartRate = remoteWorkout.maxHeartRateValue ?? 0
            
            if remoteWorkout.totalEnergyBurnedValue > 0 {
                workout.energyBurned = remoteWorkout.totalEnergyBurnedValue
            } else {
                workout.energyBurned = remoteWorkout.totalCaloriesValue ?? 0
            }
        }
    }
    
    func insertWorkoutTags(for tagValues: [WorkoutTagValue]) {
        guard tagValues.isPresent else { return }
        
        for value in tagValues {
            let workoutTag = WorkoutTag(context: context)
            workoutTag.workoutId = value.workout
            workoutTag.tagId = value.tag
        }
    }
        
    func processRemoteWorkout(identifier: UUID, workout: HKWorkout? = nil) {
        Log.debug("SYNC: processing data for workout: \(identifier)")
        
        if storage.isProcessing(workoutID: identifier) {
            Log.debug("SYNC: workout already in queue \(identifier)")
            return
        }
        
        let processOperation = WorkoutProcess(identifier: identifier, workout: workout)
        
        let saveOperation = WorkoutUpdate(viewContext: context)
        saveOperation.addDependency(processOperation)
        
        saveOperation.completionBlock = { [unowned self] in
            self.storage.removeWorkout(withID: identifier)
        }
        
        storage.addWorkout(withID: identifier)

        // inserting save operation first to avoid a race condition
        saveQueue.addOperation(saveOperation)
        processQueue.addOperation(processOperation)
    }
    
    func deleteWorkouts(with ids: [UUID]) {
        let workouts = Workout.fetchWorkoutsWithRemoteIdentifiers(ids, in: context)
        workouts.forEach { $0.markForLocalDeletion() }
    }
    
    func postNotification(withName name: Notification.Name, userInfo: [String: Any]? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
        }
    }
    
}

// MARK: - Notifications

extension Notification.Name {
    
    static var shouldFetchRemoteData = Notification.Name("arn_should_fetch_remote_data")
    static var didInsertRemoteData = Notification.Name("arn_did_insert_remote_data")
    static var willBeginProcessingRemoteData = Notification.Name("arn_will_begin_processing_remote_data")
    static var didFinishProcessingRemoteData = Notification.Name("arn_did_finish_processing_remote_data")
    static var didUpdateWorkoutValues = Notification.Name("arn_did_update_workout_values")
}

extension Notification {
    
    static var isAuthorizedToFetchRemoteDataKey = "arn_is_authorized_to_fetch_remote_data"
    static var remoteWorkoutKey = "arn_remote_workout"
    static var resetAnchorKey = "arn_reset_anchor"
    static var regenerateDataKey = "arn_regenerate_data"
    static var workoutIdentifiersKey = "arn_workout_identifiers"
    
}
