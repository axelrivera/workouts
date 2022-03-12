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
        context.performAndWait {
            do {
                return try context.fetch(activeFetchRequest(gearTypes: gearTypes))
            } catch {
                return []
            }
        }
    }
    
    func archivedTags() -> [Tag] {
        context.performAndWait {
            do {
                return try context.fetch(archivedFetchRequest())
            } catch {
                return []
            }
        }
    }
    
    /**
     The number of tags. Used for tag name input validation.
     */
    func numberOfTags(with tagName: String) -> Int {
        context.performAndWait {
            do {
                return try context.count(for: activeFetchRequest(name: tagName))
            } catch {
                return 0
            }
        }
    }
    
    var totalActiveTags: Int {
        context.performAndWait {
            do {
                return try context.count(for: activeFetchRequest())
            } catch {
                return 0
            }
        }
    }
    
}

// MARK: - Management

extension TagProvider {
    
    func addTag(viewModel: TagEditViewModel, position: Int?) {
        context.performAndWait {
            Self.addTag(viewModel: viewModel, position: position, context: context)
        }
    }
    
}

// MARK: - Initial Values

extension TagProvider {
    
    static func addTag(viewModel: TagEditViewModel, position: Int?, context: NSManagedObjectContext) {
        Tag.insert(into: context, viewModel: viewModel, position: position)
    }
    
    static func createDefaultTags(in context: NSManagedObjectContext) {
        context.performAndWait {
            let viewModels = [
                Tag.addViewModel(name: "My Bike", gearType: .bike, color: .accentColor),
                Tag.addViewModel(name: "My Shoes", gearType: .shoes, color: .ruby),
                Tag.addViewModel(name: "Workout", gearType: .none, color: .amber),
                Tag.addViewModel(name: "Commute", gearType: .none, color: .citrine),
                Tag.addViewModel(name: "Long Run", gearType: .shoes, color: .emerald)
            ]
            
            viewModels.enumerated().forEach { (index, viewModel) in
                addTag(viewModel: viewModel, position: index, context: context)
            }
            
            do {
                try context.save()
                Log.debug("created initial tags")
            } catch {
                Log.debug("failed to save tags")
            }
        }
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
