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
    enum ActiveCoverSheet: Hashable, Identifiable {
        case settings, add
        var id: Self { self }
    }
    
    enum ActiveSheet: Hashable, Identifiable {
        case filter
        case tagsToAll
        case tags(identifier: UUID, sport: Sport)
        var id: Self { self }
    }
    
    enum ActiveAlert: Identifiable {
        case tagConfirmation
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    @StateObject var filterManager: WorkoutsFilterManager
    
    var fetchRequest: FetchRequest<Workout>
    var workouts: FetchedResults<Workout> { fetchRequest.wrappedValue }
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeCoverSheet: ActiveCoverSheet?
    @State private var activeAlert: ActiveAlert?
    
    @State private var selectedWorkout: UUID?
        
    init(filterManager: WorkoutsFilterManager) {
        _filterManager = StateObject(wrappedValue: filterManager)
        fetchRequest = DataProvider.fetchFetquest(for: filterManager.filterPredicate())
    }
    
    var filterImageName: String {
        filterManager.isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
    }
    
    func isFavorite(_ identifier: UUID) -> Bool {
        workoutManager.storage.isWorkoutFavorite(identifier)
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
                                destination: { DetailView(viewModel: workout.detailViewModel) }) {
                                    WorkoutMapCell(viewModel: workoutManager.storage.viewModel(forWorkout: workout))
                            }
                                .onReceive(NotificationCenter.default.publisher(for: Notification.Name.didFindRelevantTransactions)) { notification in
                                    workoutManager.storage.refreshAllWorkouts()
                                }
                                .onReceive(NotificationCenter.default.publisher(for: Notification.Name.didFinishProcessingDuplicates)) { notification in
                                    workoutManager.storage.refreshAllWorkouts()
                                }
                                .onReceive(NotificationCenter.default.publisher(for: WorkoutStorage.viewModelUpdatedNotification)) { notification in
                                    if let viewModel = notification.userInfo?[WorkoutStorage.viewModelKey] as? WorkoutViewModel,
                                       viewModel.id == workout.workoutIdentifier {
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
            .overlay(processOverlay())
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.refreshWorkoutsFilter)) { _ in
                refreshFilter()
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeCoverSheet = .settings }) {
                       Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { activeCoverSheet = .add}) {
                        Image(systemName: "plus")
                    }
                    .disabled(isAddDisabled)
                    
                    Button(action: { activeSheet = .filter }) {
                        Image(systemName: filterImageName)
                    }
                }
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .filter:
                    WorkoutsFilterView()
                        .environmentObject(filterManager)
                case .tagsToAll:
                    WorkoutsTagSelectorView()
                case .tags(let identifier, let sport):
                    TagSelectorView(tagManager: TagManager(context: viewContext, sport: sport, workoutIdentifier: identifier)) {
                        WorkoutStorage.resetTags(forID: identifier)
                    }
                }
            }
            .fullScreenCover(item: $activeCoverSheet) { item in
                switch item {
                case .settings:
                    SettingsView()
                        .environmentObject(purchaseManager)
                case .add:
                    ImportView()
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .tagConfirmation:
                    return Alert(
                        title: Text("Apply Tags"),
                        message: Text("Apply tags to all \(workouts.count.formatted()) results in filter? Some tags may be ignored based on gear type."),
                        primaryButton: Alert.Button.default(Text("Continue"), action: { activeSheet = .tagsToAll }),
                        secondaryButton: Alert.Button.cancel(Text("Cancel"))
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    func sectionHeader() -> some View {
        if filterManager.isFilterActive || workoutManager.showUpdatingRemoteLocationDataLoading || workoutManager.showNoWorkoutsAlert {
            VStack(spacing: 0) {
                if workoutManager.showUpdatingRemoteLocationDataLoading {
                    ProcessingLocationView()
                }
                
                if workoutManager.showNoWorkoutsAlert {
                    NoWorkoutsView()
                }
                
                if filterManager.isFilterActive {
                    VStack(alignment: .leading, spacing: 15.0) {
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
                        
                        HStack {
                            Button("Reset Filter", role: .destructive, action: resetFilter)
                            Spacer()
                            Menu {
                                Button(action: filterManager.favoriteAll) {
                                    Label("Favorite All", systemImage: "heart")
                                }
                                
                                Button(action: filterManager.unfavoriteAll) {
                                    Label("Unfavorite All", systemImage: "heart.slash")
                                }
                                
                                Button(action: { activeAlert = .tagConfirmation }) {
                                    Label("Tag All", systemImage: "tag")
                                }
                                
                                Picker("Sort By", selection: $filterManager.sortBy) {
                                    ForEach(WorkoutsFilterManager.SortBy.allCases, id: \.self) { sort in
                                        HStack {
                                            Text(sort.title)
                                            if filterManager.sortBy == sort {
                                                Spacer()
                                                Image(systemName: filterManager.sortAscending ? "chevron.up" : "chevron.down")
                                            }
                                        }
                                    }
                                }
                                .onChange(of: filterManager.sortBy) { newValue in
                                    refreshFilter()
                                }
                                .onChange(of: filterManager.sortAscending) { newValue in
                                    refreshFilter()
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18.0, height: 18.0, alignment: .center)
                            }
                        }
                    }
                    .padding([.leading, .trailing])
                    .padding([.top, .bottom], CGFloat(10.0))
                    .background(.regularMaterial)
                }
            }
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
    
    @ViewBuilder
    func processOverlay() -> some View {
        if workoutManager.showProcessingRemoteDataLoading || filterManager.isProcessingActions {
            HUDView()
        }
    }
}

extension WorkoutsContentView {
    
    var isAddDisabled: Bool {
        !workoutManager.isAuthorized || workoutManager.isProcessing
    }
        
    func refreshFilter() {
        DispatchQueue.main.async {
            withAnimation {
                filterManager.updateTotals()
                workouts.nsPredicate = filterManager.filterPredicate()
                workouts.nsSortDescriptors = filterManager.filterSort()
            }
        }
    }
    
    func resetFilter() {
        withAnimation {
            filterManager.reset()
        }
        refreshFilter()
    }
    
}

struct WorkoutsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        //manager.state = .notAvailable
        manager.showNoWorkoutsAlert = true
        return manager
    }()
    
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
        
    static var previews: some View {
        WorkoutsView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(workoutManager)
            .environmentObject(purchaseManager)
            .preferredColorScheme(.dark)
    }
}
