//
//  TagWorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 11/9/21.
//

import SwiftUI
import CoreData

struct TagWorkoutsView: View {
    @Environment(\.managedObjectContext) var viewContext
    let viewModel: TagSummaryViewModel
    
    var body: some View {
        TagWorkoutsContentView(manager: TagWorkoutsManager(viewModel: viewModel, context: viewContext))
    }
}

struct TagWorkoutsContentView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    @StateObject var manager: TagWorkoutsManager
    
    private var fetchRequest: FetchRequest<Workout>
    private var workouts: FetchedResults<Workout> { fetchRequest.wrappedValue }
    
    @State private var selectedWorkout: UUID?
        
    init(manager: TagWorkoutsManager) {
        _manager = StateObject(wrappedValue: manager)
        fetchRequest = TagWorkoutsManager.fetchRequest()
    }
    
    func detailDestination(viewModel: WorkoutDetailViewModel) -> some View {
        DetailView(detailManager: DetailManager(viewModel: viewModel, context: viewContext))
    }
            
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0.0) {
                ForEach(workouts, id: \.objectID) { workout in
                    NavigationLink(
                        tag: workout.workoutIdentifier,
                        selection: $selectedWorkout,
                        destination: { detailDestination(viewModel: workout.detailViewModel) }) {
                            WorkoutMapCell(viewModel: workout.cellViewModel)
                    }
                    .buttonStyle(WorkoutPlainButtonStyle())
                    Divider()
                }
            }
        }
        .onAppear { reload() }
        .navigationTitle(manager.viewModel.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension TagWorkoutsContentView {
    
    func reload() {
        manager.reload()
        workouts.nsPredicate = manager.predicate()
    }
    
}

struct TagWorkoutsContentView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static var viewModel = TagSummaryViewModel(
        id: UUID(),
        name: "Sample Tag",
        color: .red,
        gearType: .none
    )
    
    static var previews: some View {
        NavigationView {
            TagWorkoutsView(viewModel: viewModel)
        }
        .environment(\.managedObjectContext, viewContext)
        .preferredColorScheme(.light)
    }
}
