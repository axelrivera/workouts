//
//  TagsDisplayManager.swift
//  Workouts
//
//  Created by Axel Rivera on 11/5/21.
//

import SwiftUI
import CoreData

enum TagPickerSegment: String, Identifiable, CaseIterable {
    case active, archived
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

final class TagsDisplayManager: ObservableObject {
    private let context: NSManagedObjectContext
    let dataProvider: DataProvider
    let tagProvider: TagProvider
    let workoutTagProvider: WorkoutTagProvider
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.dataProvider = DataProvider(context: context)
        self.tagProvider = TagProvider(context: context)
        self.workoutTagProvider = WorkoutTagProvider(context: context)
    }
}

extension TagsDisplayManager {
    enum TagError: Error {
        case notFound
    }
    
    func summaryViewModels(for tags: [Tag]) -> [TagSummaryViewModel] {
        tags.map { tag -> TagSummaryViewModel in
            let identifiers = workoutTagProvider.workoutIdentifiers(forTag: tag.uuid)
            
            var viewModel: TagSummaryViewModel = tag.viewModel()
            if let  dictionary = try? dataProvider.fetchStatsSummary(for: identifiers) {
                viewModel.updateValues(dictionary)
            }

            return viewModel
        }
    }
    
    func tags(forSegment segment: TagPickerSegment) -> [TagSummaryViewModel] {
        let tags = segment == .active ? tagProvider.activeTags() : tagProvider.archivedTags()
        return summaryViewModels(for: tags)
    }
    
    func viewModel(forTag uuid: UUID) throws -> TagEditViewModel {
        guard let tag = Tag.find(using: uuid, in: context) else {
            throw TagError.notFound
        }
        return tag.editViewModel()
    }
    
    func archiveTag(for uuid: UUID) throws {
        guard let tag = Tag.find(using: uuid, in: context) else { throw TagManagerError.notFound }
        
        try context.performAndWait {
            tag.archiveTag()
            try context.save()
            context.refresh(tag, mergeChanges: true)
        }
    }
    
    func restoreTag(for uuid: UUID) throws {
        guard let tag = Tag.find(using: uuid, in: context) else { throw TagManagerError.notFound }
        
        let totalTagsWithName = tagProvider.numberOfTags(with: tag.name)
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
            tag.position = NSNumber(value: Int.max)
            try context.save()
            context.refresh(tag, mergeChanges: true)
        }
    }
    
}
