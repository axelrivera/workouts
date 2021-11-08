//
//  Tag.swift
//  Workouts
//
//  Created by Axel Rivera on 10/29/21.
//

import CoreData
import SwiftUI

private let NameKey = "name"
private let ArchivedKey = "archivedDate"
private let DeletedKey = "deletedDate"
private let FavoriteKey = "isFavorite"
private let UUIDKey = "uuid"
private let GearTypeKey = "gearTypeValue"

extension Tag {
    enum GearType: String, Identifiable, CaseIterable {
        case none, bike, shoes
        var id: String { rawValue }
        
        static func displayValues(for sport: Sport) -> [GearType] {
            switch sport {
            case .cycling:
                return [.bike, .none]
            case .running, .walking:
                return [.shoes, .none]
            default:
                return []
            }
        }
    }
}

extension Tag: Identifiable {}

@objc(Tag)
class Tag: NSManagedObject {
    
    @NSManaged private(set) var uuid: UUID
    @NSManaged var name: String
    @NSManaged var color: UIColor?
    @NSManaged fileprivate var gearTypeValue: String?
    @NSManaged var isFavorite: Bool
    @NSManaged var isDefault: Bool
    
    @NSManaged var archivedDate: Date?
    @NSManaged var deletedDate: Date?
    
    @NSManaged var position: NSNumber
    
    @NSManaged var workouts: Set<WorkoutMetadata>
    
    @nonobjc
    var gearType: GearType {
        get { GearType(rawValue: gearTypeValue ?? "") ?? .none }
        set { gearTypeValue = newValue.rawValue }
    }
}

// MARK: Helper Methods

extension Tag {
    
    var colorValue: Color {
        guard let color = color else { return .accentColor }
        return Color(color)
    }
    
    var positionValue: Int { position.intValue }
    
}

// MARK: Fetching

extension Tag {
    
    static func find(using uuid: UUID, in context: NSManagedObjectContext) -> Tag? {
        context.performAndWait {
            let request = NSFetchRequest<Tag>(entityName: Tag.entityName)
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "%K == %@", UUIDKey, uuid as NSUUID)
            return try? context.fetch(request).first
        }
    }
    
    @discardableResult
    static func insert(into context: NSManagedObjectContext, viewModel: TagEditViewModel) -> Tag {
        context.performAndWait {
            let tag = Tag(context: context)
            tag.uuid = UUID()
            updateValues(for: tag, viewModel: viewModel, in: context)
            
            return tag
        }
    }
    
    static func updateValues(for tag: Tag, viewModel: TagEditViewModel, in context: NSManagedObjectContext) {
        context.performAndWait {
            tag.name = viewModel.name
            tag.color = UIColor(viewModel.color)
            tag.gearType = viewModel.gearType
            tag.isDefault = viewModel.isDefault
        }
    }
    
}

// MARK: - Predicates

extension Tag {
    
    static func activePredicate(name: String? = nil, sport: Sport? = nil) -> NSPredicate {
        var predicates = [notArchivedPredicate(), notDeletedPredicate()]
        
        if let name = name {
            predicates.append(namePredicate(name))
        }
        
        if let sport = sport {
            predicates.append(gearPredicate(sport: sport))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    static func namePredicate(_ name: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", NameKey, name)
    }
    
    static func archivedPredicate() -> NSPredicate {
        NSPredicate(format: "%K  != NULL", ArchivedKey)
    }
    
    static func notArchivedPredicate() -> NSPredicate {
        NSPredicate(format: "%K == NULL", ArchivedKey)
    }
    
    static func deletedPredicate() -> NSPredicate {
        NSPredicate(format: "%K != NULL", DeletedKey)
    }
    
    static func notDeletedPredicate() -> NSPredicate {
        NSPredicate(format: "%K == NULL", DeletedKey)
    }
    
    static func gearPredicate(sport: Sport) -> NSPredicate {
        let gearTypes: [GearType]
        switch sport {
        case .cycling:
            gearTypes = [.bike, .none]
        case .running, .walking:
            gearTypes = [.shoes, .none]
        default:
            gearTypes = [.none]
        }
        
        return NSPredicate(format: "%K IN %@", gearTypes.map({ $0.rawValue }))
    }
    
}

// MARK: - Sort Descriptors

extension Tag {
    
    static func sortedByPositionDescriptor(ascending: Bool = true) -> NSSortDescriptor {
        NSSortDescriptor(keyPath: \Tag.position, ascending: ascending)
    }
    
    static func sortedByArchivedDateDescriptor(ascending: Bool = false) -> NSSortDescriptor {
        NSSortDescriptor(keyPath: \Tag.archivedDate, ascending: ascending)
    }
    
}
