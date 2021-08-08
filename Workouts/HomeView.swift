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
        case log, settings, add
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
    
    init() {
        _workouts = DataProvider.fetchRequest(sport: nil, interval: DateInterval.lastTwoWeeks())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    VStack(alignment: .leading) {
                        Picker("Display", selection: $logManager.displayType.animation()) {
                            ForEach(LogDisplayType.allCases, id: \.self) { dataType in
                                Text(dataType.rawValue.capitalized)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.bottom)
                        
                        Text("Current Week")
                            .font(.title)
                            .padding(.bottom, 2.0)
                        HStack(alignment: .lastTextBaseline, spacing: 10.0) {
                            Text(logManager.currentIntervalDateLabel)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(logManager.currentIntervalDisplayLabel)
                                .animation(.none)
                                .foregroundColor(logManager.displayType.color)
                        }
                                            
                        WorkoutLogIntervalStack(
                            displayType: $logManager.displayType,
                            interval: logManager.currentInterval
                        )
                        .onAppear { logManager.reloadCurrentInterval() }
                    }
                    
                    NavigationLink(destination: WorkoutLogView()
                                    .environmentObject(logManager)
                                    .environmentObject(purchaseManager)) {
                        HStack {
                            Label("Workout Log", systemImage: "calendar")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(WorkoutButtonStyle())
                    .padding(.top)
                    
                }
                .padding()
                
                VStack(spacing: 5.0) {
                    HStack {
                        Text("Recent Workouts")
                            .font(.title)
                            .foregroundColor(.primary)
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        if workouts.isPresent {
                            NavigationLink("See All", destination: workoutsDestination())
                        }
                    }
                    .padding([.leading, .trailing])
                    .padding(.bottom, 10.0)
                    
                    if workouts.isEmpty {
                        NavigationLink(destination: workoutsDestination()) {
                            HStack(alignment: .center, spacing: 10.0) {
                                Image(systemName: "flame")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading) {
                                    Text("No Recent Workouts")
                                        .font(.title3)
                                    Text("See All Workouts")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(WorkoutButtonStyle())
                        .padding([.leading, .trailing])
                    } else {
                        ForEach(workouts) { workout in
                            NavigationLink(destination: DetailView(identifier: workout.remoteIdentifier!)) {
                                HStack {
                                    WorkoutCell(workout: workout)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(WorkoutButtonStyle())
                        }
                        .padding([.leading, .trailing])
                    }
                }
                .padding(.bottom)
            }
            .workoutStateOverlay()
            .navigationBarTitle("Home")
            .navigationViewStyle(StackNavigationViewStyle())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeSheet = .add }) {
                       Image(systemName: "plus")
                    }
                    .disabled(isAddDisabled)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { activeSheet = .settings }) {
                       Image(systemName: "gearshape")
                    }
                }
            }
            .fullScreenCover(item: $activeSheet) { item in
                switch item {
                case .log:
                    WorkoutLogView()
                        .environmentObject(logManager)
                        .environmentObject(purchaseManager)
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
        manager.state = .notAvailable
        
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
