//
//  WorkoutLogView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/26/21.
//

import SwiftUI

extension WorkoutLogView {
    
    enum ActiveSheet: Identifiable {
        case filter
        var id: Int { hashValue }
    }
    
}

struct WorkoutLogView: View {
    enum ActiveCoverSheet: Identifiable {
        case settings
        var id: Int { hashValue }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var manager: LogManager
    @EnvironmentObject var purchaseManager: IAPManager

    @State private var activeSheet: ActiveSheet?
    @State private var activeCoverSheet: ActiveCoverSheet?
    
    @ViewBuilder
    func headerView() -> some View {
        if manager.sports.isPresent || manager.dateFilter != .recentMonths {
            HStack {
                Text(manager.filterTitleString)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if manager.sports.isPresent {
                    Text(manager.filterSportString)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding([.leading, .trailing])
            .padding([.top, .bottom], CGFloat(10.0))
            .background(.regularMaterial)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section(header: headerView()) {
                        ForEach(manager.intervals, id: \.id) { interval in
                            WorkoutLogIntervalRow(displayType: $manager.displayType, interval: interval)
                            Divider()
                        }
                    }
                }
                .onAppear { reloadIfNeeded() }
                .onChange(of: purchaseManager.isActive, perform: { isActive in
                    reloadIfNeeded()
                })
            }
            .overlay(emptyOverlay())
            .paywallButtonOverlay(source: .calendar)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeCoverSheet = .settings }) {
                       Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Picker("Display", selection: $manager.displayType.animation()) {
                        ForEach(LogManager.DisplayType.allCases, id: \.self) { dataType in
                            Text(dataType.rawValue.capitalized)
                        }
                    }
                    .onChange(of: manager.displayType, perform: { newValue in
                        AnalyticsManager.shared.capture(.changedCalendarDisplay)
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    .fixedSize()
                    .disabled(!purchaseManager.isActive)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { activeSheet = .filter }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }
                    .disabled(!purchaseManager.isActive)
                }
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .filter:
                    LogFilterView(
                        availableSports: $manager.availableSports,
                        dateFilter: $manager.dateFilter,
                        filterYear: $manager.displayYear,
                        years: $manager.filterYears,
                        sports: $manager.sports
                    )
                }
            }
            .fullScreenCover(item: $activeCoverSheet) { item in
                switch item {
                case .settings:
                    SettingsView()
                        .environmentObject(purchaseManager)
                }
            }
        }
    }
    
    @ViewBuilder
    func emptyOverlay() -> some View {
        if purchaseManager.isActive && manager.intervals.isEmpty {
            Text("No Workouts")
                .foregroundColor(.secondary)
        }
    }
}

extension WorkoutLogView {
    
    func reloadIfNeeded() {
        if purchaseManager.isActive {
            manager.reloadIntervals()
        } else {
            manager.intervals = LogInterval.sampleLastTwelveMonths()
        }
    }
    
}

struct WorkoutLogView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var workoutManager = WorkoutManagerPreview.manager(context: viewContext)
    
    static var manager: LogManager = {
        let manager = LogManagerPreview.manager(context: viewContext)
        //manager.intervals = LogInterval.sampleLastTwelveMonths()
        return manager
    }()
    
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    static var previews: some View {
        WorkoutLogView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(workoutManager)
            .environmentObject(manager)
            .environmentObject(purchaseManager)
    }
}

