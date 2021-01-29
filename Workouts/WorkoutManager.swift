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
    
    @Published var workouts = [Workout]()
    
    var workoutQuery: HKAnchoredObjectQuery?
    var lastWorkoutAnchor: HKQueryAnchor?
    
    init() {
        fetchWorkouts()
    }
    
    func fetchWorkouts() {
        // TODO: Add Permission Validation Here
        
        if let query = workoutQuery {
            healthStore.stop(query)
            lastWorkoutAnchor = nil
            
            DispatchQueue.main.async {
                self.workouts = [Workout]()
            }
        }
        
        let query = HKAnchoredObjectQuery(
            type: .workoutType(),
            predicate: nil,
            anchor: lastWorkoutAnchor,
            limit: HKObjectQueryNoLimit) { (query, samples, deleted, anchor, error) in
            guard let samples = samples as? [HKWorkout], let deleted = deleted else { return }
            
            self.lastWorkoutAnchor = anchor
            
            let workouts = samples.map { Workout(object: $0) }
            DispatchQueue.main.async {
                self.workouts.append(contentsOf: workouts)
                
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
    
    func importWorkous(at urls: [URL]) {
        urls.forEach { importWorkout(at: $0) }
    }
    
    func importWorkout(at url: URL) {
        guard let fit = FitFile(file: url) else {
            Log.debug("unable to read fit file: \(url)")
            return
        }
        
        guard let workoutImport = WorkoutImport(fit: fit) else {
            Log.debug("unable to import fit file")
            return
        }
        
        Log.debug("importing workout")
        
        WorkoutDataStore.saveWorkoutImport(workoutImport) { result in
            switch result {
            case .success:
                Log.debug("import succeeded")
            case .failure(let error):
                Log.debug("import failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: User Interface

extension WorkoutManager {
    
    func availableWorkouts() -> [HKWorkoutActivityType] {
        [.cycling]
    }
    
}
