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

class WorkoutManager: ObservableObject {
    let healthStore = HealthData.healthStore
    
    enum State {
        case ok, empty, notAvailable, permissionDenied
    }
        
    @Published var shouldRequestReadingAuthorization = false
    @Published var state = State.ok
            
    func fetchRequestStatusForReading() {
        Log.debug("request status for reading")
        
        HealthData.requestStatusForReading { (result) in
            switch result {
            case .success(let shouldRequest):
                Log.debug("success")
                if !shouldRequest {
                    self.postRefreshNotification(isAuthorized: true)
                } else {
                    self.postRefreshNotification(isAuthorized: false)
                }
                
                DispatchQueue.main.async {
                    self.shouldRequestReadingAuthorization = shouldRequest
                }
            case .failure(let error):
                Log.debug("read request failed: \(error)")
                if case HealthData.DataError.dataNotAvailable = error {
                    self.updateState(.notAvailable)
                }
            }
        }
    }
    
    func validateWorkoutStatusForReading() {
        WorkoutDataStore.fetchTotalWorkouts { (result) in
            do {
                let total = try result.get()
                Log.debug("total workouts: \(total)")
                self.updateState(total > 0 ? .ok : .empty)
            } catch {
                Log.debug("failed to get total workouts: \(error.localizedDescription)")
            }
        }
    }
    
    func requestReadingAuthorization(completionHandler: @escaping (_ success: Bool) -> Void) {
        func success() {
            updateState(.ok)
            updateShouldRequestReadingAuthorization(false)
            postRefreshNotification(isAuthorized: true)
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
        
        HealthData.requestReadingAuthorization(for: HealthData.readObjectTypes()) { result in
            switch result {
            case .success:
                Log.debug("fetch data succeeded")
                success()
            case .failure(let error):
                failed(error: error)
            }
        }
    }
    
    func postRefreshNotification(isAuthorized: Bool? = nil) {
        var userInfo: [String: Any]?
        
        if let isAuthorized = isAuthorized {
            userInfo = [Notification.isAuthorizedToFetchRemoteDataKey: isAuthorized]
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .shouldFetchRemoteData, object: nil, userInfo: userInfo)
        }
        
    }
}

// MARK: User Interface

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
    
}
