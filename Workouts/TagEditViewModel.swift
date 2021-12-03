//
//  TagEditViewModel.swift
//  Workouts
//
//  Created by Axel Rivera on 10/31/21.
//

import SwiftUI

class TagEditViewModel: ObservableObject, Hashable, Identifiable {
    static func == (lhs: TagEditViewModel, rhs: TagEditViewModel) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum Mode {
        case add, edit
    }
    
    let id: String
    let uuid: UUID
    let mode: Mode
    let sport: Sport?
    let availableGearTypes: [Tag.GearType]
    
    @Published var name: String = ""
    @Published var color: Color = .accentColor
    @Published var gearType: Tag.GearType = .none
    @Published var isDefault: Bool = false
    @Published var isArchived: Bool = false
    
    init(uuid: UUID, mode: Mode, sport: Sport? = nil) {
        self.id = uuid.uuidString
        self.uuid = uuid
        self.mode = mode
        self.sport = sport
        
        if let sport = sport {
            availableGearTypes = Tag.GearType.displayValues(for: sport)
        } else {
            availableGearTypes = Tag.GearType.allCases
        }
    }
}

extension Tag {
    
    static func addViewModel(sport: Sport? = nil) -> TagEditViewModel {
        TagEditViewModel(uuid: UUID(), mode: .add, sport: sport)
    }
        
    func editViewModel(sport: Sport? = nil) -> TagEditViewModel {
        let viewModel = TagEditViewModel(uuid: uuid, mode: .edit, sport: sport)
        viewModel.name = name
        
        if let color = color {
            viewModel.color = Color(color)
        }
        
        viewModel.gearType = gearType
        viewModel.isDefault = isDefault
        viewModel.isArchived = archivedDate != nil
        
        return viewModel
    }
    
}
