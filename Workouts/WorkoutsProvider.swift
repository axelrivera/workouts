//
//  WorkoutsProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 7/18/22.
//

import CoreData
import OSLog
import HealthKit

let APP_TRANSACTION_AUTHOR_NAME = "workouts_app"
let WORKOUTS_REMOTE_CONTAINER = "iCloud.me.axelrivera.Workouts"

class WorkoutsProvider {
    let logger = Logger(subsystem: "me.axelrivera.Workouts", category: "persistence")
    
    static let shared = WorkoutsProvider()
    
    static let preview: WorkoutsProvider = {
        let provider = WorkoutsProvider(inMemory: true)
        return provider
    }()
    
    static let sampleContext: NSManagedObjectContext = {
        preview.container.viewContext
    }()
    
    private let inMemory: Bool
    private var notificationToken: NSObjectProtocol?
    
    private let downloader = WorkoutsDownloader()
    private let healthProvider = HealthProvider.shared
    
    private var anchor: HKQueryAnchor? {
        didSet {
            AppSettings.workoutsQueryAnchor = anchor
        }
    }
    
    private var regenerate = false
    
    private init(inMemory: Bool = false) {
        self.inMemory = inMemory
        self.anchor = AppSettings.workoutsQueryAnchor
        
        // Observe Core Data remote change notifications on the queue where the changes were made.
        notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil) { note in
            self.logger.debug("received a persistent store remote change notification")
            Task {
                await self.fetchPersistentHistory()
            }
        }
    }
    
    deinit {
        if let observer = notificationToken {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private var lastToken: NSPersistentHistoryToken?
    
//    private var lastToken: NSPersistentHistoryToken? = nil {
//        didSet {
//            guard let token = lastToken,
//                let data = try? NSKeyedArchiver.archivedData( withRootObject: token, requiringSecureCoding: true) else { return }
//
//            do {
//                try data.write(to: Self.tokenFile)
//            } catch {
//                logger.debug("failed to write token data. Error = \(error.localizedDescription)")
//            }
//        }
//    }
    
    lazy var container: NSPersistentContainer = {
//        if let tokenData = try? Data(contentsOf: Self.tokenFile) {
//            do {
//                lastToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
//            } catch {
//                logger.debug("failed to unarchive history token: \(error.localizedDescription)")
//            }
//        }
        
        let container = NSPersistentContainer(name: "Workouts")
        
        let defaultSQliteLocation = NSPersistentCloudKitContainer.defaultDirectoryURL()
        
        let localStoreURL = defaultSQliteLocation.appendingPathComponent("Local.sqlite")
        let localDescription = NSPersistentStoreDescription(url: localStoreURL)
        localDescription.configuration = "Local"
        
        let cloudStoreURL = defaultSQliteLocation.appendingPathComponent("Cloud.sqlite")
        let cloudDescription = NSPersistentStoreDescription(url: cloudStoreURL)
        cloudDescription.configuration = "Cloud"
        
        if inMemory {
            localDescription.type = NSInMemoryStoreType
            cloudDescription.type = NSInMemoryStoreType
        } else {
            // Local
//            localDescription.setOption(
//                true as NSNumber,
//                forKey: NSPersistentHistoryTrackingKey
//            )
//            localDescription.setOption(
//                true as NSNumber,
//                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
//            )
            
            // Cloud
            cloudDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: WORKOUTS_REMOTE_CONTAINER
            )
            cloudDescription.setOption(
                true as NSNumber,
                forKey: NSPersistentHistoryTrackingKey
            )
            cloudDescription.setOption(
                true as NSNumber,
                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
            )
        }
        
        container.persistentStoreDescriptions = [localDescription, cloudDescription]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("core data store failed to load with error: \(error), description: \(String(describing: description.configuration))")
            }
        }
        
        // Provider refreshes UI by consuming store changes via persistent history tracking.
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.name = "viewContext"
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        
        return container
    }()
    
    private func newTaskContext() -> NSManagedObjectContext {
        let taskContext = container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
    
    static func sampleWorkout(sport: Sport? = nil, date: Date? = nil, moc context: NSManagedObjectContext? = nil) -> Workout {
        let viewContext = context ?? sampleContext

        let start = date ?? Date.dateFor(month: 1, day: 1, year: 2021)!
        let end = start.addingTimeInterval(9000) // 1 hour
        let duration = end.timeIntervalSince(start)
        
        let workout = Workout(context: viewContext)
        workout.remoteIdentifier = UUID()
        workout.sport = sport ?? .cycling
        workout.indoor = false
        workout.start = start
        workout.end = end
        workout.duration = duration
        workout.valuesUpdated = Date()
        workout.locationUpdated = Date()
        workout.source = "Workouts Preview"
        workout.device = nil
        
        return workout
    }
}

// MARK: - Workouts

extension WorkoutsProvider {
    typealias WorkoutTagValue = (workout: UUID, tag: UUID)
    
    func fetchWorkouts(regenerate: Bool = false) async throws {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .willBeginProcessingRemoteData, object: nil)
        }
        
        let (workouts, deleted, newAnchor) = await downloader.fethLatestWorkouts(anchor: anchor)
        
        if deleted.isPresent {
            deleteWorkouts(with: deleted)
        }
        
        var inserts = Set<HKWorkout>()
        var updates = Set<HKWorkout>()
        var updateIds = Set<UUID>()
        var tagValues = [WorkoutTagValue]()
                
        for remoteWorkout in workouts {
            if let _ = Workout.find(using: remoteWorkout.uuid, in: container.viewContext) {
                if regenerate {
                    updates.insert(remoteWorkout)
                    updateIds.insert(remoteWorkout.uuid)
                } else {
                    Log.debug("SYNC: skip workout \(remoteWorkout.uuid)")
                }
            } else {
                inserts.insert(remoteWorkout)
                updates.insert(remoteWorkout)
                updateIds.insert(remoteWorkout.uuid)
                
                let tags = Tag.defaultTags(sport: remoteWorkout.workoutActivityType.sport(), in: container.viewContext)
                tags.forEach { tagValues.append((remoteWorkout.uuid, $0)) }
            }
        }
        
        do {
            try await importWorkouts(for: Array(inserts))
            try await importWorkoutTags(for: tagValues)
            anchor = newAnchor
        } catch {
            anchor = nil
            throw error
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didFinishProcessingRemoteData, object: nil)
        }
        
        let allPending = Set(Workout.pendingValues(in: container.viewContext))
        let pending = allPending.subtracting(updateIds)
        if pending.isPresent {
            let pendingWorkouts = (try? await healthProvider.fetchWorkouts(for: Array(pending))) ?? [HKWorkout]()
            pendingWorkouts.forEach { updates.insert($0) }
        }

        if updates.isPresent {
            await processRemoteWorkouts(Array(updates))
        }
    }
    
    private func importWorkouts(for remoteWorkouts: [HKWorkout]) async throws {
        guard remoteWorkouts.isPresent else { return }
        
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importWorkoutsContext"
        taskContext.transactionAuthor = "importWorkouts"
        
        try await taskContext.perform {
            let request = self.newBatchInsertRequest(for: remoteWorkouts)
            request.resultType = .objectIDs
            
            let response = try taskContext.execute(request) as? NSBatchInsertResult
            let objects = response?.result as? [NSManagedObjectID] ?? [NSManagedObjectID]()
            self.mergeChanges(for: NSInsertedObjectsKey, objects: objects)
        }
    }
    
    private func importWorkoutTags(for tagValues: [WorkoutTagValue]) async throws {
        guard tagValues.isPresent else { return }
        
        let taskContext = newTaskContext()
        taskContext.name = "importWorkoutTagsContext"
        taskContext.transactionAuthor = "importWorkoutTags"
        
        try await taskContext.perform {
            let request = self.newBatchInsertRequest(for: tagValues)
            try taskContext.execute(request)
            
            let response = try taskContext.execute(request) as? NSBatchInsertResult
            let objects = response?.result as? [NSManagedObjectID] ?? [NSManagedObjectID]()
            self.mergeChanges(for: NSInsertedObjectsKey, objects: objects)
        }
    }
        
    private func processRemoteWorkouts(_ remoteWorkouts: [HKWorkout]) async {
        let taskContext = newTaskContext()
        taskContext.name = "updateContext"
        taskContext.transactionAuthor = "updateWorkout"
        
        let chunked = Array(remoteWorkouts.chunks(ofCount: 5))
        
        var index = 0
        let total = chunked.count
        var updates = [NSManagedObjectID]()
        
        while index < total {
            let chunk = chunked[index]
            
            do {
                let objects: [NSManagedObjectID] = try await withThrowingTaskGroup(of: NSManagedObjectID.self) { group in
                    var objects = [NSManagedObjectID]()
                    objects.reserveCapacity(chunk.count)
                    
                    for remoteWorkout in chunk {
                        group.addTask {
                            return try await self.processRemoteWorkout(remoteWorkout, context: taskContext)
                        }
                    }
                    
                    for try await obj in group {
                        objects.append(obj)
                    }
                    
                    return objects
                }
                
                updates.append(contentsOf: objects)
                
                if updates.count >= 25 {
                    mergeChanges(for: NSUpdatedObjectsKey, objects: updates)
                    updates = [NSManagedObjectID]()
                }
            } catch {
                logger.debug("processing workout failed: \(error.localizedDescription)")
            }
            
            index += 1
        }
        
        mergeChanges(for: NSUpdatedObjectsKey, objects: updates)
    }
    
    func mergeChanges(for key: String, objects: [NSManagedObjectID]) {
        guard objects.isPresent else { return }
        
        let viewContext = container.viewContext
        viewContext.perform {
            let changes = [key: objects]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.container.viewContext])
        }
    }
    
    private func processRemoteWorkout(_ remoteWorkout: HKWorkout, context: NSManagedObjectContext) async throws -> NSManagedObjectID {
        let processor = WorkoutProcessor(workout: remoteWorkout)
        await processor.process()
        
        let values = await processor.dictionary
        
        var object: NSManagedObjectID?
        try await context.perform {
            let request = self.newBatchUpdateRequest(for: remoteWorkout.uuid, values: values)
            request.resultType = .updatedObjectIDsResultType
            
            let response = try context.execute(request) as? NSBatchUpdateResult
            let objects = response?.result as? [NSManagedObjectID]
            object = objects?.first
        }
        
        if let object = object {
            return object
        }
        
        throw WorkoutError("missing object id")
    }
    
    private func newBatchInsertRequest(for remoteWorkouts: [HKWorkout]) -> NSBatchInsertRequest {
        var index = 0
        let total = remoteWorkouts.count
        
        let request = NSBatchInsertRequest(entity: Workout.entity()) { (object: NSManagedObject) -> Bool in
            guard index < total else { return true }
            
            let remoteWorkout = remoteWorkouts[index]
            if let workout = object as? Workout {
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
            
            index += 1
            return false
        }
        return request
    }
    
    func newBatchInsertRequest(for tagValues: [WorkoutTagValue]) -> NSBatchInsertRequest {
        var index = 0
        let total = tagValues.count
        
        let request = NSBatchInsertRequest(entity: WorkoutTag.entity()) { (object: NSManagedObject) -> Bool in
            guard index < total else { return true }
            
            let value = tagValues[index]
            if let workoutTag = object as? WorkoutTag {
                workoutTag.workoutId = value.workout
                workoutTag.tagId = value.tag
            }
            
            index += 1
            return false
        }
        return request
    }
    
    func newBatchUpdateRequest(for identifier: UUID, values: [String: Any]) -> NSBatchUpdateRequest {
        let request = NSBatchUpdateRequest(entity: Workout.entity())
        request.predicate = Workout.predicateForRemoteIdentifier(identifier)
        request.propertiesToUpdate = values
        return request
    }
    
    func deleteWorkouts(with ids: [UUID]) {
        let context = container.viewContext
        
        logger.debug("start deleting workouts: \(ids.count)")
        context.perform {
            let workouts = Workout.fetchWorkoutsWithRemoteIdentifiers(ids, in: context)
            workouts.forEach { $0.markForLocalDeletion() }
        }
        logger.debug("finished deleting workouts")
    }
    
}

// MARK: - History

extension WorkoutsProvider {
    
    private static var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("Workouts", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Log.debug("failed to create persistent container URL. error = \(error.localizedDescription)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()
    
    func fetchPersistentHistory() async {
        do {
            try await fetchPersistentHistoryTransactionsAndChanges()
        } catch {
            logger.debug("\(error.localizedDescription)")
        }
    }
    
    private func fetchPersistentHistoryTransactionsAndChanges() async throws {
        let taskContext = newTaskContext()
        taskContext.name = "persistentHistoryContext"
        
        logger.debug("start fetching persistent history changes from the store...")

        try await taskContext.perform {
            // Execute the persistent history change since the last transaction.
            let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
            let historyResult = try taskContext.execute(changeRequest) as? NSPersistentHistoryResult
            if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
               !history.isEmpty {
                self.mergePersistentHistoryChanges(from: history)
            } else {
                self.logger.debug("no persistent history transactions found")
            }
        }

        logger.debug("finished merging history changes")
    }
    
    private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
        self.logger.debug("received \(history.count) persistent history transactions")
        
        // Update view context with objectIDs from history change request.
        let viewContext = container.viewContext
        viewContext.perform {
            for transaction in history {
            
                // transaction source details
                let context = transaction.contextName ?? "unknown context"
                let author = transaction.author ?? "unknown author"
                
                self.logger.debug("transaction - context: \(context), author: \(author)")
                
                viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                self.lastToken = transaction.token
            }
        }
    }
    
}
