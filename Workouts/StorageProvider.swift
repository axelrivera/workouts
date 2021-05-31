//
//  StorageProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 5/27/21.
//

import CoreData

class PersistentContainer: NSPersistentContainer {}

class StorageProvider {
    let persistentContainer: PersistentContainer

    init(inMemory: Bool = false) {
        persistentContainer = PersistentContainer(name: "Workouts")
        
        #if DEBUG
        if let storeDescription = persistentContainer.persistentStoreDescriptions.first, let url = storeDescription.url {
            do {
                try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: storeDescription.type)
            } catch {
                Log.debug("failed to reset persistent store: \(error.localizedDescription)")
            }
        }
        #endif
        
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
    
    static let preview: StorageProvider = {
        let result = StorageProvider(inMemory: true)
        let viewContext = result.persistentContainer.viewContext
        
        let start = Date.dateFor(month: 1, day: 1, year: 2021)!
        let end = start.addingTimeInterval(3600) // 1 hour
        
        for _ in 0 ..< 10 {
            let newWorkout = Workout(context: viewContext)
            newWorkout.remoteIdentifier = UUID()
            newWorkout.sport = .cycling
            newWorkout.start = start
            newWorkout.end = end
            newWorkout.distance = 20000.0
            newWorkout.energyBurned = 500.0
            newWorkout.avgSpeed = 6.7056
            newWorkout.maxSpeed = 10.2919
            newWorkout.avgCyclingCadence = 80.0
            newWorkout.maxCyclingCadence = 95.0
            newWorkout.elevationAscended = 500.0
            newWorkout.elevationDescended = 200.0
            newWorkout.source = "Workouts Preview"
            
            try! viewContext.save()
        }
        
        return result
    }()
}
