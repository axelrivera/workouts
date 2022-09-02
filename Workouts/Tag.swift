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
private let UUIDKey = "uuid"
private let GearTypeKey = "gearTypeValue"
private let DefaultKey = "isDefault"

extension Tag {
    enum GearType: String, Identifiable, CaseIterable {
        case none, bike, shoes
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .none: return NSLocalizedString("None", comment: "Label")
            case .bike: return NSLocalizedString("Bike", comment: "Label")
            case .shoes: return NSLocalizedString("Shoes", comment: "Label")
            }
        }
        
        var displaySport: Sport? {
            switch self {
            case .none:
                return nil
            case .bike:
                return .cycling
            case .shoes:
                return .running
            }
        }
        
        static func displayValues(for sport: Sport) -> [GearType] {
            switch sport {
            case .cycling:
                return [.none, .bike]
            case .running, .walking:
                return [.none, .shoes]
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
    @NSManaged var isDefault: Bool
    
    @NSManaged private(set) var archivedDate: Date?
    @NSManaged private(set) var deletedDate: Date?
    
    @NSManaged var position: NSNumber
        
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
    
    func archiveTag() {
        archivedDate = Date()
    }
    
    func restoreTag() {
        archivedDate = nil
        position = NSNumber(value: Int.max)
    }
    
    func deleteTag() {
        deletedDate = Date()
        archivedDate = nil
    }
    
}

// MARK: Fetching

extension Tag {
    
    static func request() -> NSFetchRequest<Tag> {
        NSFetchRequest<Tag>(entityName: entityName)
    }
    
    static func predicate(for uuid: UUID) -> NSPredicate {
        NSPredicate(format: "%K == %@", UUIDKey, uuid as NSUUID)
    }
    
    static func find(using uuid: UUID, in context: NSManagedObjectContext) -> Tag? {
        context.performAndWait {
            let request = request()
            request.returnsObjectsAsFaults = false
            request.predicate = predicate(for: uuid)
            return try? context.fetch(request).first
        }
    }
    
    static func find(uuids: [UUID], in context: NSManagedObjectContext) -> [Tag] {
        context.performAndWait {
            let request = request()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "%K IN %@", UUIDKey, uuids)
            request.sortDescriptors = [sortedByPositionDescriptor()]
            
            do {
                return try context.fetch(request)
            } catch {
                return []
            }
        }
    }
    
    static func defaultTags(sport: Sport, in context: NSManagedObjectContext) -> [UUID] {
        context.performAndWait {
            let request = NSFetchRequest<NSDictionary>(entityName: Tag.entityName)
            request.predicate = defaultTagsPredicate(sport: sport)
            request.resultType = .dictionaryResultType
            request.returnsObjectsAsFaults = false
            request.propertiesToFetch = ["uuid"]
            
            do {
                let dictionaries = try context.fetch(request)
                return dictionaries.compactMap { (dictionary) -> UUID? in
                    return dictionary["uuid"] as? UUID
                }
            } catch {
                return []
            }
        }
    }
    
    @discardableResult
    static func insert(into context: NSManagedObjectContext, viewModel: TagEditViewModel, position: Int?) -> Tag {
        context.performAndWait {
            let tag = Tag(context: context)
            tag.uuid = UUID()
            updateValues(for: tag, viewModel: viewModel, position: position ?? 0, in: context)
            return tag
        }
    }
    
    static func updateValues(for tag: Tag, viewModel: TagEditViewModel, position: Int?, in context: NSManagedObjectContext) {
        context.performAndWait {
            tag.name = viewModel.name
            tag.color = UIColor(viewModel.color)
            tag.gearType = viewModel.gearType
            tag.isDefault = viewModel.isDefault
            
            if let position = position {
                tag.position = NSNumber(value: position)
            }
        }
    }
    
}

// MARK: - Predicates

extension Tag {
    
    static func visiblePredicate(using uuids: [UUID]) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            notDeletedPredicate(), notArchivedPredicate(), predicate(using: uuids)
        ])
    }

    static func activePredicate(using uuids: [UUID]) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            notDeletedPredicate(), predicate(using: uuids)
        ])
    }
    
    static func predicate(using uuids: [UUID]) -> NSPredicate {
        NSPredicate(format: "%K IN %@", UUIDKey, uuids)
    }
    
    static func activePredicate(name: String? = nil, gearTypes: [GearType] = []) -> NSPredicate {
        var predicates = [notArchivedPredicate(), notDeletedPredicate()]
        
        if let name = name {
            predicates.append(namePredicate(name))
        }
        
        if gearTypes.isPresent {
            predicates.append(gearTypesPredicate(gearTypes))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    static func defaultTagsPredicate(sport: Sport) -> NSPredicate {
        var predicates = [notArchivedPredicate(), notDeletedPredicate()]
        predicates.append(NSPredicate(format: "%K == %@", DefaultKey, NSNumber(booleanLiteral: true)))
        predicates.append(gearTypesPredicate(sport.defaultGearTypes))
        
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
    
    static func gearTypesPredicate(_ gearTypes: [GearType]) -> NSPredicate {
        NSPredicate(format: "%K IN %@", GearTypeKey, gearTypes.map({ $0.rawValue }))
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
