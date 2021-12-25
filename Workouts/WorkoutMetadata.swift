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
    
    static func find(using identifier: UUID, in context: NSManagedObjectContext) -> [WorkoutMetadata] {
        context.performAndWait {
            let request = NSFetchRequest<WorkoutMetadata>(entityName: WorkoutMetadata.entityName)
            request.predicate = predicate(for: identifier)
            
            do {
                return try context.fetch(request)
            } catch {
                return []
            }
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

// MARK: - Duplicates

extension WorkoutMetadata {
    
    static func duplicates(in context: NSManagedObjectContext) -> [UUID] {
        let identiferExpr = NSExpression(forKeyPath: "identifier")
        let countExpr = NSExpressionDescription()
        let countVariableExpr = NSExpression(forVariable: "count")
        
        countExpr.name = "count"
        countExpr.expression = NSExpression(forFunction: "count:", arguments: [identiferExpr])
        countExpr.expressionResultType = .integer64AttributeType
        
        let request = NSFetchRequest<NSDictionary>(entityName: entityName)
        request.resultType = .dictionaryResultType
        request.propertiesToGroupBy = [IdentifierKey]
        request.propertiesToFetch = [IdentifierKey, countExpr]
        request.havingPredicate = NSPredicate(format: "%@ > 1", countVariableExpr)
        
        do {
            let results = try context.fetch(request)
            return results.compactMap({ $0["identifier"] as? UUID })
        } catch {
            return []
        }
    }
    
    static func fixDuplicates(in context: NSManagedObjectContext) {
        context.performAndWait {
            let duplicates = self.duplicates(in: context)
            Log.debug("fixing duplicates: \(duplicates)")
            
            for identifier in duplicates {
                fixDuplicate(identifier: identifier, in: context)
            }
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    Log.debug("error saving context: \(context)")
                    context.rollback()
                }
            }
        }
    }
    
    static func fixDuplicate(identifier: UUID, in context: NSManagedObjectContext) {
        let workouts = find(using: identifier, in: context)

        if let first = workouts.first {
            first.isFavorite = workouts.filter({ $0.isFavorite }).isPresent
        }

        let resulting = workouts.dropFirst()
        resulting.forEach({ context.delete($0) })
    }
    
}
