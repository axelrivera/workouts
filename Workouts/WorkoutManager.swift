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
    let LOADING_WAIT_IN_SECONDS: Double = 5.0
    
    private(set) var context: NSManagedObjectContext
    private(set) var dataProvider: DataProvider
    private(set) var metaProvider: MetadataProvider
    private(set) var tagProvider: TagProvider
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
    
    @Published var isProcessingRemoteData = false
    @Published var showProcessingRemoteDataLoading = false
        
    @Published var isOnboardingVisible = false
    @Published var isAuthorized = true

    @Published var showNoWorkoutsAlert = false
    
    private var startProcessingDate: Date?
    private var timer: Timer?
    
    init(context: NSManagedObjectContext) {
        self.context = context
        dataProvider = DataProvider(context: context)
        metaProvider = MetadataProvider(context: context)
        tagProvider = TagProvider(context: context)
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
                    self.showNoWorkoutsAlert = total == 0
                }
            } catch {
                DispatchQueue.main.async {
                    self.showNoWorkoutsAlert = true
                }
            }
        }
    }
    
}

// MARK: - Metadata

extension WorkoutManager {
    
    func viewModel(for workout: Workout) -> WorkoutViewModel {
        storage.viewModel(forWorkout: workout)
    }
    
    func toggleFavorite(_ identifier: UUID) {
        var isFavorite = storage.isWorkoutFavorite(identifier)

        do {
            if isFavorite {
                try metaProvider.unfavoriteWorkout(for: identifier)
                isFavorite = false
                AnalyticsManager.shared.capture(.unfavorited)
            } else {
                try metaProvider.favoriteWorkout(for: identifier)
                isFavorite = true
                AnalyticsManager.shared.capture(.favorited)
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
            selector: #selector(didFinishFetchingWorkouts),
            name: .didFinishFetchingRemoteData,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willProcessWorkouts),
            name: .willBeginProcessingRemoteData,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didProcessWorkouts),
            name: .didFinishProcessingRemoteData,
            object: nil
        )
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .didFinishFetchingRemoteData, object: nil)
        NotificationCenter.default.removeObserver(self, name: .willBeginProcessingRemoteData, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didFinishProcessingRemoteData, object: nil)
    }
    
    // MARK: - Inserting Workouts
    
    @objc
    private func didFinishFetchingWorkouts(_ notification: Notification) {
        Log.debug("WORKOUTS: did finish inserting workouts")
        if showNoWorkoutsAlert {
            DispatchQueue.main.async {
                self.showNoWorkoutsAlert = false
            }
        }
    }
    
    @objc
    private func willProcessWorkouts(_ notification: Notification) {
        Log.debug("WORKOUTS: will process workout data")
        
        startProcessingDate = Date()
        
        DispatchQueue.main.async {
            self.isProcessingRemoteData = true
        }
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: LOADING_WAIT_IN_SECONDS, repeats: false) { _ in
                DispatchQueue.main.async {
                    if self.isProcessingRemoteData {
                        withAnimation {
                            self.showProcessingRemoteDataLoading = true
                        }
                    }
                }
            }
        }
    }
    
    @objc
    private func didProcessWorkouts(_ notification: Notification) {
        var totalMinutes: Double = 0
        
        if let start = startProcessingDate {
            totalMinutes = Date().timeIntervalSince(start) / 60.0
        }
        
        Log.debug("WORKOUTS: did finish processing workout data (\(totalMinutes) minutes)")
        
        startProcessingDate = nil
        timer = nil
        validateHealthPermissions()
        
        DispatchQueue.main.async {
            withAnimation {
                self.isProcessingRemoteData = false
                self.showProcessingRemoteDataLoading = false
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
