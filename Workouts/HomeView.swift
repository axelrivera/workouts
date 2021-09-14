//
//  HomeView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/25/21.
//

import SwiftUI
import CoreData

extension HomeView {
    
    enum ActiveSheet: Identifiable {
        case settings, add
        var id: Int { hashValue }
    }
    
}

struct HomeView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var logManager: LogManager
    @EnvironmentObject var purchaseManager: IAPManager
        
    @State private var activeSheet: ActiveSheet?
    
    func sectionHeader(text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top, .bottom])
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: sectionHeader(text: "My Training")) {
                    Picker("Display", selection: $logManager.displayType.animation()) {
                        ForEach(LogDisplayType.allCases, id: \.self) { dataType in
                            Text(dataType.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding([.top, .bottom], CGFloat(5.0))

                    HomeLogRow(
                        displayType: $logManager.displayType,
                        title: "Current Week",
                        supportText: logManager.currentIntervalDisplayLabel,
                        interval: logManager.currentInterval
                    )

                    HomeLogRow(
                        displayType: $logManager.displayType,
                        title: "Last Week",
                        supportText: logManager.prevIntervalDisplayLabel,
                        interval: logManager.prevInterval
                    )

                    NavigationLink(destination: logDestination) {
                        Label("Workout Log", systemImage: "calendar")
                    }
                }
                .onAppear { logManager.reloadCurrentInterval() }
                .textCase(nil)
                
                Section(header: sectionHeader(text: "Recent Workouts")) {
                    if workoutManager.recentWorkouts.isEmpty {
                        Text("You haven't completed any workouts in the past two weeks.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding([.top, .bottom], CGFloat(20.0))
                    } else {
                        ForEach(workoutManager.recentWorkouts) { workout in
                            NavigationLink(destination: detailDestination(viewModel: workout.detailViewModel)) {
                                HomeWorkoutCell(viewModel: workout.cellViewModel)
                            }
                        }
                    }
                }
                .textCase(nil)
            }
            .listStyle(InsetGroupedListStyle())
            .disabled(workoutManager.showImportProgress)
            .overlay(processOverlay())
            .navigationTitle("Home")
            .navigationViewStyle(StackNavigationViewStyle())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeSheet = .settings }) {
                       Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { activeSheet = .add}) {
                        Text("Add Workout")
                    }
                    .disabled(isAddDisabled)
                }
            }
            .fullScreenCover(item: $activeSheet) { item in
                switch item {
                case .settings:
                    SettingsView()
                        .environmentObject(purchaseManager)
                case .add:
                    ImportView()
                        .environmentObject(ImportManager())
                }
            }
        }
    }
    
    @ViewBuilder
    func processOverlay() -> some View {
        if workoutManager.showImportProgress  {
            ZStack {
                Color.systemFill
                    .background(.thinMaterial)
                    .ignoresSafeArea()
                
                ProcessView(
                    title: "Importing Workouts",
                    value: $workoutManager.processingRemoteDataValue
                )
            }
        }
    }
}

// MARK: - Actions

extension HomeView {
    
    var isAddDisabled: Bool {
        !workoutManager.isAuthorized || workoutManager.showImportProgress
    }
    
    func logDestination() -> some View {
        WorkoutLogView()
    }
    
    func detailDestination(viewModel: WorkoutDetailViewModel) -> some View {
        DetailView(detailManager: DetailManager(viewModel: viewModel))
    }
    
}

struct HomeView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        manager.isAuthorized = true
        return manager
    }()
    
    static var logManager: LogManager = {
        let manager = LogManagerPreview.manager(context: viewContext)
//        manager.currentInterval = LogInterval.sampleInterval(moc: viewContext)
//        manager.prevInterval = LogInterval.sampleInterval(moc: viewContext)
        return manager
    }()
    
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    static var previews: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }

        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(workoutManager)
        .environmentObject(logManager)
        .environmentObject(purchaseManager)
        .preferredColorScheme(.dark)
        
    }
}

struct HomeLogRow: View {
    @Binding var displayType: LogDisplayType
    let title: String
    let supportText: String
    let interval: LogInterval
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack(alignment: .lastTextBaseline, spacing: 10.0) {
                    Text(title)
                        .font(.fixedBody)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(supportText)
                        .animation(.none)
                        .font(.fixedBody)
                        .foregroundColor(displayType.color)
                }

                WorkoutLogIntervalStack(
                    displayType: $displayType,
                    interval: interval
                )
            }
        }
    }
    
}
