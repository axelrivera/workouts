//
//  OnboardingModifier.swift
//  Workouts
//
//  Created by Axel Rivera on 8/5/21.
//

import SwiftUI

struct OnboardingModifier: ViewModifier {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    func body(content: Content) -> some View {
        content.overlay(overlay())
    }
    
    @ViewBuilder
    func overlay() -> some View {
        if workoutManager.isOnboardingVisible {
            ZStack {
                Color.systemBackground
                    .ignoresSafeArea()
                OnboardingView {
                    Task(priority: .userInitiated) {
                        Log.debug("requesting permission")
                        await workoutManager.requestHealthAuthorization()
                    }
                }
            }
        }
    }
    
}

extension View {
    
    func onboardingOverlay() -> some View {
        modifier(OnboardingModifier())
    }
    
}
