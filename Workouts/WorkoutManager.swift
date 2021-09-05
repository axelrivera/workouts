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
    
    private let authProvider = HealthAuthProvider.shared
    private let healthProvider = HealthProvider.shared
    
    @Published var sport: Sport?
    @Published var isWorkoutsVisible = false
    @Published var selectedWorkout: UUID?
    
    @Published var isProcessingRemoteData = false
    @Published var processingRemoteDataValue: Double = 0
    private var totalPendingWorkouts = 0
    private var totalCurrentWorkouts = 0
        
    @Published var isOnboardingVisible = false
    @Published var isAuthorized = true
    @Published var recentWorkouts = [Workout]()
    
    init(context: NSManagedObjectContext) {
        self.context = context
        dataProvider = DataProvider(context: context)
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
            refreshWorkouts(isAuthorized: isAuthorized, resetAnchor: false)
        }
    }
    
    func requestHealthAuthorization() async {
        guard healthProvider.isAvailable else { return }
        
        do {
            Log.debug("getting authorization")
            try await healthProvider.healthStore.requestAuthorization(toShare: HealthAuthProvider.writeSampleTypes(), read: HealthAuthProvider.readObjectTypes())

            let isAuthorized = true
            refreshWorkouts(isAuthorized: isAuthorized, resetAnchor: false)

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
    
    func refreshWorkouts(isAuthorized: Bool, resetAnchor: Bool) {
        let userInfo: [String: Any] = [
            Notification.isAuthorizedToFetchRemoteDataKey: isAuthorized,
            Notification.resetAnchorKey: resetAnchor
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
        totalPendingWorkouts = notification.userInfo?[Notification.totalRemoteWorkoutsKey] as? Int ?? 0
        totalCurrentWorkouts = 0
        updateRemoteValues()
    }
    
    @objc
    private func didInsertWorkout(_ notification: Notification) {
        totalCurrentWorkouts += 1
        updateRemoteValues()
    }
    
    @objc
    private func didProcessWorkouts(_ notification: Notification) {
        totalPendingWorkouts = 0
        totalCurrentWorkouts = 0
        updateRemoteValues()
    }
    
}

// MARK: - User Interface

extension WorkoutManager {
    
    private func updateRemoteValues() {
        DispatchQueue.main.async {
            if self.totalPendingWorkouts > 0 {
                self.isProcessingRemoteData = true
                self.processingRemoteDataValue = Double(self.totalCurrentWorkouts) / Double(self.totalPendingWorkouts)
            } else {
                self.isProcessingRemoteData = false
                self.processingRemoteDataValue = 0.0
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
