//
//  ImportManager.swift
//  Workouts
//
//  Created by Axel Rivera on 1/31/21.
//

import SwiftUI
import FitFileParser
import HealthKit

class ImportManager: ObservableObject {
    enum State {
        case processing, ok, empty, notAuthorized, notAvailable
        
        var isWhitelisted: Bool {
            Self.whitelisted.contains(self)
        }
        
        var showEmptyView: Bool {
            Self.emptyViewStates.contains(self)
        }
        
        static let whitelisted: [State] = [.ok, .empty]
        static let emptyViewStates: [State] = [.empty, .notAuthorized, notAvailable]
    }
    
    @Published var workouts = [WorkoutImport]()
    @Published var isProcessingImports = false
    @Published var state = State.empty
    
    private var urls = [URL]()
    
    private lazy var importQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}

// MARK: - Authorization

extension ImportManager {
    
    func requestWritingAuthorization(completionHandler: @escaping (_ success: Bool) -> Void) {
        HealthData.requestWritingAuthorization { result in
            switch result {
            case .success:
                let validationStatus = HealthData.validateWritingStatus()
                self.updateState(with: validationStatus)
                completionHandler(true)
            case .failure(let error):
                if case HealthData.DataError.dataNotAvailable = error {
                    self.updateState(.notAvailable)
                }
                completionHandler(false)
            }
        }
    }
    
    func updateState(with status: HKAuthorizationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .sharingAuthorized:
                withAnimation {
                    self.state = self.workouts.isEmpty ? .empty : .ok
                }
            default:
                withAnimation {
                    self.state = .notAuthorized
                }
            }
        }
    }
    
    func updateState(_ state: State) {
        DispatchQueue.main.async {
            withAnimation {
                self.state = state
            }
        }
    }
    
}

// MARK: - Selection Logic

extension ImportManager {
    func deleteWorkout(at offsets: IndexSet) {
        DispatchQueue.main.async {
            self.workouts.remove(atOffsets: offsets)
            withAnimation {
                self.state = self.workouts.isEmpty ? .empty : .ok
            }
        }
    }
        
    var isImportDisabled: Bool {
        return newWorkouts.isEmpty || isProcessingImports || !state.isWhitelisted
    }
    
    var isAddImportDisabled: Bool {
        isProcessingImports || !state.isWhitelisted
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
    
    func processDocuments(at urls: [URL], completionHandler: @escaping (() -> Void)) {
        self.urls = urls
        workouts = [WorkoutImport]()
        
        DispatchQueue.global(qos: .userInitiated).async {
            var workouts = [WorkoutImport]()
            for url in urls {
                guard let fit = FitFile(file: url) else { continue }
                guard let workout = WorkoutImport(fit: fit) else { continue }
                workouts.append(workout)
            }
            
            let sortedWorkouts = workouts.sorted(by: { (lhs, rhs) -> Bool in
                guard let leftDate = lhs.startDate, let rightDate = rhs.startDate else { return false }
                return leftDate > rightDate
            })
            
            DispatchQueue.main.async {
                self.workouts = sortedWorkouts
                completionHandler()
            }
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

