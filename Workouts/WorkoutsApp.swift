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
    let workoutManager = WorkoutManager()
    let purchaseManager = IAPManager()
    
    let storageProvider = StorageProvider()
    let synchronizer: Synchronizer
    
    init() {
        let context = storageProvider.persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        synchronizer = Synchronizer(context: context)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, storageProvider.persistentContainer.viewContext)
                .environmentObject(workoutManager)
                .environmentObject(purchaseManager)
        }
    }
}
