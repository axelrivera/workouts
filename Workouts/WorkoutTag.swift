//
//  WorkoutTag.swift
//  Workouts
//
//  Created by Axel Rivera on 11/8/21.
//

import CoreData

private let WorkoutKey = "workoutId"
private let TagKey = "tagId"
private let DeletedDateKey = "deletedDate"

@objc(WorkoutTag)
class WorkoutTag: NSManagedObject {
    @NSManaged var workoutId: UUID
    @NSManaged var tagId: UUID
    @NSManaged var deletedDate: Date?
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
    
    static func predicate(forWorkout workout: UUID, andTag tag: UUID) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(forWorkout: workout),
            predicate(forTag: tag)
        ])
    }
    
    static func predicate(forWorkout workout: UUID) -> NSPredicate {
        NSPredicate(format: "%K == %@", WorkoutKey, workout as NSUUID)
    }
    
    static func predicate(forTag tag: UUID) -> NSPredicate {
        NSPredicate(format: "%K == %@", TagKey, tag as NSUUID)
    }
    
    static func activePredicate() -> NSPredicate {
        NSPredicate(format: "%K == NULL", DeletedDateKey)
    }
    
}
