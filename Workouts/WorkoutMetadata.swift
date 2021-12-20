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
}

extension WorkoutMetadata {
    
    static func request() -> NSFetchRequest<WorkoutMetadata> {
        NSFetchRequest<WorkoutMetadata>(entityName: entityName)
    }
    
    static func find(using identifier: UUID, in context: NSManagedObjectContext) -> WorkoutMetadata? {
        context.performAndWait {
            let request = NSFetchRequest<WorkoutMetadata>(entityName: WorkoutMetadata.entityName)
            request.predicate = predicate(for: identifier)
            return try? context.fetch(request).first
        }
    }
    
    static func findOrCreate(using identifier: UUID, in context: NSManagedObjectContext) throws -> WorkoutMetadata {
        try context.performAndWait {
            let request = NSFetchRequest<WorkoutMetadata>(entityName: WorkoutMetadata.entityName)
            request.predicate = predicate(for: identifier)
            
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
            let request = NSFetchRequest<NSDictionary>(entityName: WorkoutMetadata.entityName)
            request.predicate = favoritesPredicate()
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["identifier"]
                        
            return try context.fetch(request).compactMap { dictionary in
                dictionary["identifier"] as? UUID
            }
        } catch {
            return []
        }
    }
        
}

// MARK: - Predicates

extension WorkoutMetadata {
    
    static func predicate(for identifier: UUID) -> NSPredicate {
        NSPredicate(format: "%K == %@", IdentifierKey, identifier as NSUUID)
    }
    
    static func favoritesPredicate() -> NSPredicate {
        NSPredicate(format: "%K == %@", FavoriteKey, NSNumber(value: true))
    }
    
}
