//
//  WorkoutStateModifier.swift
//  Workouts
//
//  Created by Axel Rivera on 8/5/21.
//

import SwiftUI

struct WorkoutStateModifier: ViewModifier {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    func body(content: Content) -> some View {
        content.overlay(overlay())
    }
    
    var notAvailable: Bool {
        let states: [WorkoutManager.State] = [.empty, .notAvailable]
        return states.contains(workoutManager.state)
    }
    
    var showOverlay: Bool {
        notAvailable || workoutManager.isLoading
    }
    
    @ViewBuilder
    func overlay() -> some View {
        if showOverlay {
            if notAvailable {
                ZStack {
                    Color.systemBackground
                        .ignoresSafeArea()
                    WorkoutEmptyView(workoutState: workoutManager.state)
                }
            } else if workoutManager.isLoading {
                ProcessView(title: "Importing Workouts", value: $workoutManager.processingRemoteDataValue)
            }
        }
    }
    
}

extension View {
    
    func workoutStateOverlay() -> some View {
        modifier(WorkoutStateModifier())
    }
    
}
