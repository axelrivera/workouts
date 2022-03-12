//
//  StorageProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 5/27/21.
//

import CoreData
import SwiftUI

class PersistentContainer: NSPersistentCloudKitContainer {}

let WORKOUTS_REMOTE_CONTAINER = "iCloud.me.axelrivera.Workouts"

class StorageProvider: ObservableObject {
    let persistentContainer: PersistentContainer

    init(inMemory: Bool = false) {
        if let tokenData = try? Data(contentsOf: Self.tokenFile) {
            do {
                lastHistoryToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
            } catch {
                print("###\(#function): Failed to unarchive NSPersistentHistoryToken. Error = \(error)")
            }
        }
        
        persistentContainer = PersistentContainer(name: "Workouts")
        
        let defaultSQliteLocation = PersistentContainer.defaultDirectoryURL()
        
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
            cloudDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: WORKOUTS_REMOTE_CONTAINER)
            cloudDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            cloudDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        persistentContainer.persistentStoreDescriptions = [localDescription, cloudDescription]
        
        if inMemory {
            persistentContainer.persistentStoreDescriptions.forEach { description in
                description.shouldInferMappingModelAutomatically = false
                description.shouldMigrateStoreAutomatically = false
            }
        } else {
//            #if DEBUG
//            do {
//                // Use the container to initialize the development schema.
//                try persistentContainer.initializeCloudKitSchema(options: [])
//            } catch {
//                Log.debug("failed to initialize schema: \(error.localizedDescription)")
//                // Handle any errors.
//            }
//            #endif
            
            persistentContainer.persistentStoreDescriptions.forEach { description in
                description.shouldInferMappingModelAutomatically = false
                description.shouldMigrateStoreAutomatically = false
            }
        }
        
        let storeURLs = persistentContainer.persistentStoreDescriptions.compactMap({ $0.url })
        if storeURLs.isEmpty {
            fatalError("missing persistent store url")
        }
        
        for storeURL in storeURLs {
            let migrator = CoreDataMigrator()
            let currentVersion = ModelVersion.current
            if migrator.requiresMigration(at: storeURL, toVersion: currentVersion) {
                switch currentVersion {
                case .v2, .v3, .v4:
                    NSPersistentStoreCoordinator.destroyStore(at: storeURL)
                default:
                    migrator.migrateStore(at: storeURL, toVersion: currentVersion)
                }
            }
        }
        
        persistentContainer.loadPersistentStores(completionHandler: { description, error in
            if let error = error {
                fatalError("Core Data store failed to load with error: \(error), description: \(String(describing: description.configuration))")
            }
        })
        
        persistentContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        persistentContainer.viewContext.transactionAuthor = APP_TRANSACTION_AUTHOR_NAME

        if !inMemory {
            // Pin the viewContext to the current generation token and set it to keep itself up to date with local changes.
            persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
            do {
                try persistentContainer.viewContext.setQueryGenerationFrom(.current)
            } catch {
                fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)")
            }
            
            // Observe Core Data remote change notifications.
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(storeRemoteChange),
                name: .NSPersistentStoreRemoteChange,
                object: persistentContainer.persistentStoreCoordinator
            )
        }
    }
    
    // MARK: History
    
    /**
     Track the last history token processed for a store, and write its value to file.
     
     The historyQueue reads the token when executing operations, and updates it after processing is complete.
     */
    private var lastHistoryToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastHistoryToken,
                let data = try? NSKeyedArchiver.archivedData( withRootObject: token, requiringSecureCoding: true) else { return }
            
            do {
                try data.write(to: Self.tokenFile)
            } catch {
                print("###\(#function): Failed to write token data. Error = \(error)")
            }
        }
    }
    
    /**
     The file URL for persisting the persistent history token.
    */
    private static var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("Workouts", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("###\(#function): Failed to create persistent container URL. Error = \(error)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()
    
    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    static let preview: StorageProvider = {
        let result = StorageProvider(inMemory: true)
        let viewContext = result.persistentContainer.viewContext
        
        for _ in 0 ..< 10 {
            let _ = sampleWorkout(moc: viewContext)
            try! viewContext.save()
        }
        
        for index in 0 ..< 5 {
            let tag = sampleTag(name: "Sample Tag \(index)", color: .accentColor, gear: .none, moc: viewContext)
            tag.position = NSNumber(value: index)
            try! viewContext.save()
        }
        
        return result
    }()
    
    // MARK: - Samples and Previews
    
    static var sampleContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = preview.persistentContainer.viewContext
        return context
    }()
    
    static func sampleWorkout(sport: Sport? = nil, date: Date? = nil, moc context: NSManagedObjectContext? = nil) -> Workout {
        let viewContext = context ?? sampleContext
        
        let start = date ?? Date.dateFor(month: 1, day: 1, year: 2021)!
        let end = start.addingTimeInterval(9000) // 1 hour
        let duration = end.timeIntervalSince(start)
        let avgSpeed = 6.7056
        
        let object = WorkoutProcessor.InsertObject(
            identifier: UUID(),
            sport: sport ?? .cycling,
            indoor: false,
            start: start,
            end: end,
            duration: duration,
            distance: 20000.0,
            movingTime: duration - 300.0,
            avgMovingSpeed: avgSpeed,
            avgSpeed: avgSpeed,
            maxSpeed: avgSpeed + 1.0,
            avgPace: 0.0,
            avgMovingPace: 0.0,
            avgCyclingCadence: 80.0,
            maxCyclingCadence: 90.0,
            energyBurned: 500.0,
            avgHeartRate: 0.0,
            maxHeartRate: 0.0,
            elevationAscended: 0.0,
            elevationDescended: 0.0,
            source: "Workouts Preview",
            device: nil
        )
        
        let workout = Workout(context: viewContext)
        Workout.updateValues(for: workout, object: object, isLocationPending: false, in: viewContext)
        
        return workout
    }
    
    static func sampleTag(name: String, color: Color, gear: Tag.GearType, moc context: NSManagedObjectContext? = nil) -> Tag {
        let viewContext = context ?? sampleContext
        
        let viewModel = Tag.addViewModel()
        viewModel.name = name
        viewModel.color = color
        viewModel.gearType = gear
        
        let tag = Tag.insert(into: viewContext, viewModel: viewModel, position: nil)
        return tag
    }
    
    static func previewTags(in context: NSManagedObjectContext? = nil) -> [Tag] {
        let context = context ?? sampleContext
        
        let request = NSFetchRequest<Tag>(entityName: Tag.entityName)
        request.predicate = Tag.activePredicate()
        request.sortDescriptors = [Tag.sortedByPositionDescriptor()]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
}

extension StorageProvider {
    
    @objc
    func storeRemoteChange(_ notification: Notification) {
        // Process persistent history to merge changes from other coordinators.
        historyQueue.addOperation {
            self.processPersistentHistory()
        }
    }
    
}

// MARK: - Persistent history processing

extension Notification.Name {
    static let didFindRelevantTransactions = Notification.Name("didFindRelevantTransactions")
    static let didFinishProcessingDuplicates = Notification.Name("didFinishProcessingDuplicates")
}

extension StorageProvider {
    
    /**
     Process persistent history, posting any relevant transactions to the current view.
     */
    
    func processPersistentHistory() {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.performAndWait {
            
            // Fetch history received from outside the app since the last token
            let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
            historyFetchRequest.predicate = NSPredicate(format: "author != %@", APP_TRANSACTION_AUTHOR_NAME)
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
            request.fetchRequest = historyFetchRequest

            let result = (try? taskContext.execute(request)) as? NSPersistentHistoryResult
            guard let transactions = result?.result as? [NSPersistentHistoryTransaction],
                  !transactions.isEmpty
                else { return }

            // Post transactions relevant to the current view.
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didFindRelevantTransactions, object: self, userInfo: ["transactions": transactions])
            }
            
            var newWorkoutMetaObjects = [NSManagedObjectID]()
            let workoutMetaEntity = WorkoutMetadata.entityName
            
            for transaction in transactions where transaction.changes != nil {
                for change in transaction.changes! where change.changedObjectID.entity.name == workoutMetaEntity && change.changeType == .insert {
                    newWorkoutMetaObjects.append(change.changedObjectID)
                }
            }
            
            if newWorkoutMetaObjects.isPresent {
                deduplicateAndWait(metaObjectIDs: newWorkoutMetaObjects)
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .didFinishProcessingDuplicates, object: self)
                }
            }
            
            // Update the history token using the last transaction.
            if let token = transactions.last?.token {
                lastHistoryToken = token
            }
        }
    }
    
}

// MARK: - Tags

extension StorageProvider {
    
    private func deduplicateAndWait(metaObjectIDs: [NSManagedObjectID]) {
        let taskContext = persistentContainer.newBackgroundContext()
        
        taskContext.performAndWait {
            for objectID in metaObjectIDs {
                deduplicate(workoutMeta: objectID, context: taskContext)
            }
            
            do {
                try taskContext.save()
            } catch {
                Log.debug("failed to save deduplicated objects")
            }
        }
    }
    
    private func deduplicate(workoutMeta objectID: NSManagedObjectID, context: NSManagedObjectContext) {
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
