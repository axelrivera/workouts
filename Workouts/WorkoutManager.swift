//
//  WorkoutManager.swift
//  Workouts
//
//  Created by Axel Rivera on 12/28/20.
//

import SwiftUI
import Combine
import CoreData

class WorkoutManager: ObservableObject {
    private(set) var context: NSManagedObjectContext
    private(set) var dataProvider: DataProvider
    private(set) var metaProvider: MetadataProvider
    
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
    @Published var processingRemoteDataValue: Double = 0
    @Published var totalProcessingWorkouts = 0
    private var totalPendingWorkouts = 0
        
    @Published var isOnboardingVisible = false
    @Published var isAuthorized = true
    @Published var recentWorkouts = [Workout]()
        
    init(context: NSManagedObjectContext) {
        self.context = context
        dataProvider = DataProvider(context: context)
        metaProvider = MetadataProvider(context: context)
        recentWorkouts = dataProvider.recentWorkouts()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - Methods
    
    func requestHealthaStatus() async {
        let shouldRequestStatus = await authProvider.shouldRequestStatus()
        if shouldRequestStatus {
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.isOnboardingVisible = true
            }
        } else {
            Log.debug("request status not required")
            refreshWorkouts(isAuthorized: isAuthorized)
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
    
    func fetchRecentWorkouts() {
        let workouts = dataProvider.recentWorkouts()
        
        DispatchQueue.main.async {
            withAnimation {
                self.recentWorkouts = workouts
            }
        }
    }
    
    var showImportProgress: Bool {
        isProcessingRemoteData && totalProcessingWorkouts > 5
    }
    
    var totalWorkouts: Int {
        dataProvider.totalWorkouts(sport: sport, interval: nil)
    }
    
}

// MARK: - Metadata

extension WorkoutManager {
    
    func toggleFavorite(_ identifier: UUID) {
        var isFavorite = WorkoutCache.shared.isFavorite(identifier: identifier)
        
        do {
            if isFavorite {
                try metaProvider.unfavoriteWorkout(for: identifier)
                isFavorite = false
            } else {
                try metaProvider.favoriteWorkout(for: identifier)
                isFavorite = true
            }
            
            WorkoutCache.shared.set(isFavorite: isFavorite, identifier: identifier)
        } catch {
            Log.debug("favorite toggle error for id - \(identifier): \(error.localizedDescription)")
        }
    }
    
}

// MARK: - Notifications and Observers

extension WorkoutManager {
    
    private func addObservers() {
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
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .willBeginProcessingRemoteData, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didInsertRemoteData, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didFinishProcessingRemoteData, object: nil)
    }
    
    @objc
    private func willProcessWorkouts(_ notification: Notification) {
        let processing = notification.userInfo?[Notification.totalRemoteWorkoutsKey] as? Int ?? 0
        
        DispatchQueue.main.async {
            withAnimation {
                self.totalProcessingWorkouts = processing
                self.totalPendingWorkouts = processing
                self.processingRemoteDataValue = 0.0
                self.isProcessingRemoteData = true
            }
        }
    }
    
    @objc
    private func didInsertWorkout(_ notification: Notification) {
        totalPendingWorkouts -= 1
        let current = totalProcessingWorkouts - totalPendingWorkouts
        let value = Double(current) / Double(totalProcessingWorkouts)
        
        DispatchQueue.main.async {
            self.processingRemoteDataValue = value
        }
    }
    
    @objc
    private func didProcessWorkouts(_ notification: Notification) {
        DispatchQueue.main.async {
            withAnimation {
                self.totalProcessingWorkouts = 0
                self.totalPendingWorkouts = 0
                self.processingRemoteDataValue = 0.0
                self.isProcessingRemoteData = false
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
