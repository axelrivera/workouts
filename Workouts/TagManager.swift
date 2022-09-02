//
//  TagManager.swift
//  Workouts
//
//  Created by Axel Rivera on 10/31/21.
//

import SwiftUI
import CoreData
import Combine

enum TagManagerError: Error {
    case maxReached, notUnique, notFound, missingIdentifier
}

extension TagManagerError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .maxReached:
            return NSLocalizedString("Maximum number of tags reached.", comment: "Tag error")
        case .notUnique:
            return NSLocalizedString("There's a tag with the same name.", comment: "Tag error")
        case .notFound:
            return NSLocalizedString("Workout not found.", comment: "Tag error")
        case .missingIdentifier:
            return NSLocalizedString("Missing workout identifier.", comment: "Tag error")
        }
    }
}

class TagManager: ObservableObject {
    private(set) var context: NSManagedObjectContext
    private(set) var backgroundContext: NSManagedObjectContext
    private(set) var provider: TagProvider
    private(set) var workoutTagProvider: WorkoutTagProvider
    
    @Published var tags = [Tag]()
    @Published var selectedTags = Set<Tag>()
    @Published var archived = [Tag]()
    
    private(set) var sport: Sport?
    private(set) var workoutIdentifier: UUID?
            
    init(context: NSManagedObjectContext, sport: Sport? = nil, workoutIdentifier: UUID? = nil) {
        self.context = context
        self.backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.backgroundContext.parent = context
        
        self.sport = sport
        self.workoutIdentifier = workoutIdentifier
        provider = TagProvider(context: context)
        workoutTagProvider = WorkoutTagProvider(context: context)
    }
}

extension TagManager {
    
    func resetCache() {
        WorkoutStorage.resetAll()
        NotificationCenter.default.post(
            name: .refreshWorkoutsFilter,
            object: nil
        )
    }
    
    func reloadData() {
        tags = provider.activeTags(sport: sport)
        
        if let identifier = workoutIdentifier {
            let selectedTags = workoutTagProvider.visibleTags(forWorkout: identifier)
            self.selectedTags = Set<Tag>(selectedTags)
        } else {
            archived = provider.archivedTags()
        }
    }
    
    func updatePositions() {
        backgroundContext.perform { [unowned self] in
            for index in 0 ..< tags.count {
                let tag = tags[index]
                tag.position = NSNumber(value: index + 1)
            }
            
            do {
                try backgroundContext.save()
                try context.save()
                
                DispatchQueue.main.async {
                    self.resetCache()
                }
            } catch {
                Log.debug("failed to update position for tags")
            }
        }
    }
    
    func addTag(viewModel: TagEditViewModel, isInsert: Bool) throws {
        if viewModel.mode == .add && provider.numberOfTags(with: viewModel.name) > 0 {
            throw TagManagerError.notUnique
        }
        
        context.performAndWait {
            do {
                if let tag = Tag.find(using: viewModel.uuid, in: context) {
                    Tag.updateValues(for: tag, viewModel: viewModel, position: nil, in: context)
                } else {
                    let total = provider.totalActiveTags
                    let position = total + 1
                    let newTag = Tag.insert(into: context, viewModel: viewModel, position: position)
                    if isInsert {
                        self.tags.insert(newTag, at: 0)
                    } else {
                        self.tags.append(newTag)
                    }
                }
                
                try context.save()
            } catch {
                Log.debug("failed to add tag: \(error.localizedDescription)")
            }
        }
        
        resetCache()
    }
    
    func archiveTag(for uuid: UUID) throws {
        guard let tag = Tag.find(using: uuid, in: context) else { throw TagManagerError.notFound }
        
        try context.performAndWait {
            tag.archiveTag()
            try context.save()
        }
        
        resetCache()
    }
    
    func restoreTag(for uuid: UUID) throws {
        guard let tag = Tag.find(using: uuid, in: context) else { throw TagManagerError.notFound }
        
        let totalTagsWithName = provider.numberOfTags(with: tag.name)
        let updateName = totalTagsWithName > 0
        
        try context.performAndWait {
            if updateName {
                tag.name = TagStrings.restoreMessage(name: tag.name, date: Date())
            }
            
            tag.restoreTag()
            tag.position = NSNumber(value: tags.count + 1)
            try context.save()
        }
        
        resetCache()
    }
    
    func deleteTag(for uuid: UUID) throws {
        guard let tag = Tag.find(using: uuid, in: context) else { throw TagManagerError.notFound }
        
        try context.performAndWait {
            tag.deleteTag()
            try context.save()
        }
        
        resetCache()
    }
    
    func deleteTags(atOffsets offsets: IndexSet) throws {
        let ids = offsets.map({ tags[$0].uuid })
        try ids.forEach({ try deleteTag(for: $0) })
        
        withAnimation {
            tags.remove(atOffsets: offsets)
        }
    }
    
    func addTagToWorkout(_ tag: Tag) throws {
        guard let workoutId = workoutIdentifier else { throw TagManagerError.missingIdentifier }
        
        try context.performAndWait {
            try workoutTagProvider.addWorkoutTag(for: workoutId, tag: tag.uuid)
        }
    }
    
    func removeTagFromWorkout(_ tag: Tag) throws {
        guard let workoutId = workoutIdentifier else { throw TagManagerError.missingIdentifier }
        
        try context.performAndWait {
            try workoutTagProvider.deleteWorkoutTag(for: workoutId, tag: tag.uuid)
        }
    }
    
}

// MARK: - Selection

extension TagManager {
    
    func isSelected(tag: Tag) -> Bool {
        selectedTags.contains(tag)
    }
    
    func toggle(tag: Tag) throws {
        if isSelected(tag: tag) {
            try removeTagFromWorkout(tag)
            selectedTags.remove(tag)
        } else {
            try addTagToWorkout(tag)
            selectedTags.insert(tag)
        }
    }
    
}

// MARK: Workout Helper

extension Workout {
    
    func tagManager() -> TagManager {
        TagManager(context: managedObjectContext!, sport: sport, workoutIdentifier: workoutIdentifier)
    }
    
}
