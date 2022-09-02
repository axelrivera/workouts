//
//  ContentView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/6/21.
//

import SwiftUI

struct ContentView: View {
    enum Tabs: String, Identifiable {
        case workouts
        case log
        case stats
        case dashboard
        case tags
        
        var id: String { rawValue }
    }
    
    enum ActiveSheet: Hashable, Identifiable {
        case add(url: URL)
        var id: Self { self }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var logManager: LogManager
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State private var selected = Tabs.workouts
    @State private var activeSheet: ActiveSheet?
    
    private var foregroundPublisher = NotificationCenter.Publisher.foregroundPublisher()
    private var memoryPublisher = NotificationCenter.Publisher.memoryPublisher()
    private var fetchingPublisher = NotificationCenter.Publisher.workoutsFetchNotification()
    private var processingPublisher = NotificationCenter.Publisher.workoutsProcessNotification()
    
    var body: some View {
        TabView(selection: $selected) {
            WorkoutsView()
                .tabItem { Label(NSLocalizedString("Workouts", comment: "Tab"), systemImage: "flame") }
                .tag(Tabs.workouts)

            WorkoutLogView()
                .tabItem { Label(NSLocalizedString("Calendar", comment: "Tab"), systemImage: "calendar") }
                .tag(Tabs.log)

            StatsContainer()
                .tabItem { Label(NSLocalizedString("Progress", comment: "Tab"), systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tabs.stats)
            
            DashboardView()
                .tabItem { Label(NSLocalizedString("Dashboard", comment: "Tab"), systemImage: "rectangle.grid.2x2") }
                .tag(Tabs.dashboard)
            
            TagsView()
                .tabItem { Label(NSLocalizedString("Tags", comment: "Tab"), systemImage: "tag") }
                .tag(Tabs.tags)
        }
        .onOpenURL { url in
            Log.debug("trying to open url: \(url)")
            presentationMode.wrappedValue.dismiss()
            selected = .workouts
            activeSheet = .add(url: url)
        }
        .onboardingOverlay()
        .onReceive(foregroundPublisher) { _ in
            purchaseManager.reload()
            AnalyticsManager.shared.captureOpen(isBackground: true, isPro: purchaseManager.isActive)
        }
        .onReceive(memoryPublisher) { _ in
            viewContext.refreshAllObjects()
            workoutManager.storage.resetAll()
        }
        .onReceive(fetchingPublisher, perform: reloadData)
        .onReceive(processingPublisher, perform: reloadData)
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                Log.debug("active")
                Task {
                    Log.debug("requesting status")
                    await workoutManager.requestHealthStatus()
                }
            case .background:
                Log.debug("background")
                viewContext.batchDeleteObjects()
                viewContext.saveOrRollback()
            case .inactive:
                Log.debug("inactive")
            @unknown default:
                Log.debug("unknown state")
                assertionFailure()
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .add(let url):
                ImportView(fileURL: url)
            }
        }
    }
    
}

// MARK: - Methods

extension ContentView {
    
    private func reloadData(_ notification: Notification) {
        statsManager.refresh()
        logManager.reloadIntervals()
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static let viewContext = WorkoutsProvider.preview.container.viewContext
    
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
