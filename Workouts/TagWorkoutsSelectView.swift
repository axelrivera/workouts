//
//  TagWorkoutsSelectView.swift
//  Workouts
//
//  Created by Axel Rivera on 11/10/21.
//

import SwiftUI

struct TagWorkoutsSelectView: View {
    @Environment(\.managedObjectContext) var viewContext
    let viewModel: TagSummaryViewModel
    
    var body: some View {
        TagWorkoutsSelectContentView(viewModel: viewModel)
            .environmentObject(TagWorkoutsSelectManager(viewModel: viewModel, context: viewContext))
    }
    
}


struct TagWorkoutsSelectContentView: View {
    enum ActiveSheet: Identifiable {
        case settings
        var id: Int { hashValue }
    }
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    
    @EnvironmentObject var selectManager: TagWorkoutsSelectManager
    
    let viewModel: TagSummaryViewModel
    
    private var fetchRequest: FetchRequest<Workout>
    private var workouts: FetchedResults<Workout> { fetchRequest.wrappedValue }
    
    @State private var activeSheet: ActiveSheet?
        
    init(viewModel: TagSummaryViewModel) {
        self.viewModel = viewModel
        fetchRequest = DataProvider.fetchRequest(sports: viewModel.gearType.sports)
    }
            
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0.0) {
                    ForEach(workouts, id: \.objectID) { workout in
                        TagWorkoutsSelectButton(viewModel: workout.cellViewModel, tags: [])
                        Divider()
                    }
                }
            }
            .navigationTitle(viewModel.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { presentationMode.wrappedValue.dismiss() })
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: {})
                }
            }
        }
    }
}

extension TagWorkoutsSelectContentView {
    
    func tags(for workout: Workout) -> [TagLabelViewModel] {
        WorkoutCache.shared.tags(for: workout.workoutIdentifier)
    }
    
}

struct TagWorkoutsSelectView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static var viewModel = TagSummaryViewModel(
        id: UUID(),
        name: "Sample Tag",
        color: .red,
        gearType: .none
    )
    
    static var selectManager = TagWorkoutsSelectManager(viewModel: viewModel, context: viewContext)
    
    static var previews: some View {
        TagWorkoutsSelectView(viewModel: viewModel)
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(selectManager)
            .preferredColorScheme(.light)
    }
}
