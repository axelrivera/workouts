//
//  ContentView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/6/21.
//

import SwiftUI

struct ContentView: View {
    enum Tabs: String {
        case home, stats, goals
    }
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var logManager: LogManager
    @EnvironmentObject var storageProvider: StorageProvider
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var purchaseManager: IAPManager
    @State private var selected = Tabs.home
    
    var body: some View {
        TabView(selection: $selected) {
            HomeView()
                .onAppear {
                    if workoutManager.isProcessingRemoteData { return }
                    workoutManager.fetchRequestStatusForReading(resetAnchor: true)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    reloadData(resetAnchor: true)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    viewContext.batchDeleteObjects()
                    viewContext.refreshAllObjects()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    viewContext.refreshAllObjects()
                }
                .tabItem { Label("Home", systemImage: selected == .home ? "house.fill" : "house") }
                .tag(Tabs.home)
            
            StatsView()
                .onAppear { statsManager.refreshIfNeeded() }
                .tabItem { Label("Progress", systemImage: selected == .stats  ? "chart.bar.fill" : "chart.bar") }
                .tag(Tabs.stats)
            
//                GoalsView()
//                    .tabItem { Label("Goals", systemImage: selected == .goals ? "flag.fill" : "flag") }
//                    .tag(Tabs.goals)
            
//                WorkoutsView()
//                    .tabItem { Label("Workouts", systemImage: selected == .workouts ? "flame.fill" : "flame") }
//                    .tag(Tabs.workouts)
//                    .onAppear { fetchWorkoutsIfNecessary(resetAnchor: false) }
//                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
//                        fetchWorkoutsIfNecessary(resetAnchor: true)
//                    }
//                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
//                        viewContext.batchDeleteObjects()
//                        viewContext.refreshAllObjects()
//                    }
//                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
//                        viewContext.refreshAllObjects()
//                    }
        }
        .onboardingOverlay()
    }
}

extension ContentView {
    
    func reloadData(resetAnchor: Bool) {
        if workoutManager.isProcessingRemoteData { return }
        workoutManager.fetchRequestStatusForReading(resetAnchor: resetAnchor)
        statsManager.refreshIfNeeded()
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    static let workoutManager = WorkoutManager(context: viewContext)
    static let logManager = LogManager(context: viewContext)
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
            .environmentObject(logManager)
            .environmentObject(statsManager)
            .environmentObject(purchaseManager)
    }
}
