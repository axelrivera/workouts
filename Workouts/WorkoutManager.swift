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

class WorkoutManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var workouts = [Workout]()
    @Published var summary = WorkoutSummary()
        
    func fetchWorkouts() {
        let sampleType = HKSampleType.workoutType()
        let predicate = HKQuery.predicateForWorkouts(with: .cycling)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                Log.debug("workout query failed: \(error.localizedDescription)")
                return
            }
            
            let workouts = samples as? [HKWorkout] ?? [HKWorkout]()
            self.updateUI(for: workouts)
        }
        
        HKHealthStore().execute(query)
    }
    
    func updateUI(for objects: [HKWorkout]) {
        var workouts = [Workout]()
        
        let totalWorkouts = objects.count
        var distance: Double = 0
        var energyBurned: Double = 0
        var elapsedTime: Double = 0
        
        objects.forEach { object in
            let workout = Workout(object: object)
            workouts.append(workout)
            
            distance += workout.distance
            energyBurned += workout.energyBurned
            elapsedTime += workout.elapsedTime
        }
        
        let summary = WorkoutSummary(
            total: totalWorkouts,
            distance: distance,
            energyBurned: energyBurned,
            elapsedTime: elapsedTime
        )
        
        DispatchQueue.main.async {
            self.workouts = workouts
            self.summary = summary
        }
    }

    func generateSampleData() {
        for _ in 0 ..< 10 {
            workouts.append(Workout.sample)
        }
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
