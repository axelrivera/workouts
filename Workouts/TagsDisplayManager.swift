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
    
    let context: NSManagedObjectContext
    let dataProvider: DataProvider
    let tagProvider: TagProvider
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.dataProvider = DataProvider(context: context)
        self.tagProvider = TagProvider(context: context)
    }
    
    @Published var tags = [TagSummaryViewModel]()
    
    func reload() {
        let tags = tagProvider.activeTags()
        
        let viewModels: [TagSummaryViewModel] = tags.compactMap { tag -> TagSummaryViewModel? in
            let identifiers = tag.workouts.map({ $0.identifier })
            if identifiers.isEmpty { return nil }
            
            var viewModel: TagSummaryViewModel = tag.viewModel()
            if let  dictionary = try? dataProvider.fetchStatsSummary(for: identifiers) {
                viewModel.updateValues(dictionary)
            }
            
            return viewModel
        }
        
        DispatchQueue.main.async {
            withAnimation {
                self.tags = viewModels
            }
        }
    }
}
