//
//  TagProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 10/31/21.
//

import CoreData

enum TagProviderError: Error {
    case notFound
}

final class TagProvider {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

// MARK: - Fetching

extension TagProvider {
    
    func activeTags(sport: Sport? = nil) -> [Tag] {
        let gearTypes = gearTypes(for: sport)
        return activeTags(gearTypes: gearTypes)
    }
    
    func activeTags(gearTypes: [Tag.GearType]) -> [Tag] {
        do {
            return try context.fetch(activeFetchRequest(gearTypes: gearTypes))
        } catch {
            return []
        }
    }
    
    func archivedTags() -> [Tag] {
        do {
            return try context.fetch(archivedFetchRequest())
        } catch {
            return []
        }
    }
    
    /**
     The number of tags. Used for tag name input validation.
     */
    func numberOfTags(with tagName: String) -> Int {
        do {
            return try context.count(for: activeFetchRequest(name: tagName))
        } catch {
            return 0
        }
    }
    
    var totalActiveTags: Int {
        do {
            return try context.count(for: activeFetchRequest())
        } catch {
            return 0
        }
    }
    
}

// MARK: - Management

extension TagProvider {
    
    func addTag(viewModel: TagEditViewModel) throws {
        Tag.insert(into: context, viewModel: viewModel)
    }
    
}

// MARK: - Requests

extension TagProvider {
    
    func gearTypes(for sport: Sport?) -> [Tag.GearType] {
        guard let sport = sport else { return [] }
        
        let gearTypes: [Tag.GearType]
        switch sport {
        case .cycling:
            gearTypes = [.bike, .none]
        case .running, .walking:
            gearTypes = [.shoes, .none]
        default:
            gearTypes = [.none]
        }
        return gearTypes
    }
    
    func activeFetchRequest(name: String? = nil, gearTypes: [Tag.GearType] = []) -> NSFetchRequest<Tag> {
        let request = NSFetchRequest<Tag>(entityName: Tag.entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = Tag.activePredicate(name: name, gearTypes: gearTypes)
        request.sortDescriptors = [Tag.sortedByPositionDescriptor()]
        return request
    }
    
    func archivedFetchRequest() -> NSFetchRequest<Tag> {
        let request = NSFetchRequest<Tag>(entityName: Tag.entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = Tag.archivedPredicate()
        request.sortDescriptors = [Tag.sortedByArchivedDateDescriptor()]
        
        return request
    }
    
}
