//
//  Synchronizer.swift
//  Workouts
//
//  Created by Axel Rivera on 7/3/22.
//

import Foundation
import CoreData
import HealthKit
import Combine

class Synchronizer {
    let CHUNK_SIZE: Int = 25
    let MAX_OPERATIONS: Int = 1
    
    let provider: WorkoutsProvider
    private var cancellable: Cancellable?
    
    init(provider: WorkoutsProvider) {
        self.provider = provider
        cancellable = NotificationCenter.default.publisher(for: .shouldFetchRemoteData).sink(receiveValue: fetchRemoteData)
    }
    
    deinit {
        cancellable = nil
    }
}

// MARK: Import Workouts

extension Synchronizer {
    
    func fetchRemoteData(_ notification: Notification) {
        let regenerate = notification.userInfo?[Notification.regenerateDataKey] as? Bool ?? false
        Task {
            do {
                try await provider.fetchWorkouts(regenerate: regenerate)
            } catch {
                Log.debug("failed to fetch workouts: \(error.localizedDescription)")
            }
        }
    }
    
}

// MARK: - Notifications

extension Notification.Name {
    
    static var shouldFetchRemoteData = Notification.Name("arn_should_fetch_remote_data")
    static var didFinishFetchingRemoteData = Notification.Name("arn_did_finish_fetching_remote_data")
    static var willBeginProcessingRemoteData = Notification.Name("arn_will_begin_processing_remote_data")
    static var didFinishProcessingRemoteData = Notification.Name("arn_did_finish_processing_remote_data")
}

extension Notification {
    
    static var isAuthorizedToFetchRemoteDataKey = "arn_is_authorized_to_fetch_remote_data"
    static var remoteWorkoutKey = "arn_remote_workout"
    static var resetAnchorKey = "arn_reset_anchor"
    static var regenerateDataKey = "arn_regenerate_data"
    static var workoutIdentifiersKey = "arn_workout_identifiers"
    
}
