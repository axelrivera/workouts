//
//  TagWorkoutsSelectManager.swift
//  Workouts
//
//  Created by Axel Rivera on 11/10/21.
//

import Foundation
import SwiftUI
import CoreData

final class TagWorkoutsSelectManager: ObservableObject {
    let viewModel: TagSummaryViewModel
    let provider: WorkoutTagProvider
    
    @Published var selectedWorkouts = Set<UUID>()
    @Published var isSavingWorkouts = false
        
    init(viewModel: TagSummaryViewModel, context: NSManagedObjectContext) {
        self.viewModel = viewModel
        self.provider = WorkoutTagProvider(context: context)
    }
}

extension TagWorkoutsSelectManager {
    
    func load() {
        let ids = provider.workoutIdentifiers(forTag: viewModel.id)
        self.selectedWorkouts = Set(ids)
    }
    
    func isSelected(workout: UUID) -> Bool {
        selectedWorkouts.contains(workout)
    }
    
    func toggleWorkout(_ workout: UUID) {
        if isSelected(workout: workout) {
            selectedWorkouts.remove(workout)
        } else {
            selectedWorkouts.insert(workout)
        }
    }
    
    func saveSelectedWorkouts() async throws {
        isSavingWorkouts = true
        
        try await provider.context.perform { [weak self] in
            guard let self = self else { return }
            
            try self.selectedWorkouts.forEach { uuid in
                try self.provider.addWorkoutTag(for: uuid, tag: self.viewModel.id)
            }
            
            DispatchQueue.main.async {
                self.isSavingWorkouts = true
            }
        }
    }
    
}
