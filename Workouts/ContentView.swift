//
//  ContentView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/6/21.
//

import SwiftUI

struct ContentView: View {
    enum Tabs: String, Identifiable {
        case workouts, log, stats, tags
        var id: String { rawValue }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.managedObjectContext) var viewContext
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var logManager: LogManager
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State private var selected = Tabs.workouts
    
    var body: some View {
        TabView(selection: $selected) {
            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "flame") }
                .tag(Tabs.workouts)

            WorkoutLogView()
                .tabItem { Label("Training", systemImage: "calendar") }
                .tag(Tabs.log)

            StatsView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tabs.stats)

            TagsView()
                .tabItem { Label("Tags", systemImage: "tag") }
                .tag(Tabs.tags)
            
        }
        .onboardingOverlay()
        .noWorkoutsOverlay()
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
        statsManager.refresh()
        logManager.reloadIntervals()
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        //manager.state = .notAvailable
        return manager
    }()
    
    static let logManager = LogManagerPreview.manager(context: viewContext)
    static let statsManager = StatsManagerPreview.manager(context: viewContext)
    static let purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(workoutManager)
            .environmentObject(logManager)
            .environmentObject(statsManager)
            .environmentObject(purchaseManager)
    }
}
