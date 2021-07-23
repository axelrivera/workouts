//
//  CoreDataMigrator.swift
//  Workouts
//
//  Created by Axel Rivera on 7/19/21.
//

import CoreData

protocol CoreDataMigratorProtocol {
    func requiresMigration(at storeURL: URL, toVersion version: ModelVersion) -> Bool
    func migrateStore(at storeURL: URL, toVersion version: ModelVersion)
}

class CoreDataMigrator: CoreDataMigratorProtocol {
    
    // MARK: - Check
    
    func requiresMigration(at storeURL: URL, toVersion version: ModelVersion) -> Bool {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL) else {
            return false
        }
        
        return (ModelVersion.compatibleVersionForStoreMetadata(metadata) != version)
    }
    
    func migrateStore(at storeURL: URL, toVersion version: ModelVersion) {
        forceWALCheckpointingForStore(at: storeURL)
        
        var currentURL = storeURL
        let migrationSteps = self.migrationStepsForStore(at: storeURL, toVersion: version)
        
        for migrationStep in migrationSteps {
            let manager = NSMigrationManager(sourceModel: migrationStep.sourceModel, destinationModel: migrationStep.destinationModel)
            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
            
            do {
                try manager.migrateStore(
                    from: currentURL,
                    sourceType: NSSQLiteStoreType,
                    options: nil,
                    with: migrationStep.mappingModel,
                    toDestinationURL: destinationURL,
                    destinationType: NSSQLiteStoreType,
                    destinationOptions: nil
                )
            } catch {
                fatalError("failed attempting to migrate from \(migrationStep.sourceModel) to \(migrationStep.destinationModel), error: \(error.localizedDescription)")
            }
            
            if currentURL != storeURL {
                //Destroy intermediate step's store
                NSPersistentStoreCoordinator.destroyStore(at: currentURL)
            }
            
            currentURL = destinationURL
        }
        
        NSPersistentStoreCoordinator.replaceStore(at: storeURL, withStoreAt: currentURL)
        
        if (currentURL != storeURL) {
            NSPersistentStoreCoordinator.destroyStore(at: currentURL)
        }
    }
    
    private func migrationStepsForStore(at storeURL: URL, toVersion destinationVersion: ModelVersion) -> [MigrationStep] {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL), let sourceVersion = ModelVersion.compatibleVersionForStoreMetadata(metadata) else {
            fatalError("unknown store version at URL \(storeURL)")
        }
        
        return migrationSteps(fromSourceVersion: sourceVersion, toDestinationVersion: destinationVersion)
    }
    
    private func migrationSteps(fromSourceVersion sourceVersion: ModelVersion, toDestinationVersion destinationVersion: ModelVersion) -> [MigrationStep] {
        var sourceVersion = sourceVersion
        var migrationSteps = [MigrationStep]()
        
        while sourceVersion != destinationVersion, let nextVersion = sourceVersion.next() {
            let migrationStep = MigrationStep(sourceVersion: sourceVersion, destinationVersion: nextVersion)
            migrationSteps.append(migrationStep)
            sourceVersion = nextVersion
        }
        
        return migrationSteps
    }
    
    // MARK: - WAL
    
    func forceWALCheckpointingForStore(at storeURL: URL) {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL), let currentModel = NSManagedObjectModel.compatibleModelForStoreMetadata(metadata) else {
            return
        }
        
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)
            
            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store = persistentStoreCoordinator.addPersistentStore(at: storeURL, options: options)
            try persistentStoreCoordinator.remove(store)
        } catch {
            fatalError("failed to force WAL checkpointing, error: \(error.localizedDescription)")
        }
    }
}

private extension ModelVersion {
    
    static func compatibleVersionForStoreMetadata(_ metadata: [String : Any]) -> ModelVersion? {
        let compatibleVersion = ModelVersion.allCases.first {
            let model = NSManagedObjectModel.managedObjectModel(forResource: $0.rawValue)
            return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }
        
        return compatibleVersion
    }
    
}
