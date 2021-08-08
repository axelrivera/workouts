//
//  ModelVersion.swift
//  Workouts
//
//  Created by Axel Rivera on 7/19/21.
//

import CoreData

enum ModelVersion: String, CaseIterable {
    case v1 = "Workouts"
    case v2 = "Workouts 2"
    case v3 = "Workouts 3"
    
    static var current: ModelVersion {
        guard let current = allCases.last else {
            fatalError("no model versions found")
        }
        return current
    }
}

extension ModelVersion {
    
    func next() -> ModelVersion? {
        switch self {
        case .v1: return .v2
        case .v2: return .v3
        case .v3: return nil
        }
    }
    
}
