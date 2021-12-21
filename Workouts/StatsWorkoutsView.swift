//
//  StatsWorkoutsView.swift
//  StatsWorkoutsView
//
//  Created by Axel Rivera on 9/3/21.
//

import SwiftUI
import CoreData

struct StatsWorkoutsView: View {
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var workoutManager: WorkoutManager

    private var fetchRequest: FetchRequest<Workout>
    private var workouts: FetchedResults<Workout> { fetchRequest.wrappedValue }
    
    let title: String?
    @State private var selectedWorkout: UUID?
    
    init(identifiers: [UUID], title: String? = nil) {
        self.title = title
        fetchRequest = DataProvider.fetchRequest(for: identifiers)
    }
    
    func detailDestination(viewModel: WorkoutDetailViewModel) -> some View {
        DetailView(detailManager: DetailManager(viewModel: viewModel, context: viewContext))
    }
            
    var body: some View {
        List(workouts, id: \.objectID) { workout in
            NavigationLink(
                tag: workout.workoutIdentifier,
                selection: $selectedWorkout,
                destination: { detailDestination(viewModel: workout.detailViewModel) }) {
                    WorkoutPlainCell(viewModel: workout.detailViewModel)
            }
        }
        .overlay(emptyOverlay())
        .listStyle(PlainListStyle())
        .navigationTitle(title ?? "Workouts")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    func emptyOverlay() -> some View {
        if workouts.isEmpty {
            Text("No Workouts")
                .foregroundColor(.secondary)
        }
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
            StatsWorkoutsView(identifiers: [])
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(workoutManager)
        .preferredColorScheme(.dark)
    }
}
