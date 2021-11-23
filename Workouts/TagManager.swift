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
            return "Maximum number of tags reached."
        case .notUnique:
            return "There's a tag with the same name."
        case .notFound:
            return "Workout not found."
        case .missingIdentifier:
            return "Missing workout identifier."
        }
    }
}

class TagManager: ObservableObject {
    private(set) var context: NSManagedObjectContext
    private(set) var provider: TagProvider
    private(set) var workoutTagProvider: WorkoutTagProvider
    
    @Published var tags = [Tag]()
    @Published var selectedTags = Set<Tag>()
    @Published var archived = [Tag]()
    
    private(set) var sport: Sport?
    private(set) var workoutIdentifier: UUID?
        
    init(context: NSManagedObjectContext, sport: Sport? = nil, workoutIdentifier: UUID? = nil) {
        self.context = context
        self.sport = sport
        self.workoutIdentifier = workoutIdentifier
        provider = TagProvider(context: context)
        workoutTagProvider = WorkoutTagProvider(context: context)
    }
}

extension TagManager {
    
    func reloadData() {
        tags = provider.activeTags(sport: sport)
        
        if let identifier = workoutIdentifier {
            let selectedTags = workoutTagProvider.visibleTags(forWorkout: identifier)
            self.selectedTags = Set<Tag>(selectedTags)
        } else {
            archived = provider.archivedTags()
        }
    }
    
    func addTag(viewModel: TagEditViewModel) throws {
        if viewModel.mode == .add && provider.numberOfTags(with: viewModel.name) > 0 {
            throw TagManagerError.notUnique
        }
        
        context.performAndWait {
            do {
                if let tag = Tag.find(using: viewModel.uuid, in: context) {
                    Tag.updateValues(for: tag, viewModel: viewModel, in: context)
                } else {
                    let newTag = Tag.insert(into: context, viewModel: viewModel)
                    self.tags.append(newTag)
                }
                
                try context.save()
            } catch {
                Log.debug("failed to add tag: \(error.localizedDescription)")
            }
        }
    }
    
    func archiveTag(for uuid: UUID) throws {
        guard let tag = Tag.find(using: uuid, in: context) else { throw TagManagerError.notFound }
        
        try context.performAndWait {
            tag.archiveTag()
            try context.save()
        }
    }
    
    func restoreTag(for uuid: UUID) throws {
        guard let tag = Tag.find(using: uuid, in: context) else { throw TagManagerError.notFound }
        
        let totalTagsWithName = provider.numberOfTags(with: tag.name)
        let updateName = totalTagsWithName > 0
        
        try context.performAndWait {
            if updateName {
                let newName = String(
                    format: "%@ - Restored %@",
                    tag.name,
                    Date().formatted(date: .numeric, time: .standard)
                )
                tag.name = newName
            }
            
            tag.restoreTag()
            try context.save()
        }
    }
    
    func deleteTag(for uuid: UUID) throws {
        guard let tag = Tag.find(using: uuid, in: context) else { throw TagManagerError.notFound }
        
        try context.performAndWait {
            tag.deleteTag()
            try context.save()
        }
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
        try workoutTagProvider.addWorkoutTag(for: workoutId, tag: tag.uuid)
    }
    
    func removeTagFromWorkout(_ tag: Tag) throws {
        guard let workoutId = workoutIdentifier else { throw TagManagerError.missingIdentifier }
        try workoutTagProvider.deleteWorkoutTag(for: workoutId, tag: tag.uuid)
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
