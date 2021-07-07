//
//  WorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI
import CoreData

struct WorkoutsView: View {
    enum ActiveSheet: Identifiable {
        case add
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @State var activeSheet: ActiveSheet?
    
    @State var sport: Sport? = AppSettings.defaultWorkoutsFilter {
        didSet {
            AppSettings.defaultWorkoutsFilter = sport
        }
    }
    
    @State var isEmpty = false
    
    @Environment(\.managedObjectContext) private var viewContext
        
    var isNotAvailable: Bool {
        workoutManager.state == .empty || workoutManager.state == .notAvailable
    }
    
    func destination(for workout: Workout) -> some View {
        DetailView(workout: workout)
    }
    
    var showEmptyText: Bool {
        isEmpty && workoutManager.state == .ok && !workoutManager.isLoading
    }
            
    var body: some View {
        NavigationView {
            ZStack {
                FilteredList(sport: sport, isEmpty: $isEmpty) { workout in
                    NavigationLink(destination: destination(for: workout)) {
                        VStack(alignment: .leading, spacing: 2.0) {
                            Text(workout.title)
                            
                            if workout.distance > 0 {
                                Text(formattedDistanceString(for: workout.distance))
                                    .font(.largeTitle)
                                    .foregroundColor(.distance)
                            } else {
                                Text(formattedHoursMinutesSecondsDurationString(for: workout.duration))
                                    .font(.largeTitle)
                                    .foregroundColor(.time)
                            }
                            
                            HStack {
                                Text(workout.source)
                                Spacer()
                                Text(formattedRelativeDateString(for: workout.start))
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .disabled(workoutManager.isLoading)
                
                if isNotAvailable {
                    Color.systemBackground
                        .ignoresSafeArea()
                    WorkoutEmptyView(workoutState: workoutManager.state)
                }
                
                if showEmptyText {
                    Text("No Workouts")
                        .foregroundColor(.secondary)
                }
                
                if workoutManager.isLoading {
                    ProcessView(text: "Fetching Workouts...", value: $workoutManager.processingRemoteDataValue)
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeSheet = .add }) {
                        Image(systemName: "plus")
                    }
                    .disabled(workoutManager.isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            self.sport = nil
                        }, label: {
                            Text("All Workouts")
                        })
                        
                        Divider()
                        
                        ForEach(Sport.supportedSports) { sport in
                            Button(action: {
                                self.sport = sport
                            }, label: {
                                Text(sport.title)
                            })
                        }
                    } label: {
                        Text(sport?.title ?? "All Workouts")
                    }
                    .disabled(workoutManager.isDisabled || workoutManager.isLoading)
                }
            }
            .fullScreenCover(item: $activeSheet) { item in
                switch item {
                case .add:
                    ImportView()
                        .environmentObject(ImportManager())
                }
            }
        }
    }
}

struct WorkoutsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManager(context: viewContext)
        //manager.state = .notAvailable
        return manager
    }()
    
    static var previews: some View {
        WorkoutsView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(workoutManager)
            .colorScheme(.dark)
    }
}


extension WorkoutsView {
    
    struct FilteredList<Content: View>: View {
        var fetchRequest: FetchRequest<Workout>
        @Binding var isEmpty: Bool

        // this is our content closure; we'll call this once for each item in the list
        let content: (Workout) -> Content

        var body: some View {
            let workouts = fetchRequest.wrappedValue
            isEmpty = workouts.isEmpty
            
            return List(workouts, id: \.self) { workout in
                self.content(workout)
            }
        }

        init(sport: Sport?, isEmpty: Binding<Bool>, @ViewBuilder content: @escaping (Workout) -> Content) {
            _isEmpty = isEmpty
            
            let request = Self.fetchRequest(for: sport)
            fetchRequest = FetchRequest(fetchRequest: request, animation: .default)
            
            self.content = content
        }
        
        private static func fetchRequest(for sport: Sport?) -> NSFetchRequest<Workout> {
            let sort = [Workout.sortedByDateDescriptor()]
            let request = Workout.defaultFetchRequest()
            request.predicate = Workout.activePredicate(sport: sport, interval: nil)
            request.sortDescriptors = sort
            return request
        }
    }
    
}
