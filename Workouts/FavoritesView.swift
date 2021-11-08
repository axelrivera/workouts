//
//  TagWorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 11/3/21.
//

import SwiftUI
import CoreData

final class FavoritesManager: ObservableObject {
    let provider: MetadataProvider
    
    @Published var favorites = [Workout]()
    
    init(context: NSManagedObjectContext) {
        provider = MetadataProvider(context: context)
    }
    
    func reload() {
        let favorites = provider.favorites()
        DispatchQueue.main.async {
            withAnimation {
                self.favorites = favorites
            }
        }
    }
}

struct FavoritesView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        FavoritesContentView(manager: FavoritesManager(context: viewContext))
    }
}

struct FavoritesContentView: View {
    @Environment(\.managedObjectContext) var viewContext
    @StateObject var manager: FavoritesManager
    
    @State private var selectedWorkout: UUID?
    
    func detailDestination(viewModel: WorkoutDetailViewModel) -> some View {
        DetailView(detailManager: DetailManager(viewModel: viewModel, context: viewContext))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(manager.favorites, id: \.objectID) { workout in
                    NavigationLink(
                        tag: workout.workoutIdentifier,
                        selection: $selectedWorkout,
                        destination: { detailDestination(viewModel: workout.detailViewModel) }) {
                            WorkoutMapCell(
                                isFavorite: workout.isFavorite,
                                viewModel: workout.cellViewModel
                            )
                                .padding()
                    }
                    .buttonStyle(WorkoutPlainButtonStyle())
                    Divider()
                }
            }
            .onAppear(perform: { manager.reload() })
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TagWorkoutsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static var previews: some View {
        FavoritesView()
            .environment(\.managedObjectContext, viewContext)
    }
}
