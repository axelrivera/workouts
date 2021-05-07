//
//  ContentView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/6/21.
//

import SwiftUI

struct ContentView: View {
    enum Tabs: Int {
        case workouts, stats, settings
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    @State private var selected = Tabs.workouts
    
    var body: some View {
        ZStack {
            TabView(selection: $selected) {
                WorkoutsView()
                    .tabItem { Label("Workouts", systemImage: selected == .workouts ? "flame.fill" : "flame") }
                    .tag(Tabs.workouts)
                    .onAppear {
                        workoutManager.fetchRequestStatusForReading()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        workoutManager.fetchRequestStatusForReading()
                    }
                
                StatsView()
                    .tabItem { Label("Statistics", systemImage: selected == .stats  ? "chart.bar.fill" : "chart.bar") }
                    .tag(Tabs.stats)
                
                SettingsView()
                    .tabItem { Label("Settings", systemImage: selected == .settings ? "gearshape.fill" : "gearshape") }
                    .tag(Tabs.settings)
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
    static let workoutManager = WorkoutManager()
    
    static var previews: some View {
        ContentView()
            .onAppear(perform: {
                workoutManager.workouts = WorkoutManager.sampleWorkouts()
                workoutManager.state = .ok
                workoutManager.shouldRequestReadingAuthorization = false
            })
            .environmentObject(workoutManager)
            .environmentObject(IAPManager())
    }
}
