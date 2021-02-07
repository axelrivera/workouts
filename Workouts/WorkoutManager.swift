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
    let healthStore = HKHealthStore()
    
    enum State {
        case ok, empty, notAvailable
    }
    
    @Published var workouts = [Workout]()
    
    @Published var shouldRequestReadingAuthorization = false
    @Published var state = State.ok
    
    var workoutQuery: HKAnchoredObjectQuery?
    var lastWorkoutAnchor: HKQueryAnchor?
    
    func fetchRequestStatusForReading() {
        HealthData.requestStatusForReading { (result) in
            switch result {
            case .success(let shouldRequest):
                if !shouldRequest {
                    self.fetchWorkouts()
                }
                
                DispatchQueue.main.async {
                    self.shouldRequestReadingAuthorization = shouldRequest
                }
            case .failure(let error):
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
        HealthData.requestReadingAuthorization { result in
            switch result {
            case .success:
                Log.debug("fetch data succeeded")
                self.shouldRequestReadingAuthorization = false
                self.updateState(.ok)
                self.fetchWorkouts()
                completionHandler(true)
            case .failure(let error):
                Log.debug("fetch data failed: \(error.localizedDescription)")
                if case HealthData.DataError.dataNotAvailable = error {
                    self.updateState(.notAvailable)
                }
                completionHandler(false)
            }
        }
    }
    
    func fetchWorkouts() {
        if let _ = workoutQuery {
            Log.debug("ignore fetching workouts")
            validateWorkoutStatusForReading()
            return
        }
        
        Log.debug("fetch workouts")
        
        let query = HKAnchoredObjectQuery(
            type: .workoutType(),
            predicate: nil,
            anchor: lastWorkoutAnchor,
            limit: HKObjectQueryNoLimit) { (query, samples, deleted, anchor, error) in
            Log.debug("got results")
            
            if let error = error {
                Log.debug("fetch workouts failed: \(error.localizedDescription)")
            }
            
            guard let samples = samples as? [HKWorkout], let deleted = deleted else { return }
            
            self.lastWorkoutAnchor = anchor
            
            let workouts = samples.map { Workout(object: $0) }
            DispatchQueue.main.async {
                self.workouts.append(contentsOf: workouts)
                self.state = workouts.isEmpty ? .empty : .ok
                
                for object in deleted {
                    if let index = self.workouts.firstIndex(where: { $0.id == object.uuid }) {
                        self.workouts.remove(at: index)
                    }
                }
            }
        }
        
        query.updateHandler = { (query, samples, deleted, anchor, error) in
            guard let samples = samples as? [HKWorkout], let deleted = deleted else { return }
            
            self.lastWorkoutAnchor = anchor
            
            let workouts = samples.map { Workout(object: $0) }
            DispatchQueue.main.async {
                self.workouts.insert(contentsOf: workouts, at: 0)
                
                for object in deleted {
                    if let index = self.workouts.firstIndex(where: { $0.id == object.uuid }) {
                        self.workouts.remove(at: index)
                    }
                }
            }
        }
        
        workoutQuery = query
        healthStore.execute(query)
    }
}

// MARK: User Interface

extension WorkoutManager {
    
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
