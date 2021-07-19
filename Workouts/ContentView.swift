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
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var storageProvider: StorageProvider
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var purchaseManager: IAPManager
    @State private var selected = Tabs.workouts
    
    var body: some View {
        ZStack {
            TabView(selection: $selected) {
                WorkoutsView()
                    .tabItem { Label("Workouts", systemImage: selected == .workouts ? "flame.fill" : "flame") }
                    .tag(Tabs.workouts)
                    .onAppear {
                        fetchWorkoutsIfNecessary(resetAnchor: false)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        fetchWorkoutsIfNecessary(resetAnchor: true)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                        viewContext.batchDeleteObjects()
                        viewContext.refreshAllObjects()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                        viewContext.refreshAllObjects()
                    }
                
                StatsView()
                    .onAppear {
                        fetchSummariesIfNecessary()
                    }
                    .tabItem { Label("Progress", systemImage: selected == .stats  ? "chart.bar.fill" : "chart.bar") }
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
    
    func fetchWorkoutsIfNecessary(resetAnchor: Bool) {
        if !workoutManager.isProcessingRemoteData {
            workoutManager.fetchRequestStatusForReading(resetAnchor: resetAnchor)
        }
    }
    
    func fetchSummariesIfNecessary() {
        if !workoutManager.isProcessingRemoteData {
            statsManager.fetchSummaries()
        }
    }
    
    func onboardingAction() -> Void {
        workoutManager.requestReadingAuthorization { success in
            Log.debug("reading authorization succeeded: \(success)")
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    static let workoutManager = WorkoutManager(context: viewContext)
    static let statsManager = StatsManager(context: viewContext)
    static let purchaseManager = IAPManager.preview(isActive: true)
    
    static var previews: some View {
        ContentView()
            .onAppear(perform: {
                workoutManager.state = .ok
                workoutManager.isLoading = true
                workoutManager.shouldRequestReadingAuthorization = false
            })
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(workoutManager)
            .environmentObject(statsManager)
            .environmentObject(purchaseManager)
    }
}
