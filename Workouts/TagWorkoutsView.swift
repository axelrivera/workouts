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
        fetchRequest = TagWorkoutsManager.fetchRequest(predicate: manager.predicate())
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
        .listStyle(PlainListStyle())
        .onAppear { reload() }
        .overlay(emptyView())
        .navigationTitle(manager.viewModel.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    func emptyView() -> some View {
        if manager.showEmpty {
            Text("No Workouts")
                .foregroundColor(.secondary)
        }
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
    static var tag = StorageProvider.sampleTag(name: "Sample Tag", color: .red, gear: .none, moc: viewContext)
    
    static var previews: some View {
        NavigationView {
            TagWorkoutsView(viewModel: tag.viewModel())
        }
        .environment(\.managedObjectContext, viewContext)
        .preferredColorScheme(.light)
    }
}
