//
//  WorkoutManager.swift
//  Workouts
//
//  Created by Axel Rivera on 12/28/20.
//

import SwiftUI
import Combine
import CoreData
import CoreLocation

class WorkoutManager: ObservableObject {
    let LOADING_WAIT_IN_SECONDS = 2.0
    
    private(set) var context: NSManagedObjectContext
    private(set) var dataProvider: DataProvider
    private(set) var metaProvider: MetadataProvider
    private(set) var storage: WorkoutStorage
    
    private let authProvider = HealthAuthProvider.shared
    private let healthProvider = HealthProvider.shared
        
    @Published var sport: Sport?

    @Published var showDateFilter = false
    @Published var filterByfavorites = false
    @Published var filterBySports = Set<Sport>()
    @Published var filterByStartDate = Date()
    @Published var filterByEndDate = Date()
    @Published var filterByMinDistance: Double = 0
    @Published var filterByMaxDistance: Double = 0
    
    var processingRemoteDataTimestamp: Date?
    @Published var isProcessingRemoteData = false
    @Published var showProcessingRemoteDataLoading = false
    
    var updatingRemoteLocationDataTimestamp: Date?
    @Published var isUpdatingRemoteLocationData = false
    @Published var showUpdatingRemoteLocationDataLoading = false
    
    @Published var isOnboardingVisible = false
    @Published var isAuthorized = true

    @Published var showNoWorkoutsOverlay = false
    
    var isProcessing: Bool {
        isProcessingRemoteData || isUpdatingRemoteLocationData
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
        dataProvider = DataProvider(context: context)
        metaProvider = MetadataProvider(context: context)
        storage = WorkoutStorage(context: context)
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - Methods
    
    func requestHealthStatus() async {
        let shouldRequestStatus = await authProvider.shouldRequestStatus()
        if shouldRequestStatus {
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.isOnboardingVisible = true
            }
        } else {
            Log.debug("request status not required")
            refreshWorkouts(isAuthorized: isAuthorized)
            validateHealthPermissions()
        }
    }
    
    func requestHealthAuthorization() async {
        guard healthProvider.isAvailable else { return }
        
        do {
            Log.debug("getting authorization")
            try await healthProvider.healthStore.requestAuthorization(toShare: HealthAuthProvider.writeSampleTypes(), read: HealthAuthProvider.readObjectTypes())

            let isAuthorized = true
            refreshWorkouts(isAuthorized: isAuthorized)

            DispatchQueue.main.async {
                self.isOnboardingVisible = !isAuthorized
                self.isAuthorized = isAuthorized

            }
        } catch {
            Log.debug("unable to fetch health authorization: \(error.localizedDescription)")
            // TODO: Show alert here
            DispatchQueue.main.async {
                self.isAuthorized = false
            }
        }
    }
    
    func refreshWorkouts(isAuthorized: Bool) {
        let userInfo: [String: Any] = [
            Notification.isAuthorizedToFetchRemoteDataKey: isAuthorized,
        ]
        
        NotificationCenter.default.post(name: .shouldFetchRemoteData, object: nil, userInfo: userInfo)
    }
    
    var totalWorkouts: Int {
        dataProvider.totalWorkouts(sport: sport, interval: nil)
    }
    
    func validateHealthPermissions() {
        Task(priority: .userInitiated) {
            do {
                let total = try await healthProvider.totalWorkouts()
                DispatchQueue.main.async {
                    self.showNoWorkoutsOverlay = total == 0
                }
            } catch {
                DispatchQueue.main.async {
                    self.showNoWorkoutsOverlay = true
                }
            }
        }
    }
    
}

// MARK: - Metadata

extension WorkoutManager {
    
    func toggleFavorite(_ identifier: UUID) {
        var isFavorite = storage.isWorkoutFavorite(identifier)

        do {
            if isFavorite {
                try metaProvider.unfavoriteWorkout(for: identifier)
                isFavorite = false
            } else {
                try metaProvider.favoriteWorkout(for: identifier)
                isFavorite = true
            }

            storage.set(isFavorite: isFavorite, forID: identifier)
        } catch {
            Log.debug("favorite toggle error for id - \(identifier): \(error.localizedDescription)")
        }
    }
    
}

// MARK: - Notifications and Observers

extension WorkoutManager {
    
    private func addObservers() {
        // Inserting Workouts
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willProcessWorkouts),
            name: .willBeginProcessingRemoteData,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didInsertWorkout),
            name: .didInsertRemoteData,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didProcessWorkouts),
            name: .didFinishProcessingRemoteData,
            object: nil
        )
        
        // Updating Location Data
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willStartUpdatingLocation),
            name: .willBeginProcessingRemoteLocationData,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didUpdateLocation),
            name: .didUpdateRemoteLocationData,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didFinishUpdatingLocation),
            name: .didFinishProcessingRemoteLocationData,
            object: nil
        )
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .willBeginProcessingRemoteData, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didInsertRemoteData, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didFinishProcessingRemoteData, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: .willBeginProcessingRemoteLocationData, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didUpdateRemoteLocationData, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didFinishProcessingRemoteLocationData, object: nil)
    }
    
    // MARK: - Inserting Workouts
    
    @objc
    private func willProcessWorkouts(_ notification: Notification) {
        processingRemoteDataTimestamp = Date()
        
        DispatchQueue.main.async {
            withAnimation {
                self.isProcessingRemoteData = true
            }
        }
    }
    
    @objc
    private func didInsertWorkout(_ notification: Notification) {
        let now = Date()
        let date = processingRemoteDataTimestamp ?? now
        let waitTime = now.timeIntervalSince(date)
        
        if waitTime > LOADING_WAIT_IN_SECONDS && !showProcessingRemoteDataLoading {
            DispatchQueue.main.async {
                withAnimation {
                    self.showProcessingRemoteDataLoading = true
                }
            }
        }
    }
    
    @objc
    private func didProcessWorkouts(_ notification: Notification) {
        processingRemoteDataTimestamp = nil
        
        DispatchQueue.main.async {
            withAnimation {
                self.isProcessingRemoteData = false
                self.showProcessingRemoteDataLoading = false
            }
        }
    }
    
    // MARK: - Updating Location Data
    
    @objc
    func willStartUpdatingLocation(_ notification: Notification) {
        updatingRemoteLocationDataTimestamp = Date()
        
        DispatchQueue.main.async {
            withAnimation {
                self.isUpdatingRemoteLocationData = true
            }
        }
    }
    
    @objc
    func didUpdateLocation(_ notification: Notification) {
        let now = Date()
        let date = updatingRemoteLocationDataTimestamp ?? now
        let waitTime = now.timeIntervalSince(date)
        
        if waitTime > LOADING_WAIT_IN_SECONDS && !showUpdatingRemoteLocationDataLoading {
            DispatchQueue.main.async {
                withAnimation {
                    self.showUpdatingRemoteLocationDataLoading = true
                }
            }
        }
        
        let remoteIdentifier = notification.userInfo?[Notification.remoteWorkoutKey] as? UUID
        let coordinates = notification.userInfo?[Notification.coordinatesKey] as? [CLLocationCoordinate2D]

        if let remoteIdentifier = remoteIdentifier, let coordinates = coordinates {
            self.storage.set(coordinates: coordinates, forID: remoteIdentifier)
        }
    }
    
    @objc
    func didFinishUpdatingLocation(_ notification: Notification) {
        updatingRemoteLocationDataTimestamp = nil
        
        DispatchQueue.main.async {
            withAnimation {
                self.isUpdatingRemoteLocationData = false
                self.showUpdatingRemoteLocationDataLoading = false
            }
        }
    }
    
}

// MARK: - Previews

class WorkoutManagerPreview: WorkoutManager {
    
    static func manager(context: NSManagedObjectContext) -> WorkoutManager {
        WorkoutManager(context: context) as WorkoutManager
    }
    
}
