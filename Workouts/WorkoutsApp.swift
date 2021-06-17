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

@main
struct WorkoutsApp: App {
    let purchaseManager = IAPManager()
    let workoutDataStore: WorkoutDataStore
    let storageProvider = StorageProvider()
    let workoutManager: WorkoutManager
    let statsManager: StatsManager
    let synchronizer: Synchronizer
    
    init() {
        workoutDataStore = WorkoutDataStore.shared
        workoutManager = WorkoutManager(context: storageProvider.persistentContainer.viewContext)
        statsManager = StatsManager(context: storageProvider.persistentContainer.viewContext)
        
        let backgroundContext = storageProvider.persistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        synchronizer = Synchronizer(context: backgroundContext)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, storageProvider.persistentContainer.viewContext)
                .environmentObject(workoutManager)
                .environmentObject(statsManager)
                .environmentObject(purchaseManager)
        }
    }
}
