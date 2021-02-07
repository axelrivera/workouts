//
//  ContentView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/6/21.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        ZStack {
            WorkoutsView()
                .onAppear {
                    workoutManager.fetchRequestStatusForReading()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    workoutManager.fetchRequestStatusForReading()
                }
            
            if workoutManager.shouldRequestReadingAuthorization  {
                Color.systemBackground
                    .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                OnboardingView(action: onboardingAction)
            }
        }
    }
}

extension ContentView {
    
    func onboardingAction() -> Void {
        workoutManager.requestReadingAuthorization { success in
            Log.debug("reading authorization succeeded: \(success)")
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static let workoutManager: WorkoutManager = {
       let manager = WorkoutManager()
        manager.state = .notAvailable
        return manager
    }()
    
    static var previews: some View {
        ContentView()
            .environmentObject(workoutManager)
    }
}
