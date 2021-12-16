//
//  WorkoutStorage.swift
//  Workouts
//
//  Created by Axel Rivera on 12/7/21.
//

import Foundation
import CoreData
import CoreLocation
import SwiftUI

final class WorkoutStorage {
    typealias WorkoutID = UUID
    
    private var workouts = [WorkoutID: WorkoutViewModel]()
    private let imageCache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(label: "WorkoutStorage.queue")
    
    private var context: NSManagedObjectContext
    private var metaProvider: MetadataProvider
    private var workoutTagProvider: WorkoutTagProvider
    
    init(context: NSManagedObjectContext) {
        self.context = context
        metaProvider = MetadataProvider(context: context)
        workoutTagProvider = WorkoutTagProvider(context: context)
        imageCache.countLimit = 20
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
}

extension WorkoutStorage {
    
    func viewModel(forWorkout workout: Workout) -> WorkoutViewModel {
        queue.sync {
            let id = workout.workoutIdentifier
            
            if let viewModel = workouts[id] {
                return viewModel
            }
            
            let viewModel = WorkoutViewModel(workout: workout)
            viewModel.isFavorite = metaProvider.isFavorite(id)
            viewModel.tags = workoutTagProvider.visibleTags(forWorkout: id).map({ $0.viewModel() })
            
            workouts[workout.workoutIdentifier] = viewModel
            return viewModel
        }
        
    }
    
    func resetAll() {
        queue.async { [unowned self] in
            workouts = [WorkoutID: WorkoutViewModel]()
        }
    }
    
}

// MARK: - Workout Properties

extension WorkoutStorage {
    
    func set(coordinates: [CLLocationCoordinate2D], forID id: WorkoutID) {
        queue.async { [unowned self] in
            if let viewModel = workouts[id] {
                resetImages(forID: id)
                viewModel.coordinates = coordinates
                DispatchQueue.main.async {
                    postNotification(forViewModel: viewModel)
                }
            }
        }
    }
    
    func isPendingLocation(forID id: WorkoutID) -> Bool {
        queue.sync {
            if let viewModel = workouts[id] {
                return viewModel.isPendingLocation
            } else {
                return false
            }
        }
    }
    
    func coordinates(forID id: WorkoutID) -> [CLLocationCoordinate2D] {
        queue.sync {
            if let viewModel = workouts[id] {
                return viewModel.coordinates
            } else {
                return []
            }
        }
    }
    
}

// MARK:  Images

extension WorkoutStorage {
    
    func getCachedImage(forID id: WorkoutID, scheme: ColorScheme) -> UIImage? {
        queue.sync {
            let url = URL.cachedMapImageURL(id: id, scheme: scheme)
            return imageCache.object(forKey: url.path as NSString)
        }
    }
    
    func getDiskImage(forID id: WorkoutID, scheme: ColorScheme) -> UIImage? {
        queue.sync {
            let url = URL.cachedMapImageURL(id: id, scheme: scheme)
            return FileManager.localImage(at: url)
        }
    }
    
    func set(image: UIImage, forID id: WorkoutID, scheme: ColorScheme, memoryOnly: Bool = false) {
        queue.async { [unowned self] in
            let url = URL.cachedMapImageURL(id: id, scheme: scheme)
            imageCache.setObject(image, forKey: url.path as NSString)
            if !memoryOnly {
                do {
                    try FileManager.createImagesCacheDirectoryIfNeeded()
                    try FileManager.writeLocalImage(image, at: url)
                } catch {
                    Log.debug("failed to write cached image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func resetImages(forID id: WorkoutID) {
        for scheme in ColorScheme.allCases {
            let url = URL.cachedMapImageURL(id: id, scheme: scheme)
            imageCache.removeObject(forKey: url.path as NSString)
            do {
                try FileManager.deleteLocalImage(at: url)
            } catch {
                Log.debug("failed to delete image \(url.path): \(error.localizedDescription)")
            }
        }
    }
    
}

// MARK:  Workout Metadata

extension WorkoutStorage {
    
    func isWorkoutFavorite(_ id: WorkoutID) -> Bool {
        queue.sync {
            if let viewModel = workouts[id] {
                return viewModel.isFavorite
            } else {
                return metaProvider.isFavorite(id)
            }
        }
    }
    
    func set(isFavorite: Bool, forID id: WorkoutID) {
        queue.async { [unowned self] in
            if let viewModel = workouts[id] {
                viewModel.isFavorite = isFavorite
                DispatchQueue.main.async {
                    postNotification(forViewModel: viewModel)
                }
            }
        }
    }
    
    func set(tags: [TagLabelViewModel], forID id: WorkoutID) {
        queue.async { [unowned self] in
            if let viewModel = workouts[id] {
                viewModel.tags = tags
                DispatchQueue.main.async {
                    postNotification(forViewModel: viewModel)
                }
            }
        }
    }
    
    func resetTags(forID id: WorkoutID) {
        queue.async { [unowned self] in
            let tags: [TagLabelViewModel] = workoutTagProvider.visibleTags(forWorkout: id).map { $0.viewModel() }
            if let viewModel = workouts[id] {
                viewModel.tags = tags
                DispatchQueue.main.async {
                    postNotification(forViewModel: viewModel)
                }
            }
        }
    }
    
}

// MARK: - Errors

extension WorkoutStorage {
    
    enum WorkoutError: Error {
        case notFound
    }

    static var viewModelUpdatedNotification = Notification.Name("arn_workout_store_view_model_updated")
    private static var shouldUpdateCoordinatesNotification = Notification.Name("arn_workout_store_should_update_coordinates")
    private static var shouldUpdateFavoriteNotification = Notification.Name("arn_workout_store_should_update_favorite")
    private static var shouldUpdateTagsNotification = Notification.Name("arn_workout_store_should_update_tags")
    private static var shouldResetAllNotification = Notification.Name("arn_workout_store_reset_all")
    
    static var viewModelKey = "workout_view_model"
    private static var workoutIDKey = "workout_id"
    private static var coordinatesKey = "coordinates"
    private static var favoriteKey = "favorite"
    private static var tagsKey = "tags"
    
    private func postNotification(forViewModel viewModel: WorkoutViewModel) {
        let userInfo = [Self.viewModelKey: viewModel]
        NotificationCenter.default.post(name: Self.viewModelUpdatedNotification, object: nil, userInfo: userInfo)
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateCoordinates),
            name: Self.shouldUpdateCoordinatesNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateFavorites),
            name: Self.shouldUpdateFavoriteNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTags),
            name: Self.shouldUpdateTagsNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetAllWorkouts),
            name: Self.shouldResetAllNotification,
            object: nil
        )
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: Self.shouldUpdateCoordinatesNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Self.shouldUpdateFavoriteNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Self.shouldUpdateTagsNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Self.shouldResetAllNotification, object: nil)
    }
    
    @objc
    private func updateCoordinates(_ notification: Notification) {
        guard let id = notification.userInfo?[Self.workoutIDKey] as? WorkoutID else { return }
        guard let coordinates = notification.userInfo?[Self.coordinatesKey] as? [CLLocationCoordinate2D] else { return }
        set(coordinates: coordinates, forID: id)
    }
    
    @objc
    private func updateFavorites(_ notification: Notification) {
        guard let id = notification.userInfo?[Self.workoutIDKey] as? WorkoutID else { return }
        guard let favorite = notification.userInfo?[Self.favoriteKey] as? Bool else { return }
        set(isFavorite: favorite, forID: id)
    }
    
    @objc
    private func updateTags(_ notification: Notification) {
        guard let id = notification.userInfo?[Self.workoutIDKey] as? WorkoutID else { return }
        resetTags(forID: id)
    }
    
    @objc
    private func resetAllWorkouts(_ notification: Notification) {
        resetAll()
    }
    
    // MARK: Notification Wrappers
    
    static func updateCoordinates(_ coordinates: [CLLocationCoordinate2D], forID id: WorkoutID) {
        let userInfo: [String: Any] = [workoutIDKey: id, coordinatesKey: coordinates]
        NotificationCenter.default.post(name: shouldUpdateCoordinatesNotification, object: nil, userInfo: userInfo)
    }
    
    static func updateFavorite(_ isFavorite: Bool, forID id: WorkoutID) {
        let userInfo: [String: Any] = [workoutIDKey: id, favoriteKey: isFavorite]
        NotificationCenter.default.post(name: shouldUpdateFavoriteNotification, object: nil, userInfo: userInfo)
    }
    
    static func resetTags(forID id: WorkoutID) {
        let userInfo: [String: Any] = [workoutIDKey: id]
        NotificationCenter.default.post(name: shouldUpdateTagsNotification, object: nil, userInfo: userInfo)
    }
    
    static func resetAll() {
        NotificationCenter.default.post(name: shouldResetAllNotification, object: nil, userInfo: nil)
    }
    
}
