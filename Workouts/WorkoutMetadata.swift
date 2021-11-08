//
//  WorkoutMetadata.swift
//  Workouts
//
//  Created by Axel Rivera on 10/22/21.
//

import CoreData

private let IdentifierKey = "identifier"
private let FavoriteKey = "isFavorite"

@objc(WorkoutMetadata)
class WorkoutMetadata: NSManagedObject {
    @NSManaged var identifier: UUID
    @NSManaged var isFavorite: Bool
    @NSManaged var favoriteDate: Date?
    @NSManaged var tags: Set<Tag>
}

extension WorkoutMetadata {
    
    static func request() -> NSFetchRequest<WorkoutMetadata> {
        NSFetchRequest<WorkoutMetadata>(entityName: entityName)
    }
    
    static func find(using identifier: UUID, in context: NSManagedObjectContext) -> WorkoutMetadata? {
        context.performAndWait {
            let request = NSFetchRequest<WorkoutMetadata>(entityName: WorkoutMetadata.entityName)
            request.predicate = NSPredicate(format: "%K == %@", IdentifierKey, identifier as NSUUID)
            return try? context.fetch(request).first
        }
    }
    
    static func findOrCreate(using identifier: UUID, in context: NSManagedObjectContext) throws -> WorkoutMetadata {
        try context.performAndWait {
            let request = NSFetchRequest<WorkoutMetadata>(entityName: WorkoutMetadata.entityName)
            request.predicate = NSPredicate(format: "%K == %@", IdentifierKey, identifier as NSUUID)
            
            if let workout = try context.fetch(request).first {
                return workout
            } else {
                let newWorkout = WorkoutMetadata(context: context)
                newWorkout.identifier = identifier
                return newWorkout
            }
        }
    }
    
    static func favorites(in context: NSManagedObjectContext) -> [UUID] {
        do {
            let request = self.request()
            request.predicate = favoritesPredicate()
            
            return try context.fetch(request).map { $0.identifier }
        } catch {
            return []
        }
    }
    
}

// MARK: - Predicates

extension WorkoutMetadata {
    
    static func favoritesPredicate() -> NSPredicate {
        NSPredicate(format: "%K == %@", FavoriteKey, NSNumber(value: true))
    }
    
}
