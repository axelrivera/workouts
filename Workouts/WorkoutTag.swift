//
//  WorkoutTag.swift
//  Workouts
//
//  Created by Axel Rivera on 11/8/21.
//

import CoreData

@objc(WorkoutTag)
class WorkoutTag: NSManagedObject {
    @NSManaged var workoutId: UUID
    @NSManaged var tagId: UUID
    @NSManaged private(set) var deletedDate: Date?
}

extension WorkoutTag {
    
    func archive() {
        deletedDate = Date()
    }
    
    func restore() {
        deletedDate = nil
    }
    
}

extension WorkoutTag {
    
    static func request() -> NSFetchRequest<WorkoutTag> {
        NSFetchRequest<WorkoutTag>(entityName: entityName)
    }
    
    static func find(workout: UUID, tag: UUID, context: NSManagedObjectContext) -> WorkoutTag? {
        let request = request()
        request.returnsObjectsAsFaults = false
        request.predicate = predicate(forWorkout: workout, andTag: tag)
        return try? context.fetch(request).first
    }
    
    @discardableResult
    static func insert(into context: NSManagedObjectContext, workout: UUID, tag: UUID) -> WorkoutTag {
        let workoutTag = WorkoutTag(context: context)
        workoutTag.workoutId = workout
        workoutTag.tagId = tag
        return workoutTag
    }
    
}

// MARK: - Predicates

extension WorkoutTag {
    
    static func activePredicate(forWorkout workout: UUID) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            activePredicate(),
            predicate(forWorkout: workout)
        ])
    }
    
    static func activePredicate(forTag tag: UUID) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            activePredicate(),
            predicate(forTag: tag)
        ])
    }
    
    static func activePredicate(forTags tags: [UUID]) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            activePredicate(),
            predicate(forTags: tags)
        ])
    }
    
    static func predicate(forWorkout workout: UUID, andTag tag: UUID) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(forWorkout: workout),
            predicate(forTag: tag)
        ])
    }
    
    static func predicate(forWorkout workout: UUID) -> NSPredicate {
        NSPredicate(format: "%K == %@", WorkoutTagSchema.workout.key, workout as NSUUID)
    }
    
    static func predicate(forTag tag: UUID) -> NSPredicate {
        NSPredicate(format: "%K == %@", WorkoutTagSchema.tag.key, tag as NSUUID)
    }
    
    static func predicate(forTags tags: [UUID]) -> NSPredicate {
        NSPredicate(format: "%K IN %@", WorkoutTagSchema.tag.key, tags)
    }
    
    static func activePredicate() -> NSPredicate {
        NSPredicate(format: "%K == NULL", WorkoutTagSchema.deletedDate.key)
    }
    
}
