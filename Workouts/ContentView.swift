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
    
    private let memoryNotification = UIApplication.didReceiveMemoryWarningNotification
    private let refreshNotification = Notification.Name.didFinishProcessingRemoteData
    
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
                .tabItem { Label("Home", systemImage: selected == .home ? "house.fill" : "house") }
                .tag(Tabs.home)
            
            StatsView()
                .tabItem { Label("Progress", systemImage: selected == .stats  ? "chart.bar.fill" : "chart.bar") }
                .tag(Tabs.stats)
            
            NavigationView {
                WorkoutsView(sport: $workoutManager.sport, interval: nil, showFilter: true)
                    .navigationTitle("Workouts")
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(Tabs.history)
        }
        .onboardingOverlay()
        .onReceive(NotificationCenter.default.publisher(for: memoryNotification)) { _ in
            viewContext.refreshAllObjects()
        }
        .onReceive(NotificationCenter.default.publisher(for: refreshNotification)) { _ in
            logManager.reloadCurrentInterval()
            reloadIntervalsIfNeeded()
            statsManager.refresh()
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
    
    func reloadIntervalsIfNeeded() {
        if purchaseManager.isActive {
            logManager.reloadIntervals()
        } else {
            withAnimation(.none) {
                logManager.intervals = LogInterval.sampleLastTwelveMonths()
            }
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
