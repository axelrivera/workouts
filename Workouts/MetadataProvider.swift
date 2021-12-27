//
//  MetadataProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 11/3/21.
//

import CoreData
import SwiftUI

final class MetadataProvider {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
}


extension MetadataProvider {
    
    func fetchWorkout(identifier: UUID) throws -> WorkoutMetadata {
        try WorkoutMetadata.findOrCreate(using: identifier, in: context)
    }
    
}

// MARK: - Favorites

extension MetadataProvider {
    
    func isFavorite(_ identifier: UUID) -> Bool {
        guard let workout = try? fetchWorkout(identifier: identifier) else { return false }
        return workout.isFavorite
    }
    
    func favorites() -> [Workout] {
        let ids = WorkoutMetadata.favorites(in: context)
        return Workout.fetchWorkoutsWithRemoteIdentifiers(ids, in: context, sorted: true)
    }
    
    func favoriteWorkout(for identifier: UUID) throws {
        try context.performAndWait {
            let workout = try fetchWorkout(identifier: identifier)
            workout.isFavorite = true
            workout.favoriteDate = Date()
            try context.save()
        }
    }
    
    func unfavoriteWorkout(for identifier: UUID) throws {
        try context.performAndWait {
            let workout = try fetchWorkout(identifier: identifier)
            workout.isFavorite = false
            workout.favoriteDate = nil
            try context.save()
        }
    }
    
}
