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
    
    let displayType: StatsTimelineManager.DisplayType
    
    var body: some View {
        StatsTimelineContentView(
            manager: StatsTimelineManager(displayType: displayType, context: viewContext)
        )
    }
    
}

struct StatsTimelineContentView: View {
    @StateObject var manager: StatsTimelineManager
    @EnvironmentObject var purchaseManager: IAPManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(manager.stats, id: \.id) { stats in
                    NavigationLink(destination: StatsWorkoutsView(identifiers: stats.workouts, title: stats.title)) {
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
        .paywallButtonOverlay()
        .navigationTitle(manager.displayType.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(manager.displayType.title)
                        .font(.system(size: 13.0, weight: .semibold, design: .default))
                    Text(manager.displayType.subtitle)
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
                .disabled(!purchaseManager.isActive)
            }
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
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        return manager
    }()
    
    static var purchaseManager = IAPManagerPreview.manager(isActive: false)
        
    static var previews: some View {
        NavigationView {
            StatsTimelineView(displayType: .yearToDate(sport: .cycling))
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(workoutManager)
        .environmentObject(purchaseManager)
    }
}
