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
                    AppSettings.workoutsQueryAnchor = nil
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
                try data.write(to: tokenFile)
            } catch {
                print("###\(#function): Failed to write token data. Error = \(error)")
            }
        }
    }
    
    /**
     The file URL for persisting the persistent history token.
    */
    private lazy var tokenFile: URL = {
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
        
//        for _ in 0 ..< 10 {
//            let _ = sampleWorkout(moc: viewContext)
//            try! viewContext.save()
//        }
//        
//        for index in 0 ..< 5 {
//            let tag = sampleTag(name: "Sample Tag \(index)", color: .accentColor, gear: .none, moc: viewContext)
//            tag.position = NSNumber(value: index)
//            try! viewContext.save()
//        }
        
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
        
        let object = WorkoutProcessor.Object(
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
            avgHeartRate: 140.0,
            maxHeartRate: 170.0,
            coordinatesValue: "",
            elevationAscended: 0.0,
            elevationDescended: 0.0,
            maxElevation: 0.0,
            minElevation: 0.0,
            source: "Workouts Preview",
            device: nil
        )
        
        let workout = Workout(context: viewContext)
        Workout.updateValues(for: workout, object: object, in: viewContext)
        
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

            // Deduplicate the new tags.
            var newTagObjectIDs = [NSManagedObjectID]()
            let tagEntityName = Tag.entity().name

            for transaction in transactions where transaction.changes != nil {
                for change in transaction.changes!
                    where change.changedObjectID.entity.name == tagEntityName && change.changeType == .insert {
                        newTagObjectIDs.append(change.changedObjectID)
                }
            }
            if !newTagObjectIDs.isEmpty {
                deduplicateAndWait(tagObjectIDs: newTagObjectIDs)
            }
            
            // Update the history token using the last transaction.
            lastHistoryToken = transactions.last!.token
        }
    }
}

// MARK: - Deduplicate tags

extension StorageProvider {
    /**
     Deduplicate tags with the same name by processing the persistent history, one tag at a time, on the historyQueue.
     
     All peers should eventually reach the same result with no coordination or communication.
     */
    private func deduplicateAndWait(tagObjectIDs: [NSManagedObjectID]) {
//        // Make any store changes on a background context
//        let taskContext = persistentContainer.backgroundContext()
//
//        // Use performAndWait because each step relies on the sequence. Since historyQueue runs in the background, waiting won’t block the main queue.
//        taskContext.performAndWait {
//            tagObjectIDs.forEach { tagObjectID in
//                deduplicate(tagObjectID: tagObjectID, performingContext: taskContext)
//            }
//            // Save the background context to trigger a notification and merge the result into the viewContext.
//            taskContext.save(with: .deduplicate)
//        }
    }

    /**
     Deduplicate a single tag.
     */
    private func deduplicate(tagObjectID: NSManagedObjectID, performingContext: NSManagedObjectContext) {
//        guard let tag = performingContext.object(with: tagObjectID) as? Tag,
//            let tagName = tag.name else {
//            fatalError("###\(#function): Failed to retrieve a valid tag with ID: \(tagObjectID)")
//        }
//
//        // Fetch all tags with the same name, sorted by uuid
//        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.Tag.uuid.rawValue, ascending: true)]
//        fetchRequest.predicate = NSPredicate(format: "\(Schema.Tag.name.rawValue) == %@", tagName)
//
//        // Return if there are no duplicates.
//        guard var duplicatedTags = try? performingContext.fetch(fetchRequest), duplicatedTags.count > 1 else {
//            return
//        }
//        print("###\(#function): Deduplicating tag with name: \(tagName), count: \(duplicatedTags.count)")
//
//        // Pick the first tag as the winner.
//        let winner = duplicatedTags.first!
//        duplicatedTags.removeFirst()
//        remove(duplicatedTags: duplicatedTags, winner: winner, performingContext: performingContext)
    }
    
    /**
     Remove duplicate tags from their respective posts, replacing them with the winner.
     */
    private func remove(duplicatedTags: [Tag], winner: Tag, performingContext: NSManagedObjectContext) {
//        duplicatedTags.forEach { tag in
//            defer { performingContext.delete(tag) }
//            guard let posts = tag.posts else { return }
//
//            for case let post as Post in posts {
//                if let mutableTags: NSMutableSet = post.tags?.mutableCopy() as? NSMutableSet {
//                    if mutableTags.contains(tag) {
//                        mutableTags.remove(tag)
//                        mutableTags.add(winner)
//                    }
//                }
//            }
//        }
    }
}
