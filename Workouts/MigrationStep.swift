//
//  MigrationStep.swift
//  Workouts
//
//  Created by Axel Rivera on 7/19/21.
//

import CoreData

class MigrationStep {
    let sourceModel: NSManagedObjectModel
    let destinationModel: NSManagedObjectModel
    let mappingModel: NSMappingModel
    
    init(sourceVersion: ModelVersion, destinationVersion: ModelVersion) {
        let sourceModel = NSManagedObjectModel.managedObjectModel(forResource: sourceVersion.rawValue)
        let destinationModel = NSManagedObjectModel.managedObjectModel(forResource: destinationVersion.rawValue)
        
        guard let mappingModel = MigrationStep.mappingModel(fromSourceModel: sourceModel, toDestinationModel: destinationModel) else {
            fatalError("expected modal mapping not present")
        }
        
//        if sourceVersion == .v2 && destinationVersion == .v3 {
//            let fullClassName = NSStringFromClass(Workout2ToWorkout3MigrationPolicy.self)
//            mappingModel.entityMappings.forEach { $0.entityMigrationPolicyClassName = fullClassName}
//        }
        
        self.sourceModel = sourceModel
        self.destinationModel = destinationModel
        self.mappingModel = mappingModel
    }
    
    // MARK: - Mapping
    
    private static func mappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel) -> NSMappingModel? {
        guard let customMapping = customMappingModel(fromSourceModel: sourceModel, toDestinationModel: destinationModel) else {
            return inferredMappingModel(fromSourceModel:sourceModel, toDestinationModel: destinationModel)
        }
        
        return customMapping
    }
    
    private static func inferredMappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel) -> NSMappingModel? {
        return try? NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
    }
    
    private static func customMappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel) -> NSMappingModel? {
        NSMappingModel(from: [Bundle.main], forSourceModel: sourceModel, destinationModel: destinationModel)
    }
    
}
