//
//  WorkoutTagProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 11/9/21.
//

import Foundation
import CoreData

final class WorkoutTagProvider {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension WorkoutTagProvider {
    
    func workoutTags(forWorkout workout: UUID) -> [WorkoutTag] {
        let request = WorkoutTag.request()
        request.predicate = WorkoutTag.activePredicate(forWorkout: workout)
        request.returnsObjectsAsFaults = false
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    func visibleTags(forWorkout workout: UUID) -> [Tag] {
        let ids = workoutTags(forWorkout: workout).map { $0.tagId }
        let request = Self.visibleTagsFetchRequest(using: ids)
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    func activeTags(forWorkout workout: UUID) -> [Tag] {
        let ids = workoutTags(forWorkout: workout).map { $0.tagId }
        let request = Self.activeTagsFetchRequest(using: ids)
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    func workoutIdentifiers(forTag tag: UUID) -> [UUID] {
        let request = WorkoutTag.request()
        request.predicate = WorkoutTag.activePredicate(forTag: tag)
        request.returnsObjectsAsFaults = false
        
        let workoutTags: [WorkoutTag] = (try? context.fetch(request)) ?? []
        return workoutTags.map { $0.workoutId }
    }
    
    func workouts(forTag tag: UUID) -> [Workout] {
        let ids = workoutIdentifiers(forTag: tag)
        return Workout.fetchWorkoutsWithRemoteIdentifiers(ids, in: context)
    }
    
    func addWorkoutTag(for workout: UUID, tag: UUID) throws {
        try context.performAndWait {
            if let workoutTag = WorkoutTag.find(workout: workout, tag: tag, context: context) {
                workoutTag.restore()
            } else {
                WorkoutTag.insert(into: context, workout: workout, tag: tag)
            }
            
            try context.save()
        }
    }
    
    func deleteWorkoutTag(for workout: UUID, tag: UUID) throws {
        guard let workoutTag = WorkoutTag.find(workout: workout, tag: tag, context: context) else { throw TagProviderError.notFound }
        try context.performAndWait {
            workoutTag.archive()
            try context.save()
        }
    }
    
}

// MARK: - Fetch Requests

extension WorkoutTagProvider {
    
    static func visibleTagsFetchRequest(using uuids: [UUID]) -> NSFetchRequest<Tag> {
        let request = Tag.request()
        request.returnsObjectsAsFaults = false
        request.predicate = Tag.visiblePredicate(using: uuids)
        request.sortDescriptors = [Tag.sortedByPositionDescriptor()]
        return request
    }
    
    static func activeTagsFetchRequest(using uuids: [UUID]) -> NSFetchRequest<Tag> {
        let request = Tag.request()
        request.returnsObjectsAsFaults = false
        request.predicate = Tag.activePredicate(using: uuids)
        request.sortDescriptors = [Tag.sortedByPositionDescriptor()]
        return request
    }
    
}
