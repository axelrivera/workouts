//
//  WorkoutsProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 7/18/22.
//

import CoreData
import OSLog
import HealthKit
import Polyline

let APP_TRANSACTION_AUTHOR_NAME = "workouts_app"
let WORKOUTS_REMOTE_CONTAINER = "iCloud.me.axelrivera.Workouts"

class WorkoutsProvider {
    let PROCESSING_REFRESH_COUNT = 10
    
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
        
    private init(inMemory: Bool = false) {
        self.inMemory = inMemory
        anchor = AppSettings.workoutsQueryAnchor
        
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
        
    private var lastToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastToken,
                let data = try? NSKeyedArchiver.archivedData( withRootObject: token, requiringSecureCoding: true) else { return }

            do {
                try data.write(to: Self.tokenFile)
            } catch {
                logger.debug("failed to write token data. Error = \(error.localizedDescription)")
            }
        }
    }
    
    lazy var container: NSPersistentContainer = {
        if let tokenData = try? Data(contentsOf: Self.tokenFile) {
            do {
                lastToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
            } catch {
                logger.debug("failed to unarchive history token: \(error.localizedDescription)")
            }
        }
        
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
}

// MARK: - Workouts

extension WorkoutsProvider {
    struct WorkoutTagValue: Hashable {
        let workout: UUID
        let tag: UUID
    }
        
    func fetchWorkouts(regenerate: Bool = false) async throws {
        // context only used for fetching fata in this method
        let fetchContext = newTaskContext()
        
        if regenerate {
            anchor = nil
        }
        
        let (workouts, deleted, newAnchor) = await downloader.fethLatestWorkouts(anchor: anchor)
        
        if deleted.isPresent {
            await deleteWorkouts(with: deleted)
        }
        
        var inserts = Set<HKWorkout>()
        var regenerates = Set<UUID>()
        var tagValues = [WorkoutTagValue]()
                
        for remoteWorkout in workouts {
            if let _ = Workout.find(using: remoteWorkout.uuid, in: fetchContext) {
                if regenerate {
                    regenerates.insert(remoteWorkout.uuid)
                } else {
                    Log.debug("SYNC: skip workout \(remoteWorkout.uuid)")
                }
            } else {
                inserts.insert(remoteWorkout)
                
                let tags = Tag.defaultTags(sport: remoteWorkout.workoutActivityType.sport(), in: fetchContext)
                tags.forEach { tag in
                    let value = WorkoutTagValue(workout: remoteWorkout.uuid, tag: tag)
                    tagValues.append(value)
                }
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
        
        let refreshIds = workouts.map({ $0.uuid })
        WorkoutStorage.reloadWorkouts(for: refreshIds)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didFinishFetchingRemoteData, object: nil)
        }
        
        // reset pending values for workouts marked as regenerate
        await resetPendingValues(with: Array(regenerates))
        let updates = Workout.pendingValues(in: fetchContext)

        if inserts.isPresent || updates.isPresent {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .willBeginProcessingRemoteData, object: nil)
            }
            
            if inserts.isPresent {
                logger.debug("processing inserts")
                let sortedInserts = inserts.sorted { $0.startDate > $1.startDate }
                await processRemoteWorkouts(sortedInserts)
            }
            
            if updates.isPresent {
                logger.debug("processing regenerates")
                
                do {
                    let workoutsToUpdate = try await healthProvider.fetchWorkouts(for: Array(updates))
                    await processRemoteWorkouts(workoutsToUpdate)
                } catch {
                    logger.debug("failed to fetch workouts: \(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didFinishProcessingRemoteData, object: nil)
            }
        }
    }
    
    func resetHeartRateZones() async throws {
        let taskContext = newTaskContext()
        taskContext.name = "updateHRZonesContext"
        taskContext.transactionAuthor = "updateHRZones"
        
        try await taskContext.perform {
            let maxHeartRate = self.healthProvider.maxHeartRate()
            let percents = self.healthProvider.heartRateZonesPercents()
            
            let (value1, value2, value3, value4, value5) = WorkoutProcessor.calculateHeartRateZones(for: percents, maxHeartRate: maxHeartRate)
            let dictionary: [WorkoutSchema: Any] = [
                .zoneValue1: value1,
                .zoneValue2: value2,
                .zoneValue3: value3,
                .zoneValue4: value4,
                .zoneValue5: value5,
                .zoneMaxHeartRate: maxHeartRate
            ]
            
            let request = NSBatchUpdateRequest(entity: Workout.entity())
            request.propertiesToUpdate = dictionary.rawValuesDictionary
            request.resultType = .updatedObjectIDsResultType
            
            let response = try taskContext.execute(request) as? NSBatchUpdateResult
            let objects = response?.result as? [NSManagedObjectID] ?? [NSManagedObjectID]()
            self.mergeChanges(for: .update, objects: objects)
        }
    }
    
}

// MARK: - Processing

extension WorkoutsProvider {
    
    private func importWorkouts(for remoteWorkouts: [HKWorkout]) async throws {
        guard remoteWorkouts.isPresent else { return }
        
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importWorkoutsContext"
        taskContext.transactionAuthor = "importWorkouts"
        
        try await taskContext.perform {
            let request = self.newBatchInsertRequestForWorkouts(remoteWorkouts)
            request.resultType = .objectIDs
            
            let response = try taskContext.execute(request) as? NSBatchInsertResult
            let objects = response?.result as? [NSManagedObjectID] ?? [NSManagedObjectID]()
            self.mergeChanges(for: .insert, objects: objects)
        }
    }
    
    private func importWorkoutTags(for tagValues: [WorkoutTagValue]) async throws {
        guard tagValues.isPresent else { return }
        
        let taskContext = container.viewContext
        try await taskContext.perform {
            let request = self.newBatchInsertRequestForWorkoutTags(tagValues)
            request.resultType = .objectIDs
                        
            let response = try taskContext.execute(request) as? NSBatchInsertResult
            let objects = response?.result as? [NSManagedObjectID] ?? [NSManagedObjectID]()
            self.mergeChanges(for: .insert, objects: objects)
        }
    }
    
    private func resetPendingValues(with identifiers: [UUID]) async {
        let taskContext = newTaskContext()
        taskContext.name = "resetPendingValuesContext"
        taskContext.transactionAuthor = "updateWorkout"
        
        do {
            try await taskContext.perform {
                let dictionary: [WorkoutSchema: Any] = [.valuesUpdated: NSNull()]
                let request = self.newBatchUpdateRequest(for: identifiers, propertiesToUpdate: dictionary.rawValuesDictionary)
                request.resultType = .statusOnlyResultType
                
                try taskContext.execute(request)
            }
        } catch {
            logger.debug("reset pending values failed")
        }
    }
        
    private func processRemoteWorkouts(_ remoteWorkouts: [HKWorkout]) async {
        let taskContext = newTaskContext()
        taskContext.name = "updateContext"
        taskContext.transactionAuthor = "updateWorkout"
        
        let maxHR = healthProvider.maxHeartRate()
        let restingHR = await healthProvider.restingHeartRate()
        let gender = healthProvider.userGender()
        
        let chunked = Array(remoteWorkouts.chunks(ofCount: 5))
        
        var index = 0
        let total = chunked.count
        var updates = [WorkoutIDTuple]()
        
        while index < total {
            let chunk = chunked[index]
            
            do {
                let objects: [WorkoutIDTuple] = try await withThrowingTaskGroup(of: WorkoutIDTuple.self) { group in
                    var objects = [WorkoutIDTuple]()
                    objects.reserveCapacity(chunk.count)
                    
                    for remoteWorkout in chunk {
                        group.addTask {
                            return try await self.processRemoteWorkout(
                                remoteWorkout,
                                maxHR: maxHR,
                                restingHR: restingHR,
                                gender: gender,
                                context: taskContext
                            )
                        }
                    }
                    
                    for try await obj in group {
                        objects.append(obj)
                    }
                    
                    return objects
                }
                
                updates.append(contentsOf: objects)
                
                if updates.count >= PROCESSING_REFRESH_COUNT {
                    processUpdates(updates)
                    updates = [WorkoutIDTuple]()
                }
            } catch {
                logger.debug("processing workout failed: \(error.localizedDescription)")
            }
            
            index += 1
        }
        
        // process any remaining workouts missed in chunk
        processUpdates(updates)
    }
    
    func processUpdates(_ updates: [WorkoutIDTuple]) {
        guard updates.isPresent else { return }
        
        let objects = updates.map({ $0.id })
        let uuids = updates.map({ $0.uuid })
        mergeChanges(for: .update, objects: objects, uuids: uuids)
    }
    
    enum MergeOperation: String, Identifiable {
        case insert, update
        var id: String { rawValue }
        
        var keyValue: String {
            switch self {
            case .insert: return NSInsertedObjectsKey
            case .update: return NSUpdatedObjectsKey
            }
        }
    }
    
    func mergeChanges(for mergeOperation: MergeOperation, objects: [NSManagedObjectID], uuids: [UUID] = []) {
        guard objects.isPresent else { return }
        
        let key = mergeOperation.keyValue
        let viewContext = container.viewContext
        viewContext.perform {
            let changes = [key: objects]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.container.viewContext])
            
            if uuids.isPresent {
                WorkoutStorage.reloadWorkouts(for: uuids)
            }
        }
    }
    
    typealias WorkoutIDTuple = (id: NSManagedObjectID, uuid: UUID)
    
    private func processRemoteWorkout(
        _ remoteWorkout: HKWorkout,
        maxHR: Int,
        restingHR: Int,
        gender: UserGender,
        context: NSManagedObjectContext
    ) async throws -> WorkoutIDTuple {
        let processor = WorkoutProcessor(
            workout: remoteWorkout,
            maxHR: maxHR,
            restingHR: restingHR,
            gender: gender
        )
        await processor.process()
        
        let values = await processor.dictionary
        
        var object: NSManagedObjectID?
        try await context.perform {
            let request = self.newBatchUpdateRequest(for: remoteWorkout.uuid, propertiesToUpdate: values)
            request.resultType = .updatedObjectIDsResultType
            
            let response = try context.execute(request) as? NSBatchUpdateResult
            let objects = response?.result as? [NSManagedObjectID]
            object = objects?.first
        }
        
        if let object = object {
            return (object, remoteWorkout.uuid)
        }
        
        throw WorkoutError("missing object id")
    }
    
    func deleteWorkouts(with ids: [UUID]) async {
        let taskContext = newTaskContext()
        taskContext.name = "deleteWorkoutsContext"
        taskContext.transactionAuthor = "deleteWorkouts"
        
        logger.debug("start deleting workouts: \(ids.count)")
        
        do {
            try await taskContext.perform {
                let dictionary: [WorkoutSchema: Any] = [.markedForDeletionDate: Date()]
                let request = self.newBatchUpdateRequest(for: ids, propertiesToUpdate: dictionary.rawValuesDictionary)
                request.resultType = .updatedObjectIDsResultType
                
                let response = try taskContext.execute(request) as? NSBatchUpdateResult
                let objects = response?.result as? [NSManagedObjectID] ?? [NSManagedObjectID]()
                self.mergeChanges(for: .update, objects: objects)
            }
        } catch {
            logger.debug("failed to delete workouts: \(error.localizedDescription)")
        }
    }
    
}

// MARK: - Batch Requests

extension WorkoutsProvider {
    
    private func newBatchInsertRequestForWorkouts(_ remoteWorkouts: [HKWorkout]) -> NSBatchInsertRequest {
        let now = Date()
        let objects = remoteWorkouts.map { (workout) -> [String: Any] in
            var dict: [WorkoutSchema: Any] = [
                .remoteIdentifier: workout.uuid,
                .sport: workout.workoutActivityType.sport().rawValue,
                .indoor: workout.isIndoor,
                .start: workout.startDate,
                .end: workout.endDate,
                .duration: workout.totalElapsedTime,
                .movingTime: workout.movingTime,
                .distance: workout.totalDistanceValue,
                .avgSpeed: workout.avgSpeedValue,
                .avgMovingSpeed: workout.avgMovingSpeedValue,
                .maxSpeed: workout.maxSpeedValue,
                .avgPace: workout.avgPaceValue,
                .avgMovingPace: workout.avgMovingPaceValue,
                .avgCyclingCadence: workout.avgCyclingCadenceValue,
                .maxCyclingCadence: workout.maxCyclingCadenceValue,
                .elevationAscended: workout.elevationAscendedValue,
                .elevationDescended: workout.elevationDescendedValue,
                .source: workout.sourceRevision.source.name,
                .createdAt: now,
                .updatedAt: now
            ]
            
            if let device = workout.device?.name {
                dict[.device] = device
            }
            
            // these values should be overriden during update
            // but adding them here in case the update fails
            
            dict[.avgHeartRate] = workout.avgHeartRateValue ?? 0
            dict[.maxHeartRate] = workout.maxHeartRateValue ?? 0
            
            if workout.totalEnergyBurnedValue > 0 {
                dict[.energyBurned] = workout.totalEnergyBurnedValue
            } else {
                dict[.energyBurned] = workout.totalCaloriesValue ?? 0
            }
            
            return dict.rawValuesDictionary
        }
        return NSBatchInsertRequest(entity: Workout.entity(), objects: objects)
    }
    
    func newBatchInsertRequestForWorkoutTags(_ tagValues: [WorkoutTagValue]) -> NSBatchInsertRequest {
        let objects = tagValues.map { (value) -> [String: Any] in
            let dict: [WorkoutTagSchema: Any] = [
                .workout: value.workout,
                .tag: value.tag
            ]
            return dict.rawValuesDictionary
        }
        return NSBatchInsertRequest(entity: WorkoutTag.entity(), objects: objects)
    }
    
    func newBatchUpdateRequest(for identifier: UUID, propertiesToUpdate properties: [String: Any]) -> NSBatchUpdateRequest {
        let request = NSBatchUpdateRequest(entity: Workout.entity())
        request.predicate = Workout.predicateForRemoteIdentifier(identifier)
        request.propertiesToUpdate = properties
        return request
    }
    
    func newBatchUpdateRequest(for identifiers: [UUID], propertiesToUpdate properties: [String: Any]) -> NSBatchUpdateRequest {
        let request = NSBatchUpdateRequest(entity: Workout.entity())
        request.predicate = Workout.predicateForIdentifiers(identifiers)
        request.propertiesToUpdate = properties
        return request
    }
    
}

// MARK: Images

extension WorkoutsProvider {
    
    func resetImageData() async throws {
        let taskContext = newTaskContext()
        
        var dictionaries: [NSDictionary] = [NSDictionary]()
        try await taskContext.perform {
            let schema: [WorkoutSchema] = [
                .remoteIdentifier,
                .coordinatesValue,
                .sport,
                .indoor
            ]
            let properties = schema.map { $0.rawValue }
            
            let request = NSFetchRequest<NSDictionary>(entityName: Workout.entityName)
            request.predicate = Workout.notMarkedForLocalDeletionPredicate
            request.resultType = .dictionaryResultType
            request.returnsObjectsAsFaults = false
            request.propertiesToFetch = properties
            
            dictionaries = try taskContext.fetch(request)
        }
        
        for dictionary in dictionaries {
            guard let dict = dictionary as? [String: Any] else { continue }
            
            do {
                try await processImage(dictionary: dict)
            } catch {
                let id = dict[WorkoutSchema.remoteIdentifier.rawValue] ?? "n/a"
                Log.debug("processing image failed \(id): \(error.localizedDescription)")
            }
        }
    }
    
    func processImage(dictionary: [String: Any]) async throws {
        let coordinatesValue = dictionary[WorkoutSchema.coordinatesValue.rawValue] as? String ?? ""
        let coordinates = Polyline(encodedPolyline: coordinatesValue).coordinates ?? []
        
        guard coordinates.isPresent else { return }
        
        guard let identifier = dictionary[WorkoutSchema.remoteIdentifier.rawValue] as? UUID else { return }
        guard let sportValue = dictionary[WorkoutSchema.sport.rawValue] as? String, let sport = Sport(rawValue: sportValue) else { return }
        guard let indoor = dictionary[WorkoutSchema.indoor.rawValue] as? Bool else { return }
        
        if sport.hasDistanceSamples && !indoor {
            Log.debug("resetting workout image for\(identifier)")
            try await WorkoutProcessor.generateAndSaveImageData(for: identifier, coordinates: coordinates)
        } else {
            Log.debug("skip workout image reset for \(identifier)")
        }
    }
    
}

// MARK: Additional Methods

extension WorkoutsProvider {
    
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
        workout.source = "Workouts Preview"
        workout.device = nil
        
        return workout
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
            
            guard let transactions = historyResult?.result as? [NSPersistentHistoryTransaction], !transactions.isEmpty else {
                self.logger.debug("no persistent history transactions found")
                return
            }
            
            self.mergePersistentHistoryChanges(from: transactions)
        }

        logger.debug("finished merging history changes")
    }
    
    private func mergePersistentHistoryChanges(from transactions: [NSPersistentHistoryTransaction]) {
        self.logger.debug("received \(transactions.count) persistent history transactions")
        
        // Update view context with objectIDs from history change request.
        let viewContext = container.viewContext
        viewContext.perform {
            for transaction in transactions {
                viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                self.lastToken = transaction.token
            }
            self.processDuplicates(from: transactions, context: viewContext)
        }
    }
    
    private func refreshAllObjects() {
        let viewContext = container.viewContext
        viewContext.perform {
            viewContext.refreshAllObjects()
        }
    }
    
}

// MARK: - Tag Duplicates

extension WorkoutsProvider {
    
    private func processDuplicates(from transactions: [NSPersistentHistoryTransaction], context: NSManagedObjectContext) {
        var newWorkoutMetaObjects = [NSManagedObjectID]()
        let workoutMetaEntity = WorkoutMetadata.entityName
        
        for transaction in transactions where transaction.changes != nil {
            for change in transaction.changes! where change.changedObjectID.entity.name == workoutMetaEntity && change.changeType == .insert {
                newWorkoutMetaObjects.append(change.changedObjectID)
            }
        }
        
        if newWorkoutMetaObjects.isPresent {
            self.deduplicateAndWait(metaObjectIDs: newWorkoutMetaObjects, context: context)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didFinishProcessingDuplicates, object: self)
            }
        }
    }
    
    private func deduplicateAndWait(metaObjectIDs: [NSManagedObjectID], context: NSManagedObjectContext)  {
        context.performAndWait {
            for objectID in metaObjectIDs {
                self.deduplicate(workoutMeta: objectID, context: context)
            }
            
            do {
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                Log.debug("failed to save deduplicated objects")
            }
        }
    }
    
    private func deduplicate(workoutMeta objectID: NSManagedObjectID, context: NSManagedObjectContext)  {
        guard let workout = context.object(with: objectID) as? WorkoutMetadata else {
            assertionFailure("failed to get valid workout metadata: \(objectID)")
            return
        }
        
        let identifier = workout.identifier
        Log.debug("trying to deduplicate workouts for \(identifier)")
        
        var workouts = WorkoutMetadata.find(using: identifier, in: context)
        if workouts.count > 1 {
            Log.debug("fixing duplicates for: \(identifier)")
            let isFavorite = workouts.filter({ $0.isFavorite }).isPresent
            let first = workouts.removeFirst()
            first.isFavorite = isFavorite
            workouts.forEach({ context.delete($0) })
        } else {
            Log.debug("no duplicates found for \(workout.identifier)")
        }
    }
    
}

extension Notification.Name {
    static let didFinishProcessingDuplicates = Notification.Name("didFinishProcessingDuplicates")
}
