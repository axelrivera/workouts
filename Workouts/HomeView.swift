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
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var logManager: LogManager
    @EnvironmentObject var purchaseManager: IAPManager
    
    @FetchRequest<Workout>
    var workouts: FetchedResults<Workout>
    
    @State private var sport: Sport?
    @State private var activeSheet: ActiveSheet?
    @State private var selectedTab = 1
    
    init() {
        _workouts = DataProvider.fetchRequest(sport: nil, interval: DateInterval.lastTwoWeeks())
    }
    
    func header(text: String) -> some View {
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
                Section(header: header(text: "My Workouts")) {
                    NavigationLink(destination: workoutsDestination()) {
                        Label("All Workouts", systemImage: "flame")
                    }
                    
                    Button(action: { activeSheet = .add }) {
                        Label("Import Workouts", systemImage: "square.and.arrow.down")
                    }
                    .disabled(isAddDisabled)
                }
                .textCase(nil)
                
                Section(header: header(text: "Activity")) {
                    VStack(alignment: .leading) {
                        Picker("Display", selection: $logManager.displayType.animation()) {
                            ForEach(LogDisplayType.allCases, id: \.self) { dataType in
                                Text(dataType.rawValue.capitalized)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        VStack {
                            VStack(alignment: .leading) {
                                HStack(alignment: .lastTextBaseline, spacing: 10.0) {
                                    Text("Current Week")
                                        .font(.fixedBody)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(logManager.currentIntervalDisplayLabel)
                                        .animation(.none)
                                        .font(.fixedBody)
                                        .foregroundColor(logManager.displayType.color)
                                }
                                                    
                                WorkoutLogIntervalStack(
                                    displayType: $logManager.displayType,
                                    interval: logManager.currentInterval
                                )
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading) {
                                HStack(alignment: .lastTextBaseline, spacing: 10.0) {
                                    Text("Last Week")
                                        .font(.fixedBody)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(logManager.prevIntervalDisplayLabel)
                                        .animation(.none)
                                        .font(.fixedBody)
                                        .foregroundColor(logManager.displayType.color)
                                }
                                                    
                                WorkoutLogIntervalStack(
                                    displayType: $logManager.displayType,
                                    interval: logManager.prevInterval
                                )
                            }
                        }
                        .padding([.top, .bottom], 5.0)
                        .onAppear { logManager.reloadCurrentInterval() }
                    }
                    .padding([.top], 10.0)
                    
                    NavigationLink(destination: logDestination()) {
                        Label("Workout Log", systemImage: "calendar")
                    }
                }
                .textCase(nil)
                
                Section(header: header(text: "Recent")) {
                    if workouts.isEmpty {
                        Text("You haven't completed any workouts in the past two weeks.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding([.top, .bottom], 20.0)
                    } else {
                        ForEach(workouts) { workout in
                            NavigationLink(destination: DetailView(identifier: workout.remoteIdentifier!)) {
                                HomeMapCell(workout: workout.workoutData())
                            }
                        }
                        .padding([.top, .bottom], 5.0)
                    }
                }
                .textCase(nil)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Home")
            .navigationViewStyle(StackNavigationViewStyle())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { activeSheet = .settings }) {
                       Image(systemName: "gearshape")
                    }
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
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Actions

extension HomeView {
    
    var isAddDisabled: Bool {
        !workoutManager.isDataAvailable || workoutManager.isLoading
    }
    
    func logDestination() -> some View {
        WorkoutLogView()
            .environmentObject(logManager)
            .environmentObject(purchaseManager)
    }
    
    func workoutsDestination() -> some View {
        WorkoutsView(sport: $sport, interval: nil, showFilter: true)
            .navigationBarTitle("Workouts")
    }
    
    func selectDay() -> (_ day: LogDay) -> Void {
        { day in
            Log.debug("selected day: \(day.date), activities: \(day.totalActivities)")
        }
    }
    
}

struct HomeView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManager(context: viewContext)
        manager.state = .ok
        manager.isLoading = false
        return manager
    }()
    
    static var logManager: LogManager = {
        let manager = LogManager(context: viewContext)
        //manager.currentInterval = LogInterval.sampleInterval(moc: viewContext)
        return manager
    }()
    
    static var purchaseManager = IAPManager()
    
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(workoutManager)
            .environmentObject(logManager)
            .environmentObject(purchaseManager)
            .preferredColorScheme(.dark)
    }
}
