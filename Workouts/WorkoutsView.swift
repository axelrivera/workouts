//
//  WorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI
import CoreData

struct WorkoutsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Binding var sport: Sport?
    
    @State private var selectedWorkout: UUID?
    
    @FetchRequest(entity: Workout.entity(), sortDescriptors: [], predicate: nil, animation: .default)
    private var workouts: FetchedResults<Workout>
    
    var interval: DateInterval?
    var showFilter: Bool = false

    init(sport: Binding<Sport?>, interval: DateInterval? = nil, showFilter: Bool = false) {
        _sport = sport
        self.interval = interval
        self.showFilter = showFilter
    }
    
    func detailDestination(viewModel: WorkoutDetailViewModel) -> some View {
        DetailView(detailManager: DetailManager(viewModel: viewModel))
    }
            
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0.0) {
                WorkoutFilter(sport: sport, interval: interval) { workout in
                    NavigationLink(
                        tag: workout.workoutIdentifier,
                        selection: $selectedWorkout,
                        destination: { detailDestination(viewModel: workout.detailViewModel) }) {
                        WorkoutMapCell(workout: workout.workoutData())
                            .padding()
                    }
                    .buttonStyle(WorkoutPlainButtonStyle())
                    Divider()
                }
            }
        }
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if showFilter {
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
                }
            }
        }
    }
}

struct WorkoutsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        //manager.state = .notAvailable
        return manager
    }()
    
    @State static var sport: Sport?
    
    static var previews: some View {
        NavigationView {
            WorkoutsView(sport: $sport)
                .navigationTitle("Workouts")
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(workoutManager)
        .preferredColorScheme(.dark)
    }
}
