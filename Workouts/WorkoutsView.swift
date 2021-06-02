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
    
    @State var sport: Sport? {
        didSet {
            AppSettings.defaultWorkoutsFilter = sport
        }
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    
    init() {
        self.sport = AppSettings.defaultWorkoutsFilter
    }
            
    var body: some View {
        NavigationView {
            ZStack {
                FilteredList(sport: sport) { workout in
                    NavigationLink(destination: DetailView(workout: workout, context: self.viewContext)) {
                        VStack(alignment: .leading, spacing: 2.0) {
                            Text(formattedActivityTypeString(for: workout.sport, indoor: workout.indoor))
                            
                            if workout.distance > 0 {
                                Text(formattedDistanceString(for: workout.distance))
                                    .font(.title)
                                    .foregroundColor(.distance)
                            } else {
                                Text(formattedHoursMinutesDurationString(for: workout.duration))
                                    .font(.title)
                                    .foregroundColor(.time)
                            }
                            
                            HStack {
                                Text(workout.source)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formattedRelativeDateString(for: workout.start))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                if workoutManager.state == .empty || workoutManager.state == .notAvailable {
                    Color.systemBackground
                        .ignoresSafeArea()
                    WorkoutEmptyView(workoutState: workoutManager.state)
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeSheet = .add }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            self.sport = nil
                        }, label: {
                            Text("All Workouts")
                        })
                        
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
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManager()
        //manager.state = .notAvailable
        return manager
    }()
    
    static var previews: some View {
        WorkoutsView()
            .environment(\.managedObjectContext, StorageProvider.preview.persistentContainer.viewContext)
            .environmentObject(workoutManager)
            .colorScheme(.dark)
    }
}

struct FilteredList<Content: View>: View {
    var fetchRequest: FetchRequest<Workout>
    var workouts: FetchedResults<Workout> { fetchRequest.wrappedValue }

    // this is our content closure; we'll call this once for each item in the list
    let content: (Workout) -> Content

    var body: some View {
        List(fetchRequest.wrappedValue, id: \.self) { workout in
            self.content(workout)
        }
    }

    init(sport: Sport?, @ViewBuilder content: @escaping (Workout) -> Content) {
        var predicates = [NSPredicate]()
        
        if let sport = sport {
            predicates.append(Workout.predicateForSport(sport))
        }
        
        predicates.append(Workout.notMarkedForLocalDeletionPredicate)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        let sort = [Workout.sortedByDateDescriptor()]
        fetchRequest = FetchRequest(entity: Workout.entity(), sortDescriptors: sort, predicate: predicate, animation: .default)
        
        self.content = content
    }
}
