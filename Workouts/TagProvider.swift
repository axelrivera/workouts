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
        do {
            return try context.fetch(activeFetchRequest(sport: sport))
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
    
    func activeFetchRequest(name: String? = nil, sport: Sport? = nil) -> NSFetchRequest<Tag> {
        let request = NSFetchRequest<Tag>(entityName: Tag.entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = Tag.activePredicate(name: name, sport: sport)
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
