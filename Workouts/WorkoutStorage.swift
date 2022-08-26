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
    private let queue = DispatchQueue(label: "WorkoutStorage.queue")
    
    private var context: NSManagedObjectContext
    private var metaProvider: MetadataProvider
    private var workoutTagProvider: WorkoutTagProvider
    
    init(context: NSManagedObjectContext) {
        self.context = context
        metaProvider = MetadataProvider(context: context)
        workoutTagProvider = WorkoutTagProvider(context: context)
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
}

extension WorkoutStorage {
    
    func isWorkoutCached(_ workoutID: WorkoutID) -> Bool {
        queue.sync {
            if let _ = workouts[workoutID] {
                return true
            } else {
                return false
            }
        }
    }
    
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
    
    func refreshMetadata(forWorkout workout: Workout) {
        queue.sync { [unowned self] in
            let id = workout.workoutIdentifier
            let viewModel = workouts[id] ?? WorkoutViewModel(workout: workout)
            viewModel.isFavorite = metaProvider.isFavorite(id)
            viewModel.tags = workoutTagProvider.visibleTags(forWorkout: id).map({ $0.viewModel() })
            
            workouts[workout.workoutIdentifier] = viewModel
            
            DispatchQueue.main.async {
                self.postNotification(forViewModel: viewModel)
            }
        }
    }
    
    func refreshAllWorkouts() {
        queue.sync { [unowned self] in
            for (id, viewModel) in workouts {
                viewModel.isFavorite = metaProvider.isFavorite(id)
                viewModel.tags = workoutTagProvider.visibleTags(forWorkout: id).map({ $0.viewModel() })
                
                DispatchQueue.main.async {
                    self.postNotification(forViewModel: viewModel)
                }
            }
        }
    }
    
    func resetAll() {
        queue.async { [unowned self] in
            Log.debug("resetting workout cache")
            workouts = [WorkoutID: WorkoutViewModel]()
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
                    self.postNotification(forViewModel: viewModel)
                }
            }
        }
    }
    
    func set(tags: [TagLabelViewModel], forID id: WorkoutID) {
        queue.async { [unowned self] in
            if let viewModel = workouts[id] {
                viewModel.tags = tags
                DispatchQueue.main.async {
                    self.postNotification(forViewModel: viewModel)
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
                    self.postNotification(forViewModel: viewModel)
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

    private static var shouldReloadWorkoutsNotification = Notification.Name("arn_workout_store_should_reload_workouts")
    private static var shouldUpdateFavoriteNotification = Notification.Name("arn_workout_store_should_update_favorite")
    private static var shouldUpdateTagsNotification = Notification.Name("arn_workout_store_should_update_tags")
    private static var shouldResetAllNotification = Notification.Name("arn_workout_store_reset_all")
    
    static var viewModelKey = "workout_view_model"
    private static var workoutIDKey = "workout_id"
    private static var workoutIDSKey = "workout_ids"
    private static var favoriteKey = "favorite"
    private static var tagsKey = "tags"
    
    private func postNotification(forViewModel viewModel: WorkoutViewModel) {
        let userInfo = [Self.viewModelKey: viewModel]
        NotificationCenter.default.post(name: Self.viewModelUpdatedNotification, object: nil, userInfo: userInfo)
    }
    
    private func addObservers() {
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
            selector: #selector(reloadWorkouts),
            name: Self.shouldReloadWorkoutsNotification,
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
        NotificationCenter.default.removeObserver(self, name: Self.shouldUpdateFavoriteNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Self.shouldUpdateTagsNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Self.shouldReloadWorkoutsNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Self.shouldResetAllNotification, object: nil)
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
    private func reloadWorkouts(_ notification: Notification) {
        Log.debug("got update workout notification")
        
        guard let ids = notification.userInfo?[Self.workoutIDSKey] as? [WorkoutID] else { return }
        
        for id in ids {
            guard isWorkoutCached(id), let workout = Workout.find(using: id, in: context) else {
                continue
            }
            refreshMetadata(forWorkout: workout)
        }
    }
    
    @objc
    private func resetAllWorkouts(_ notification: Notification) {
        resetAll()
    }
    
    // MARK: Notification Wrappers
    
    static func updateFavorite(_ isFavorite: Bool, forID id: WorkoutID) {
        let userInfo: [String: Any] = [workoutIDKey: id, favoriteKey: isFavorite]
        NotificationCenter.default.post(name: shouldUpdateFavoriteNotification, object: nil, userInfo: userInfo)
    }
    
    static func resetTags(forID id: WorkoutID) {
        let userInfo: [String: Any] = [workoutIDKey: id]
        NotificationCenter.default.post(name: shouldUpdateTagsNotification, object: nil, userInfo: userInfo)
    }
    
    static func reloadWorkouts(for ids: [WorkoutID]) {
        Log.debug("trying to update workouts")
        let userInfo: [String: Any] = [workoutIDSKey: ids]
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: shouldReloadWorkoutsNotification, object: nil, userInfo: userInfo)
        }
    }
    
    static func resetAll() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: shouldResetAllNotification, object: nil, userInfo: nil)
        }
    }
    
}
