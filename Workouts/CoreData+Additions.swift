//
//  CoreData+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import CoreData

extension NSManagedObject {
    
    static var entityName: String {
        String(describing: Self.self)
    }
    
//    static func fetchRequest<Object>() -> NSFetchRequest<Object> {
//        let request: NSFetchRequest<Object> = NSFetchRequest(entityName: entityName)
//        return request
//    }
    
}

extension NSManagedObjectContext {
    
    @discardableResult
    func saveOrRollback() -> Bool {
        do {
            try save()
            return true
        } catch {
            rollback()
            return false
        }
    }
    
    func batchDeleteObjects() {
        Workout.batchDeleteObjectsMarkedForDeletion(in: self)
    }
    
}
