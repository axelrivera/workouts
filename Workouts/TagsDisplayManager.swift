//
//  TagsDisplayManager.swift
//  Workouts
//
//  Created by Axel Rivera on 11/5/21.
//

import SwiftUI
import CoreData

enum TagPickerSegments: String, Identifiable, CaseIterable {
    case active, archived
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

final class TagsDisplayManager: ObservableObject {
    
    let dataProvider: DataProvider
    let tagProvider: TagProvider
    let workoutTagProvider: WorkoutTagProvider
    
    @Published var currentSegment = TagPickerSegments.active
    @Published var active = [TagSummaryViewModel]()
    @Published var archived = [TagSummaryViewModel]()
    
    var tags: [TagSummaryViewModel] {
        if currentSegment == .active || archived.isEmpty {
            return active
        } else {
            return archived
        }
    }
    
    init(context: NSManagedObjectContext) {
        self.dataProvider = DataProvider(context: context)
        self.tagProvider = TagProvider(context: context)
        self.workoutTagProvider = WorkoutTagProvider(context: context)
    }
}

extension TagsDisplayManager {
    
    var showPicker: Bool {
        archived.isPresent
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
    
    func reload() {
        let activeTags = tagProvider.activeTags()
        let archivedTags = tagProvider.archivedTags()
        
        let active = summaryViewModels(for: activeTags)
        let archived = summaryViewModels(for: archivedTags)

        DispatchQueue.main.async {
            withAnimation {
                self.active = active
                self.archived = archived
            }
        }
    }
    
}
