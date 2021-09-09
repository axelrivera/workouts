//
//  ContentView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/6/21.
//

import SwiftUI

struct ContentView: View {
    enum Tabs: String, Identifiable {
        case home, history, stats, goals
        var id: String { rawValue }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.managedObjectContext) var viewContext
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var logManager: LogManager
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State private var selected = Tabs.home
    
    var body: some View {
        TabView(selection: $selected) {
            EquatableView(content: HomeView())
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tabs.home)
            
            StatsView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tabs.stats)
            
            WorkoutsView(sport: $workoutManager.sport)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(Tabs.history)
        }
        .onboardingOverlay()
        .onReceive(NotificationCenter.Publisher.memoryPublisher()) { _ in
            viewContext.refreshAllObjects()
        }
        .onReceive(NotificationCenter.Publisher.workoutRefreshPublisher()) { _ in
            reloadData()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                Log.debug("active")
                Task {
                    Log.debug("requesting status")
                    await workoutManager.requestHealthaStatus()
                }
            case .background:
                Log.debug("background")
                viewContext.batchDeleteObjects()
                viewContext.refreshAllObjects()
            case .inactive:
                Log.debug("inactive")
            @unknown default:
                Log.debug("unknown state")
                assertionFailure()
            }
        }
    }
    
}

// MARK: - Methods

extension ContentView {
    
    private func reloadData() {
        logManager.reloadCurrentInterval()
        workoutManager.fetchRecentWorkouts()
        reloadIntervalsIfNeeded()
        statsManager.refresh()
    }
    
    private func reloadIntervalsIfNeeded() {
        if purchaseManager.isActive {
            logManager.reloadIntervals()
        } else {
            logManager.intervals = LogInterval.sampleLastTwelveMonths()
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    static let workoutManager = WorkoutManagerPreview.manager(context: viewContext)
    static let logManager = LogManagerPreview.manager(context: viewContext)
    static let statsManager = StatsManagerPreview.manager(context: viewContext)
    static let purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    static var previews: some View {
        ContentView()
            .environmentObject(workoutManager)
            .environmentObject(logManager)
            .environmentObject(statsManager)
            .environmentObject(purchaseManager)
    }
}
