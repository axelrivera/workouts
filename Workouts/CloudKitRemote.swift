//
//  CloudKitRemote.swift
//  Workouts
//
//  Created by Axel Rivera on 12/16/21.
//

import Foundation
import CoreData

class CloudKitRemote {
    
    private var tagProvider: TagProvider!
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
    }
    
    func load(context: NSManagedObjectContext) {
        tagProvider = TagProvider(context: context)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        NSUbiquitousKeyValueStore.default.synchronize()
        
        tagProvider.createInitialTagsIfNeeded()
    }
    
    @objc
    func storeDidChange(_ notification: Notification) {
        tagProvider.createInitialTagsIfNeeded()
    }
    
    static var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
    
}
