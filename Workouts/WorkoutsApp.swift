//
//  WorkoutsApp.swift
//  Workouts
//
//  Created by Axel Rivera on 1/16/21.
//

import SwiftUI

@main
struct WorkoutsApp: App {
    let workoutManager = WorkoutManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutManager)
        }
    }
}
