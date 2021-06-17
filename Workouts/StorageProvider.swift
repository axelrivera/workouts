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
        
//        #if DEBUG
//        if let storeDescription = persistentContainer.persistentStoreDescriptions.first, let url = storeDescription.url {
//            do {
//                try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: storeDescription.type)
//            } catch {
//                Log.debug("failed to reset persistent store: \(error.localizedDescription)")
//            }
//        }
//        #endif
        
        if inMemory {
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        persistentContainer.loadPersistentStores(completionHandler: { description, error in
            if let error = error {
                fatalError("Core Data store failed to load with error: \(error)")
            }
        })

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    func destroy() {
        
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
    
    static func sampleWorkout(moc context: NSManagedObjectContext? = nil) -> Workout {
        let viewContext = context ?? sampleContext
        
        let start = Date.dateFor(month: 1, day: 1, year: 2021)!
        let end = start.addingTimeInterval(3600) // 1 hour
        
        let workout = Workout(context: viewContext)
        workout.remoteIdentifier = UUID()
        workout.sport = .cycling
        workout.start = start
        workout.end = end
        workout.distance = 20000.0
        workout.energyBurned = 500.0
        workout.avgSpeed = 6.7056
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
