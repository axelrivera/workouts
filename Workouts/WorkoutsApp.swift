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
    // Instanciate LogManager and StatsManager first because they have observers that may depend from other singletons
    let logManager: LogManager
    let statsManager: StatsManager
    
    let workoutsProvider: WorkoutsProvider
    let synchronizer: Synchronizer
    let workoutDataStore: WorkoutDataStore
    let workoutManager: WorkoutManager
    let tagManager: TagManager
    let analytics = AnalyticsManager.shared
    
    init() {
        purchaseManager.reload()
        
        // Reset Query Anchor on Every App Load
        AppSettings.workoutsQueryAnchor = nil
        
        // Workouts Provider
        workoutsProvider = WorkoutsProvider.shared
        let context = workoutsProvider.container.viewContext
        
        // Other Singletons
        synchronizer = Synchronizer(provider: workoutsProvider)
        workoutDataStore = WorkoutDataStore.shared
        logManager = LogManager(context: context)
        statsManager = StatsManager(context: context)
        workoutManager = WorkoutManager(context: context)
        tagManager = TagManager(context: context)
        
        AnalyticsManager.shared.captureInstallOrUpdate()
        AnalyticsManager.shared.captureOpen(isBackground: false, isPro: purchaseManager.isActive)
        
        // Maintenance work should be deleted on next release
        FileManager.deleteOldImageCacheDirectoryIfNeeded()
    }
    
    @SceneBuilder
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, workoutsProvider.container.viewContext)
                .environmentObject(workoutManager)
                .environmentObject(logManager)
                .environmentObject(statsManager)
                .environmentObject(purchaseManager)
                .environmentObject(tagManager)
        }
    }
}
