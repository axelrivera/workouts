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
        if workoutManager.shouldRequestReadingAuthorization {
            ZStack {
                Color.systemBackground
                    .ignoresSafeArea()
                OnboardingView {
                    workoutManager.requestReadingAuthorization { success in
                        Log.debug("reading authorization succeeded: \(success)")
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
