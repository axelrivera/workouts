//
//  WorkoutMetadataCache.swift
//  Workouts
//
//  Created by Axel Rivera on 11/8/21.
//

import Foundation
import CoreData

final class WorkoutCache {
    
    private let cache = NSCache<NSString, WorkoutCacheObject>()
    private let lock = NSLock()
    
    private var _metaProvider: MetadataProvider?
    private var _workoutTagProvider: WorkoutTagProvider?
    
    private var metaProvider: MetadataProvider {
        guard let provider = _metaProvider else { fatalError("missing metadata provider") }
        return provider
    }
    
    private var workoutTagProvider: WorkoutTagProvider {
        guard let provider = _workoutTagProvider else { fatalError("missing workout tag provider") }
        return provider
    }
    
    static let shared = WorkoutCache()
    
    func loadProviders(withContext context: NSManagedObjectContext) {
        _metaProvider = MetadataProvider(context: context)
        _workoutTagProvider = WorkoutTagProvider(context: context)
    }
    
    func get(identifier: UUID) -> WorkoutCacheObject? {
        lock.lock(); defer { lock.unlock() }
        return cache.object(forKey: identifier.uuidString as NSString)
    }
    
    func set(object: WorkoutCacheObject, identifier: UUID) {
        lock.lock(); defer { lock.unlock() }
        cache.setObject(object, forKey: identifier.uuidString as NSString)
    }
    
    func isFavorite(identifier: UUID) -> Bool {
        if let isFavorite = get(identifier: identifier)?.isFavorite {
            return isFavorite
        } else {
            let isFavorite = metaProvider.isFavorite(identifier)
            set(isFavorite: isFavorite, identifier: identifier)
            return isFavorite
        }
    }
    
    func set(isFavorite: Bool, identifier: UUID) {
        if let object = get(identifier: identifier) {
            object.isFavorite = isFavorite
        } else {
            let newObject = WorkoutCacheObject(id: identifier, isFavorite: isFavorite)
            set(object: newObject, identifier: identifier)
        }
        
        NotificationCenter.default.post(
            name: .workoutCacheUpdated,
            object: nil,
            userInfo: [Notification.remoteWorkoutKey: identifier]
        )
    }
    
    func tags(for identifier: UUID) -> [TagLabelViewModel] {
        if let tags = get(identifier: identifier)?.tags {
            return tags
        } else {
            let tags: [TagLabelViewModel] = workoutTagProvider.visibleTags(forWorkout: identifier).map { $0.viewModel() }
            set(tags: tags, identifier: identifier)
            return tags
        }
    }
    
    func set(tags: [TagLabelViewModel], identifier: UUID) {
        if let object = get(identifier: identifier) {
            object.tags = tags
        } else {
            let newObject = WorkoutCacheObject(id: identifier, tags: tags)
            set(object: newObject, identifier: identifier)
        }
        
        NotificationCenter.default.post(
            name: .workoutCacheUpdated,
            object: nil,
            userInfo: [Notification.remoteWorkoutKey: identifier]
        )
    }
    
    func purgeObject(with identifier: UUID) {
        lock.lock(); defer { lock.unlock() }
        cache.removeObject(forKey: identifier.uuidString as NSString)
        
        NotificationCenter.default.post(
            name: .workoutCacheUpdated,
            object: nil,
            userInfo: [Notification.remoteWorkoutKey: identifier]
        )
    }
    
    func resetAll() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAllObjects()
    }
    
}

extension Notification.Name {
    
    static var workoutCacheUpdated = Notification.Name(rawValue: "workoutCacheUpdated")
    
}
