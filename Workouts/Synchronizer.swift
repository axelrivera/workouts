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

actor SynchronizerValues {
    var isAuthorized = false
    var regenerate = false
    
    func setIsAuthorized(_ isAuthorized: Bool) {
        self.isAuthorized = isAuthorized
    }
    
    func setRegenerate(_ regenerate: Bool) {
        self.regenerate = regenerate
    }
}

class Synchronizer {
    private let provider: WorkoutsProvider
    private var values = SynchronizerValues()
    
    private var fetchCancellable: Cancellable?
    private var zonesCancellable: Cancellable?
    private var imageCancellable: Cancellable?
    
    init(provider: WorkoutsProvider) {
        self.provider = provider
        fetchCancellable = NotificationCenter.default.publisher(for: .shouldFetchRemoteData).sink(receiveValue: fetchRemoteData)
        zonesCancellable = NotificationCenter.default.publisher(for: .shouldResetHeartRateZones).sink(receiveValue: resetHeartRateZones)
        imageCancellable = NotificationCenter.default.publisher(for: .shouldRegenerateMapImages).sink(receiveValue: resetImages)
    }
    
    deinit {
        fetchCancellable = nil
        zonesCancellable = nil
    }
}

// MARK: Import Workouts

extension Synchronizer {
    
    func fetchRemoteData(_ notification: Notification) {
        let isAuthorized = notification.userInfo?[Notification.isAuthorizedToFetchRemoteDataKey] as? Bool
        let regenerate = notification.userInfo?[Notification.regenerateDataKey] as? Bool
        
        Task {
            do {
                if let isAuthorized = isAuthorized {
                    await values.setIsAuthorized(isAuthorized)
                }
                
                if let regenerate = regenerate {
                    await values.setRegenerate(regenerate)
                }
                
                guard await values.isAuthorized else {
                    throw WorkoutError("not authorized")
                }
                
                try await provider.fetchWorkouts(regenerate: await values.regenerate)
                await values.setRegenerate(false)
            } catch {
                Log.debug("failed to fetch workouts: \(error.localizedDescription)")
            }
        }
    }
    
    func resetHeartRateZones(_ notification: Notification) {
        Task {
            do {
                try await provider.resetHeartRateZones()
            } catch {
                Log.debug("failed to reset heart rate zones: \(error.localizedDescription)")
            }
        }
    }
    
    func resetImages(_ notification: Notification) {
        Task {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .willBeginRegeneratingMapImages, object: nil)
            }
            
            do {
                FileManager.deleteImageCacheDirectory()
                try FileManager.createImagesCacheDirectoryIfNeeded()
                try await provider.resetImageData()
            } catch {
                Log.debug("failed to reset images: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didFinishRegeneratingMapImages, object: nil)
            }
        }
    }
    
}

extension Synchronizer {
    
    static func fetchRemoteData(isAuthorized: Bool? = nil, regenerate: Bool? = nil) {
        let userInfo: [String: Any] = [
            Notification.isAuthorizedToFetchRemoteDataKey: isAuthorized,
            Notification.regenerateDataKey: regenerate
        ].compactMapValues { $0 }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .shouldFetchRemoteData, object: nil, userInfo: userInfo)
        }
    }
    
    static func resetHeartRateZones() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .shouldResetHeartRateZones, object: nil)
        }
    }
    
    static func resetImages() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .shouldRegenerateMapImages, object: nil)
        }
    }
    
}

// MARK: - Notifications

extension Notification.Name {
    
    fileprivate static var shouldFetchRemoteData = Notification.Name("arn_should_fetch_remote_data")
    fileprivate static var shouldResetHeartRateZones = Notification.Name("arn_should_reset_heart_rate_zones")
    fileprivate static var shouldRegenerateMapImages = Notification.Name("arn_should_regenerate_map_images")
    
    // App Observers
    static var didFinishFetchingRemoteData = Notification.Name("arn_did_finish_fetching_remote_data")
    static var willBeginProcessingRemoteData = Notification.Name("arn_will_begin_processing_remote_data")
    static var didFinishProcessingRemoteData = Notification.Name("arn_did_finish_processing_remote_data")
    
    static var willBeginRegeneratingMapImages = Notification.Name("arn_will_begin_regenerating_map_images")
    static var didFinishRegeneratingMapImages = Notification.Name("arn_did_finish_regnerating_map_images")
}

extension Notification {
    
    static var isAuthorizedToFetchRemoteDataKey = "arn_is_authorized_to_fetch_remote_data"
    static var remoteWorkoutKey = "arn_remote_workout"
    static var resetAnchorKey = "arn_reset_anchor"
    static var regenerateDataKey = "arn_regenerate_data"
    static var workoutIdentifiersKey = "arn_workout_identifiers"
    
}
