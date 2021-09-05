//
//  StatsWorkoutsView.swift
//  StatsWorkoutsView
//
//  Created by Axel Rivera on 9/3/21.
//

import SwiftUI
import CoreData

struct StatsWorkoutsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State private var selectedWorkout: UUID?
    
    @FetchRequest(entity: Workout.entity(), sortDescriptors: [], predicate: nil, animation: .default)
    private var workouts: FetchedResults<Workout>
    
    var sport: Sport?
    var interval: DateInterval?

    init(sport: Sport?, interval: DateInterval? = nil) {
        self.sport = sport
        self.interval = interval
    }
    
    func detailDestination(viewModel: WorkoutDetailViewModel) -> some View {
        DetailView(detailManager: DetailManager(viewModel: viewModel))
    }
            
    var body: some View {
        List {
            WorkoutFilter(sport: sport, interval: interval) { workout in
                NavigationLink(
                    tag: workout.workoutIdentifier,
                    selection: $selectedWorkout,
                    destination: { detailDestination(viewModel: workout.detailViewModel) }) {
                        WorkoutPlainCell(viewModel: workout.detailViewModel)
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatsWorkoutsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        //manager.state = .notAvailable
        return manager
    }()
        
    static var previews: some View {
        NavigationView {
            StatsWorkoutsView(sport: nil)
                .navigationTitle("Workouts")
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(workoutManager)
        .preferredColorScheme(.dark)
    }
}
