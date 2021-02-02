//
//  ImportManager.swift
//  Workouts
//
//  Created by Axel Rivera on 1/31/21.
//

import Foundation
import FitFileParser
import HealthKit

class ImportManager: ObservableObject {
    @Published var workouts = [WorkoutImport]()
    @Published var isProcessingImports = false
    
    private var urls = [URL]()
    
    private lazy var importQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}

// MARK: - Selection Logic

extension ImportManager {
    func deleteWorkout(at offsets: IndexSet) {
        DispatchQueue.main.async {
            self.workouts.remove(atOffsets: offsets)
        }
    }
    
    var canImport: Bool {
        !newWorkouts.isEmpty
    }
    
    var newWorkouts: [WorkoutImport] {
        workoutsForStatus(.new)
    }
    
    var failedWorkouts: [WorkoutImport] {
        workoutsForStatus(.failed)
    }
    
    var processedWorkouts: [WorkoutImport] {
        workoutsForStatus(.processed)
    }
    
    private func workoutsForStatus(_ status: WorkoutImport.Status) -> [WorkoutImport] {
        workouts.filter({ $0.status == status })
    }
    
}

// MARK: - Process Imports

extension ImportManager {
    
    func cancelPendingImports() {
        importQueue.cancelAllOperations()
    }
    
    func reset() {
        urls = [URL]()
        workouts = [WorkoutImport]()
    }
    
    func processDocuments(at urls: [URL]) {
        reset()
        
        var workouts = [WorkoutImport]()
        self.urls = urls
        for url in urls {
            guard let fit = FitFile(file: url) else { continue }
            guard let workout = WorkoutImport(fit: fit) else { continue }
            
            workouts.append(workout)
        }
        
        DispatchQueue.main.async {
            self.workouts = workouts.sorted(by: { (lhs, rhs) -> Bool in
                guard let leftDate = lhs.startDate, let rightDate = rhs.startDate else { return false }
                return leftDate > rightDate
            })
        }
    }
    
    func importWorkouts(completionHandler: @escaping () -> Void) {
        isProcessingImports = true
        
        let newWorkouts = self.newWorkouts
        for workout in newWorkouts {
            let operation = ImportOperation(workout: workout)
            operation.completionBlock = {
                DispatchQueue.main.async {
                    self.isProcessingImports = !self.importQueue.operations.isEmpty
                    guard self.isProcessingImports else {
                        completionHandler()
                        return
                    }
                }
            }
            importQueue.addOperation(operation)
        }
    }
    
    func loadSampleWorkouts() {
        DispatchQueue.main.async {
            self.workouts = Self.sampleWorkouts()
        }
    }
    
}

// MARK: Sample Workouts

extension ImportManager {
    
    static func sampleWorkouts() -> [WorkoutImport] {
        [
            workoutWithStatus(.new, sport: .cycling),
            workoutWithStatus(.new, sport: .cycling, indoor: true),
            workoutWithStatus(.new, sport: .cycling),
            workoutWithStatus(.notSupported, sport: .running),
            workoutWithStatus(.notSupported, sport: .walking),
            workoutWithStatus(.processed, sport: .cycling),
            workoutWithStatus(.failed, sport: .cycling)
        ]
    }
    
    static func sampleWorkout() -> WorkoutImport {
        workoutWithStatus(.new, sport: .cycling, indoor: false)
    }
    
    private static func workoutWithStatus(_ status: WorkoutImport.Status, sport: WorkoutImport.Sport, indoor: Bool = false) -> WorkoutImport {
        let workout = WorkoutImport(status: status, sport: sport)
        workout.indoor = indoor
        workout.start = .init(valueType: .date, value: Date().timeIntervalSince1970)
        workout.totalDistance = .init(valueType: .distance, value: 16093.4)
        return workout
    }
    
}

