//
//  StorageProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 5/27/21.
//

import CoreData

class PersistentContainer: NSPersistentContainer {}

class StorageProvider: ObservableObject {
    let persistentContainer: PersistentContainer

    init(inMemory: Bool = false) {
        persistentContainer = PersistentContainer(name: "Workouts")
        
        if inMemory {
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            for description in persistentContainer.persistentStoreDescriptions {
                description.shouldInferMappingModelAutomatically = false
                description.shouldMigrateStoreAutomatically = false
            }
            
            guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
                fatalError("missing persistent store url")
            }

            let migrator = CoreDataMigrator()
            let currentVersion = ModelVersion.current
            if migrator.requiresMigration(at: storeURL, toVersion: currentVersion) {
                switch currentVersion {
                case .v2:
                    NSPersistentStoreCoordinator.destroyStore(at: storeURL)
                default:
                    migrator.migrateStore(at: storeURL, toVersion: currentVersion)
                }
            }
        }
        
        persistentContainer.loadPersistentStores(completionHandler: { description, error in
            if let error = error {
                fatalError("Core Data store failed to load with error: \(error)")
            }
        })

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    static let preview: StorageProvider = {
        let result = StorageProvider(inMemory: true)
        let viewContext = result.persistentContainer.viewContext
        
        for _ in 0 ..< 10 {
            let _ = sampleWorkout(moc: viewContext)
            try! viewContext.save()
        }
        
        return result
    }()
    
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
        
        let workout = Workout(context: viewContext)
        workout.remoteIdentifier = UUID()
        workout.sport = sport ?? .cycling
        workout.start = start
        workout.end = end
        workout.duration = duration
        workout.movingTime = duration + 0.5
        workout.distance = 20000.0
        workout.energyBurned = 500.0
        workout.avgSpeed = avgSpeed
        workout.avgMovingSpeed = avgSpeed + 0.5
        workout.maxSpeed = 10.2919
        workout.avgCyclingCadence = 80.0
        workout.maxCyclingCadence = 95.0
        workout.elevationAscended = 500.0
        workout.elevationDescended = 200.0
        workout.locationCity = "Orlando"
        workout.locationState = "FL"
        workout.source = "Workouts Preview"
        
        return workout
    }
}
