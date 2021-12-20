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
    
    let sport: Sport?
    let displayType: StatsTimelineManager.DisplayType
    
    var body: some View {
        StatsTimelineContentView(
            manager: StatsTimelineManager(sport: sport, displayType: displayType, context: viewContext)
        )
    }
    
}

struct StatsTimelineContentView: View {
    @StateObject var manager: StatsTimelineManager
    
    func destination(stats: StatsSummary) -> some View {
        StatsWorkoutsView(sport: manager.sport, interval: stats.interval)
            .navigationTitle(stats.title ?? "Workouts")
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(manager.stats, id: \.id) { stats in
                    NavigationLink(destination: destination(stats: stats)) {
                        SummaryCell(viewModel: stats)
                            .padding([.leading, .trailing])
                            .padding([.top, .bottom], CGFloat(10.0))
                    }
                    .buttonStyle(WorkoutPlainButtonStyle())
                    Divider()
                }
            }
            .onAppear { manager.reload() }
        }
        .navigationTitle(manager.displayType.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(manager.displayType.title)
                        .font(.system(size: 13.0, weight: .semibold, design: .default))
                    Text(manager.sport?.activityName ?? "All Workouts")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(manager.displayType.cases) { item in
                        Button(action: {
                            manager.timeframe = item
                        }, label: {
                            HStack {
                                Text(item.title)
                                if manager.timeframe == item {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        })
                    }
                } label: {
                    Text(manager.timeframe.title)
                }
            }
        }
    }
}

struct StatsTimelineView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        return manager
    }()
    
    static var previews: some View {
        NavigationView {
            StatsTimelineView(sport: .cycling, displayType: .yearToDate)
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(workoutManager)
    }
}
