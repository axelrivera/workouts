//
//  ManagedObjectModel+Migration.swift
//  Workouts
//
//  Created by Axel Rivera on 7/19/21.
//

import CoreData

extension NSManagedObjectModel {
    
    static func managedObjectModel(forResource resource: String) -> NSManagedObjectModel {
        let mainBundle = Bundle.main
        let subdirectory = "Workouts.momd"
        let omoURL = mainBundle.url(forResource: resource, withExtension: "omo", subdirectory: subdirectory) // optimised model file
        let momURL = mainBundle.url(forResource: resource, withExtension: "mom", subdirectory: subdirectory)
        
        guard let url = omoURL ?? momURL else {
            fatalError("unable to find model in bundle")
        }
        
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("unable to load model in bundle")
        }
        
        return model
    }
    
    static func compatibleModelForStoreMetadata(_ metadata: [String : Any]) -> NSManagedObjectModel? {
        let mainBundle = Bundle.main
        return NSManagedObjectModel.mergedModel(from: [mainBundle], forStoreMetadata: metadata)
    }
    
}
