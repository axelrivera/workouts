//
//  MigrationError.swift
//  Workouts
//
//  Created by Axel Rivera on 7/19/21.
//

import Foundation

enum CoreDataMigrationError: Error {
  case mappingModelNotFound
  case managedObjectModelNotFound
  case managedObjectModelNotLoaded
  case metadataNotLoaded
  case noCompatibleStoreVersionFound
}

extension CoreDataMigrationError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .mappingModelNotFound: return "mapping values not found"
        case .managedObjectModelNotFound: return "managed object model not found"
        case .managedObjectModelNotLoaded: return "managed object model not loaded"
        case .metadataNotLoaded: return "metadata not loaded"
        case .noCompatibleStoreVersionFound: return "no compatible store version found"
        }
    }
    
}

