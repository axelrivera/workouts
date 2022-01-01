//
//  WorkoutCacheObject.swift
//  Workouts
//
//  Created by Axel Rivera on 11/8/21.
//

import Foundation
import Combine

final class WorkoutCacheObject: Hashable, Identifiable {
    static func == (lhs: WorkoutCacheObject, rhs: WorkoutCacheObject) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: UUID
    var isFavorite: Bool
    var tags: [TagLabelViewModel]?
    
    init(id: UUID, isFavorite: Bool = false, tags: [TagLabelViewModel]? = nil) {
        self.id = id
        self.isFavorite = isFavorite
        self.tags = tags
    }
}
