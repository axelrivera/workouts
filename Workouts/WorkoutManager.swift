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
    
    @Published var workouts = [Workout]()
    
    @Published var shouldRequestReadingAuthorization = false
    @Published var state = State.ok
    
    var workoutQuery: HKAnchoredObjectQuery?
    var lastWorkoutAnchor: HKQueryAnchor?
        
    func fetchRequestStatusForReading() {
        Log.debug("request status for reading")
        
        HealthData.requestStatusForReading { (result) in
            switch result {
            case .success(let shouldRequest):
                Log.debug("success")
                if !shouldRequest {
                    self.fetchWorkouts()
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
            fetchWorkouts()
            completionHandler(true)
        }
        
        func failed(error: Error) {
            Log.debug("request reading permissions failed: \(error)")
            
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
    
    func fetchWorkouts() {
        Log.debug("fetching workouts")
        
        if let _ = workoutQuery {
            Log.debug("ignore fetching workouts")
            validateWorkoutStatusForReading()
            return
        }
                        
        let query = HKAnchoredObjectQuery(
            type: .workoutType(),
            predicate: WorkoutDataStore.defaultActivitiesPredicate(),
            anchor: lastWorkoutAnchor,
            limit: HKObjectQueryNoLimit) { (query, samples, deleted, anchor, error) in
            self.lastWorkoutAnchor = anchor
            self.updateWorkouts(samples: samples, deleted: deleted)
        }
        
        query.updateHandler = { (query, samples, deleted, anchor, error) in
            self.lastWorkoutAnchor = anchor
            self.updateWorkouts(samples: samples, deleted: deleted)
        }
        
        workoutQuery = query
        healthStore.execute(query)
    }
    
    func updateWorkouts(samples: [HKSample]?, deleted: [HKDeletedObject]?) {
        let deletedObjects = deleted ?? [HKDeletedObject]()
        for object in deletedObjects {
            if let index = self.workouts.firstIndex(where: { $0.id == object.uuid }) {
                DispatchQueue.main.async {
                    self.workouts.remove(at: index)
                    self.state = self.workouts.isEmpty ? .empty : .ok
                    self.postRefreshNotification()
                }
            }
        }
        
        if let samples = samples as? [HKWorkout] {
            let newWorkouts = samples.map { Workout(object: $0) }
            DispatchQueue.main.async {
                self.workouts.append(contentsOf: newWorkouts)
                self.workouts.sort(by: { $0.startDate.compare($1.startDate) == .orderedDescending })
                self.state = self.workouts.isEmpty ? .empty : .ok
                self.postRefreshNotification()
            }
        }
    }
    
    func postRefreshNotification() {
        NotificationCenter.default.post(name: .didRefreshWorkouts, object: nil)
    }
}

// MARK: User Interface

extension WorkoutManager {
    
    func updateShouldRequestReadingAuthorization(_ shouldRequestReadingAuthorization: Bool) {
        DispatchQueue.main.async {
            self.shouldRequestReadingAuthorization = shouldRequestReadingAuthorization
        }
    }
    
    func validateState() {
        updateState(workouts.isEmpty ? .empty : .ok)
    }
    
    func updateState(_ state: State) {
        DispatchQueue.main.async {
            self.state = state
        }
    }
    
    func availableWorkouts() -> [HKWorkoutActivityType] {
        [.cycling]
    }
    
}

// MARK: Sample Data

extension WorkoutManager {
    
    static func sampleWorkouts() -> [Workout] {
        (0 ..< 10).map({ _ -> Workout in Workout.sample })
    }
    
}
