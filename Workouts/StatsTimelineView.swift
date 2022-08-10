//
//  StatsTimelineView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/18/21.
//

import SwiftUI
import CoreData

struct StatsTimelineView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    let source: AnalyticsManager.PaywallSource
    let title: String
    let subtitle: String?
    let sport: Sport?
    let interval: DateInterval
    let timeframe: StatsSummary.Timeframe
    let identifiers: [UUID]
    
    var body: some View {
        StatsTimelineContentView(
            source: source,
            title: title,
            subtitle: subtitle,
            manager: manager
        )
    }
    
    var manager: StatsTimelineManager {
        StatsTimelineManager(
            sport: sport,
            interval: interval,
            timeframe: timeframe,
            identifiers: identifiers,
            context: viewContext
        )
    }
    
}

struct StatsTimelineContentView: View {
    let source: AnalyticsManager.PaywallSource
    let title: String
    let subtitle: String?
    @StateObject var manager: StatsTimelineManager
    @EnvironmentObject var purchaseManager: IAPManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(manager.stats, id: \.id) { stats in
                    NavigationLink(destination: activityDestination(stats: stats)) {
                        SummaryCell(viewModel: stats, active: purchaseManager.isActive)
                            .padding([.leading, .trailing])
                            .padding([.top, .bottom], CGFloat(10.0))
                    }
                    .buttonStyle(WorkoutPlainButtonStyle())
                    Divider()
                }
            }
            .onAppear { manager.reload() }
        }
        .overlay(emptyOverlay())
        .paywallButtonOverlay(source: source)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let subtitle = subtitle {
                    VStack {
                        Text(title)
                            .font(.system(size: 13.0, weight: .semibold, design: .default))
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(title)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                if manager.timeframe == .year {
                    EmptyView()
                } else {
                    Menu {
                        Picker(selection: $manager.timeframe) {
                            ForEach(manager.menuOptions, id: \.self) { item in
                                Text(item.menuTitle)
                            }
                        } label: {}
                    } label: {
                        Text(manager.timeframe.menuTitle)
                    }
                    .disabled(purchaseManager.isFreeUser)
                }
            }
        }
    }
    
    @ViewBuilder
    func activityDestination(stats: StatsSummary) -> some View {
        if manager.timeframe == .year {
            StatsTimelineView(
                source: source,
                title: stats.title,
                subtitle: nil,
                sport: manager.sport,
                interval: stats.interval,
                timeframe: .month,
                identifiers: manager.identifiers
            )
        } else {
            StatsWorkoutsView(identifiers: stats.workouts, title: stats.title)
        }
    }
    
    @ViewBuilder
    func emptyOverlay() -> some View {
        if manager.stats.isEmpty {
            Text("No Workouts")
                .foregroundColor(.secondary)
        }
    }
    
}

struct StatsTimelineView_Previews: PreviewProvider {
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        return manager
    }()
    
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
        
    static var previews: some View {
        NavigationView {
            StatsTimelineView(
                source: .progress,
                title: "Timeline Title",
                subtitle: "Subtitle",
                sport: .cycling,
                interval: DateInterval.lastTwelveMonths(),
                timeframe: .year,
                identifiers: []
            )
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(workoutManager)
        .environmentObject(purchaseManager)
    }
}
