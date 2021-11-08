//
//  WorkoutsApp.swift
//  Workouts
//
//  Created by Axel Rivera on 1/16/21.
//

import SwiftUI

// Don't install Production Debug version on device to prevent from overriding an installed production app
// Can be commented if needed

#if PRODUCTION_DEBUG
#error("preventing debug version from overriding production release")
#endif

let APP_TRANSACTION_AUTHOR_NAME = "workouts_app"

@main
struct WorkoutsApp: App {
    
    let purchaseManager = IAPManager()
    // Instanciate LogManager and StatsManager first because they have observers that may depend from other singletons
    let logManager: LogManager
    let statsManager: StatsManager
    
    let workoutDataStore: WorkoutDataStore
    let storageProvider = StorageProvider()
    let workoutManager: WorkoutManager
    let tagManager: TagManager
    let synchronizer: Synchronizer
    
    init() {
        workoutDataStore = WorkoutDataStore.shared
        logManager = LogManager(context: storageProvider.persistentContainer.viewContext)
        statsManager = StatsManager(context: storageProvider.persistentContainer.viewContext)
        workoutManager = WorkoutManager(context: storageProvider.persistentContainer.viewContext)
        tagManager = TagManager(context: storageProvider.persistentContainer.viewContext)
        
        let backgroundContext = storageProvider.persistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.transactionAuthor = APP_TRANSACTION_AUTHOR_NAME
        
        synchronizer = Synchronizer(context: backgroundContext)
    }
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, storageProvider.persistentContainer.viewContext)
                .environmentObject(workoutManager)
                .environmentObject(logManager)
                .environmentObject(statsManager)
                .environmentObject(purchaseManager)
                .environmentObject(tagManager)
        }
    }
}
