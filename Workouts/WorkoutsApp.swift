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
    let workoutCache = WorkoutCache.shared
    let tagManager: TagManager
    let synchronizer: Synchronizer
    
    init() {
        let context = storageProvider.persistentContainer.viewContext
        workoutCache.loadProviders(withContext: context)
        workoutDataStore = WorkoutDataStore.shared
        logManager = LogManager(context: context)
        statsManager = StatsManager(context: context)
        workoutManager = WorkoutManager(context: context)
        tagManager = TagManager(context: context)
        
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
