//
//  WorkoutManager.swift
//  Workouts
//
//  Created by Axel Rivera on 12/28/20.
//

import Foundation
import HealthKit
import Combine
import FitFileParser
import MapKit
import CoreData

class WorkoutManager: ObservableObject {
    let healthStore = HealthData.shared.healthStore
    
    enum State {
        case ok, empty, notAvailable, permissionDenied, none
    }
    
    var context: NSManagedObjectContext
        
    @Published var shouldRequestReadingAuthorization = false
    @Published var state = State.none
    @Published var isLoading = false
    
    @Published var isProcessingRemoteData = false
    @Published var processingRemoteDataValue: Double = 0
    private var totalPendingWorkouts = 0
    private var totalCurrentWorkouts = 0
    
    init(context: NSManagedObjectContext) {
        self.context = context
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    var isDisabled: Bool {
        state != .ok
    }
    
    var totalWorkouts: Int {
        let request = Workout.sortedFetchRequest
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
}

// MARK: - Authorization Methods

extension WorkoutManager {
    
    func fetchRequestStatusForReading(resetAnchor: Bool) {
        Log.debug("request status for reading - reset anchor: \(resetAnchor)")
        
        HealthData.shared.requestStatusForReading { (result) in
            switch result {
            case .success(let shouldRequest):
                Log.debug("should request permission: \(shouldRequest)")
                
                if shouldRequest {
                    self.postRefreshNotification(isAuthorized: false, resetAnchor: resetAnchor)
                    DispatchQueue.main.async {
                        self.shouldRequestReadingAuthorization = shouldRequest
                    }
                } else {
                    self.validateWorkoutStatusForReading(resetAnchor: resetAnchor)
                }
            case .failure(let error):
                Log.debug("read request failed: \(error)")
                if case HealthData.DataError.dataNotAvailable = error {
                    self.updateState(.notAvailable)
                }
            }
        }
    }
    
    private func validateWorkoutStatusForReading(resetAnchor: Bool) {
        Log.debug("validate workout status for reading - reset anchor: \(resetAnchor)")
        
        WorkoutDataStore.shared.fetchTotalWorkouts { [unowned self] (result) in
            do {
                let _ = try result.get()
                self.postRefreshNotification(isAuthorized: true, resetAnchor: resetAnchor)
                self.updateState(.ok)
            } catch {
                Log.debug("failed to validate workout status for reading: \(error.localizedDescription)")
                self.postRefreshNotification(isAuthorized: false)
                self.updateState(.empty)
            }
        }
    }
    
    func requestReadingAuthorization(completionHandler: @escaping (_ success: Bool) -> Void) {
        func success() {
            updateState(.ok)
            updateShouldRequestReadingAuthorization(false)
            postRefreshNotification(isAuthorized: true, resetAnchor: true)
            completionHandler(true)
        }

        func failed(error: Error) {
            Log.debug("request reading permissions failed: \(error)")

            postRefreshNotification(isAuthorized: false)

            if case HealthData.DataError.permissionDenied = error {
                updateState(.permissionDenied)
            } else {
                updateState(.notAvailable)
            }

            completionHandler(false)
        }

        HealthData.shared.requestReadingAuthorization(for: HealthData.readObjectTypes()) { result in
            switch result {
            case .success:
                success()
            case .failure(let error):
                failed(error: error)
            }
        }
    }
    
}

// MARK: - Notifications and Observers

extension WorkoutManager {
    
    func postRefreshNotification(isAuthorized: Bool? = nil, resetAnchor: Bool? = nil) {
        var userInfo = [String: Any]()
        
        if let isAuthorized = isAuthorized {
            userInfo[Notification.isAuthorizedToFetchRemoteDataKey] = isAuthorized
        }
        
        if let resetAnchor = resetAnchor {
            userInfo[Notification.resetAnchorKey] = resetAnchor
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .shouldFetchRemoteData, object: nil, userInfo: userInfo)
        }
    }
    
    func addObservers() {
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
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .willBeginProcessingRemoteData, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didInsertRemoteData, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didFinishProcessingRemoteData, object: nil)
    }
    
    @objc
    func willProcessWorkouts(_ notification: Notification) {
        let totalWorkouts = self.totalWorkouts
        isLoading = totalWorkouts == 0
        
        totalPendingWorkouts = notification.userInfo?[Notification.totalRemoteWorkoutsKey] as? Int ?? 0
        totalCurrentWorkouts = 0
                
        updateRemoteValues()
    }
    
    @objc
    func didInsertWorkout(_ notification: Notification) {
        totalCurrentWorkouts += 1
        updateRemoteValues()
    }
    
    @objc
    func didProcessWorkouts(_ notification: Notification) {
        isLoading = false
        totalPendingWorkouts = 0
        totalCurrentWorkouts = 0
        
        updateRemoteValues()
    }
    
}

// MARK: - User Interface

extension WorkoutManager {
    
    func updateShouldRequestReadingAuthorization(_ shouldRequestReadingAuthorization: Bool) {
        DispatchQueue.main.async {
            self.shouldRequestReadingAuthorization = shouldRequestReadingAuthorization
        }
    }
    
    func updateState(_ state: State) {
        DispatchQueue.main.async {
            self.state = state
        }
    }
    
    func updateRemoteValues() {
        guard self.totalPendingWorkouts > 0 else {
            self.isProcessingRemoteData = false
            self.processingRemoteDataValue = 0.0
            return
        }
        
        self.isProcessingRemoteData = true
        self.processingRemoteDataValue = Double(self.totalCurrentWorkouts) / Double(self.totalPendingWorkouts)
    }
    
}
