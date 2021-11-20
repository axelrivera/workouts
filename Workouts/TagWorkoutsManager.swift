//
//  TagWorkoutsManager.swift
//  Workouts
//
//  Created by Axel Rivera on 11/9/21.
//

import Foundation
import SwiftUI
import CoreData

final class TagWorkoutsManager: ObservableObject {
    let viewModel: TagSummaryViewModel
    
    var workoutIds = [UUID]()
    private let provider: WorkoutTagProvider
    
    init(viewModel: TagSummaryViewModel, context: NSManagedObjectContext) {
        self.viewModel = viewModel
        self.provider = WorkoutTagProvider(context: context)
    }
}

extension TagWorkoutsManager {
    
    func reload() {
        workoutIds = provider.workoutIdentifiers(forTag: viewModel.id)
    }
    
    func predicate() -> NSPredicate {
        Workout.predicateForIdentifiers(workoutIds)
    }
    
}

extension TagWorkoutsManager {
    
    static func fetchRequest(predicate: NSPredicate? = nil) -> FetchRequest<Workout> {
        let request = Workout.defaultFetchRequest()
        request.predicate = predicate ?? Workout.predicateForIdentifiers([])
        request.sortDescriptors = [Workout.sortedByDateDescriptor()]
        return FetchRequest(fetchRequest: request, animation: .linear)
    }
    
    static func fetchRequestPredicate(using uuids: [UUID]) -> NSPredicate {
        Workout.predicateForIdentifiers(uuids)
    }
    
}
