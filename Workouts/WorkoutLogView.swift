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
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var manager: LogManager
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State private var activeSheet: ActiveSheet?
    
    @State private var selectedIdentifiers: [UUID]?
    @State private var isWorkoutDetailShowing = false
    @State private var isWorkoutsViewShowing = false
    
    let columns = Array(repeating:  GridItem(.flexible(), spacing: 0), count: 7)
    
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
        .background(.regularMaterial)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section(header: headerView()) {
                    ForEach(manager.intervals, id: \.self) { interval in
                        WorkoutLogIntervalRow(displayType: $manager.displayType, interval: interval)
                        Divider()
                    }
                }
            }
            .onAppear {
                reloadIntervalsIfNeeded()
            }
            .onChange(of: purchaseManager.isActive, perform: { isActive in
                reloadIntervalsIfNeeded()
            })
        }
        .paywallOverlay()
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
}

extension WorkoutLogView {
    
    func reloadIntervalsIfNeeded() {
        if purchaseManager.isActive {
            manager.reloadIntervals()
        } else {
            withAnimation(.none) {
                manager.intervals = LogInterval.sampleLastTwelveMonths()
            }
        }
    }
    
}

struct WorkoutLogView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static var manager: LogManager = {
        let manager = LogManager(context: viewContext)
        manager.intervals = LogInterval.sampleLastTwelveMonths()
        return manager
    }()
    
    static var previews: some View {
        NavigationView {
            WorkoutLogView()
                .environmentObject(manager)
                .environmentObject(IAPManager())
        }
        .preferredColorScheme(.dark)
    }
}

