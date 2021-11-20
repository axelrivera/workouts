//
//  WorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI
import CoreData

struct WorkoutsView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        WorkoutsContentView(filterManager: WorkoutsFilterManager(context: viewContext))
    }
}

struct WorkoutsContentView: View {
    enum ActiveCoverSheet: Identifiable {
        case settings
        var id: Int { hashValue }
    }
    
    enum ActiveSheet: Hashable, Identifiable {
        case filter
        case tags(identifier: UUID, sport: Sport)
        var id: Self { self }
    }
    
    @Environment(\.managedObjectContext) var viewContext
    @StateObject var filterManager: WorkoutsFilterManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    
    var fetchRequest: FetchRequest<Workout>
    var workouts: FetchedResults<Workout> { fetchRequest.wrappedValue }
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeCoverSheet: ActiveCoverSheet?
    @State private var selectedWorkout: UUID?
        
    init(filterManager: WorkoutsFilterManager) {
        _filterManager = StateObject(wrappedValue: filterManager)
        fetchRequest = DataProvider.fetchFetquest(for: filterManager.filterPredicate())
    }
    
    func detailDestination(viewModel: WorkoutDetailViewModel) -> some View {
        DetailView(detailManager: DetailManager(viewModel: viewModel, context: viewContext))
    }
    
    var filterImageName: String {
        filterManager.isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
    }
    
    func isFavorite(_ identifier: UUID) -> Bool {
        WorkoutCache.shared.isFavorite(identifier: identifier)
    }
            
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0.0, pinnedViews: [.sectionHeaders]) {
                    Section(header: sectionHeader()) {
                        ForEach(workouts, id: \.objectID) { workout in
                            NavigationLink(
                                tag: workout.workoutIdentifier,
                                selection: $selectedWorkout,
                                destination: { detailDestination(viewModel: workout.detailViewModel) }) {
                                    WorkoutMapCell(viewModel: workout.cellViewModel)
                            }
                            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.workoutCacheUpdated)) { notification in
                                if let remoteIdentifier = notification.userInfo?[Notification.remoteWorkoutKey] as? UUID, remoteIdentifier == workout.workoutIdentifier {
                                    viewContext.refresh(workout, mergeChanges: true)
                                }
                            }
                            .contextMenu {
                                if isFavorite(workout.workoutIdentifier) {
                                    Button(action: { workoutManager.toggleFavorite(workout.workoutIdentifier) }) {
                                        Label("Unfavorite", systemImage: "heart.slash")
                                    }
                                } else {
                                    Button(action: { workoutManager.toggleFavorite(workout.workoutIdentifier) }) {
                                        Label("Favorite", systemImage: "heart")
                                    }
                                }
                                
                                Button(action: { activeSheet = .tags(identifier: workout.workoutIdentifier, sport: workout.sport) }) {
                                    Label("Tags", systemImage: "tag")
                                }
                            }
                            .buttonStyle(WorkoutPlainButtonStyle())
                            Divider()
                        }
                    }
                }
            }
            .overlay(emptyOverlay())
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeCoverSheet = .settings }) {
                       Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { activeSheet = .filter }) {
                        Image(systemName: filterImageName)
                    }
                }
            }
            .sheet(item: $activeSheet, onDismiss: refreshFilter) { item in
                switch item {
                case .filter:
                    WorkoutsFilterView()
                        .environmentObject(filterManager)
                case .tags(let identifier, let sport):
                    TagSelectorView(tagManager: TagManager(context: viewContext, sport: sport, workoutIdentifier: identifier)) {
                        WorkoutCache.shared.purgeObject(with: identifier)
                    }
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
    func sectionHeader() -> some View {
        if filterManager.isFilterActive {
            VStack(alignment: .leading, spacing: 10.0) {
                HStack {
                    Button("Reset Filter", action: resetFilter)
                    Spacer()
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.accentColor)
                }
                
                HStack(spacing: 20.0) {
                    Text("\(workouts.count.formatted()) Workouts")
                    Spacer()
                    Text(filterManager.distanceString)
                        .foregroundColor(.distance)
                    Text(filterManager.durationString)
                        .foregroundColor(.time)
                }
                .font(.fixedBody)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.regularMaterial)
        }
    }
    
    @ViewBuilder
    func emptyOverlay() -> some View {
        if workouts.isEmpty {
            Text("No Workouts")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
}

extension WorkoutsContentView {
        
    func refreshFilter() {
        DispatchQueue.main.async {
            withAnimation {
                filterManager.updateTotals()
            }
            workouts.nsPredicate = filterManager.filterPredicate()
        }
    }
    
    func resetFilter() {
        filterManager.reset()
        refreshFilter()
    }
    
}

struct WorkoutsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        //manager.state = .notAvailable
        return manager
    }()
    
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    @State static var sport: Sport?
    
    static var previews: some View {
        WorkoutsView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(workoutManager)
            .environmentObject(purchaseManager)
            .preferredColorScheme(.dark)
    }
}
