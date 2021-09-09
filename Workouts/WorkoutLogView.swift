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
    @EnvironmentObject var manager: LogManager
    @EnvironmentObject var purchaseManager: IAPManager

    @State private var activeSheet: ActiveSheet?

    func headerView() -> some View {
        VStack(alignment: .center, spacing: 0) {
            Picker("Display", selection: $manager.displayType.animation()) {
                ForEach(LogManager.DisplayType.allCases, id: \.self) { dataType in
                    Text(dataType.rawValue.capitalized)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Divider()
        }
        .background(.bar)
    }

    var body: some View {
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
        .paywallButtonOverlay()
        .navigationTitle("Workout Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(manager.filterTitleString)
                        .font(.footnote)
                        .foregroundColor(.primary)
                    Text(manager.filterSportString)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing)  {
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
                    dateFilter: $manager.dateFilter,
                    filterYear: $manager.displayYear,
                    years: $manager.filterYears,
                    sports: $manager.sports
                )
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
        NavigationView {
            WorkoutLogView()
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(workoutManager)
        .environmentObject(manager)
        .environmentObject(purchaseManager)
    }
}

