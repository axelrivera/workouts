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
    private(set) var metaProvider: MetadataProvider
    
    @Published var tags = [Tag]()
    @Published var selectedTags = [Tag]()
    @Published var archived = [Tag]()
    @Published var showSegmentedControl = false
    
    private(set) var sport: Sport?
    private(set) var workoutIdentifier: UUID?
    
    private var workout: WorkoutMetadata?
    
    init(context: NSManagedObjectContext, sport: Sport? = nil, workoutIdentifier: UUID? = nil) {
        self.context = context
        self.sport = sport
        self.workoutIdentifier = workoutIdentifier
        provider = TagProvider(context: context)
        metaProvider = MetadataProvider(context: context)
    }
}

extension TagManager {
    
    func fetchWorkout() throws -> WorkoutMetadata {
        guard let identifier = workoutIdentifier else { throw TagManagerError.missingIdentifier }
        return try metaProvider.fetchWorkout(identifier: identifier)
    }
    
    func reloadData() {
        let tags = provider.activeTags(sport: sport)
        self.tags = tags
        
        if let _ = workoutIdentifier {
            do {
                let workout = try fetchWorkout()
                self.workout = workout
                self.selectedTags = Array(workout.tags)
                self.showSegmentedControl = false
            } catch {
                Log.debug("failed to create metadata object: \(error.localizedDescription)")
            }
        } else {
            let archived = provider.archivedTags()
            self.archived = archived
            self.showSegmentedControl = archived.isPresent
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
            tag.archivedDate = Date()
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
            
            tag.archivedDate = nil
            try context.save()
        }
    }
    
    func deleteTag(for uuid: UUID) throws {
        guard let tag = Tag.find(using: uuid, in: context) else { throw TagManagerError.notFound }
        
        try context.performAndWait {
            tag.deletedDate = Date()
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
        guard let workout = workout else { throw TagManagerError.missingIdentifier }
        
        try context.performAndWait {
            workout.tags.insert(tag)
            try context.save()
        }
    }
    
    func removeTagFromWorkout(_ tag: Tag) throws {
        guard let workout = workout else { throw TagManagerError.missingIdentifier }
        
        try context.performAndWait {
            workout.tags.remove(tag)
            try context.save()
        }
    }
    
}

// MARK: - Selection

extension TagManager {
    
    func isSelected(tag: Tag) -> Bool {
        selectedTags.contains(tag)
    }
    
    func toggle(tag: Tag) throws {        
        if let index = selectedTags.firstIndex(of: tag) {
            try removeTagFromWorkout(tag)
            selectedTags.remove(at: index)
        } else {
            try addTagToWorkout(tag)
            selectedTags.append(tag)
        }
    }
    
}

// MARK: Workout Helper

extension Workout {
    
    func tagManager() -> TagManager {
        TagManager(context: managedObjectContext!, sport: sport, workoutIdentifier: workoutIdentifier)
    }
    
}
