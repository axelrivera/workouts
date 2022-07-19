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
        
        static let whitelisted: [State] = [.ok, .empty, .processing]
    }
    
    @Published var workouts = [WorkoutImport]()
    @Published var isProcessingImports = false
    @Published var state = State.empty
        
    private var documents = [FitDocument]()
    
    private lazy var importQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}

// MARK: - Authorization

extension ImportManager {
    
    func success(with completionHandler: @escaping (_ success: Bool) -> Void) {
        // Double check permissions on succeed
        // sample types must be an empty string for success
        // if response is nil or an array with values it means the user did not accept some of the permissions
        
        if let sampleTypes = try? HealthData.shared.filteredWriteSampleTypes(), sampleTypes.isEmpty {
            updateState(workouts.isEmpty ? .empty : .ok)
            completionHandler(true)
        } else {
            self.fail(with: HealthData.DataError.permissionDenied, completionHandler: completionHandler)
        }
    }
    
    func fail(with error: Error, completionHandler: @escaping (_ success: Bool) -> Void) {
        switch error {
        case HealthData.DataError.dataNotAvailable:
            self.updateState(.notAvailable)
        case HealthData.DataError.permissionDenied:
            self.updateState(.notAuthorized)
        default:
            self.updateState(.notAvailable)
        }
        completionHandler(false)
    }
    
    func requestAuthorizationStatus(completionHandler: @escaping (_ success: Bool) -> Void) {
        HealthData.shared.requestStatus(write: HealthData.writeSampleTypes()) { result in
            switch result {
            case .success(let shouldRequest):
                if shouldRequest {
                    self.requestWritingAuthorization(completionHandler: completionHandler)
                    return
                }
                
                self.success(with: completionHandler)
            case .failure(let error):
                self.fail(with: error, completionHandler: completionHandler)
            }
        }
    }
    
    func requestWritingAuthorization(completionHandler: @escaping (_ success: Bool) -> Void) {
        HealthData.shared.requestHealthAuthorization(read: HealthData.readObjectTypes(), write: HealthData.writeSampleTypes()) { result in
            switch result {
            case .success:
                self.success(with: completionHandler)
            case .failure(let error):
                self.fail(with: error, completionHandler: completionHandler)
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
        
    var isImportDisabled: Bool {
        return isProcessingImports || !state.isWhitelisted
    }
    
    var processingWorkouts: [WorkoutImport] {
        workoutsForStatus(.processing)
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
    
    func processDocuments(at documents: [FitDocument], completionHandler: @escaping (() -> Void)) {
        self.documents = documents
        workouts = [WorkoutImport]()
        
        Task(priority: .userInitiated) {
            var workouts = [WorkoutImport]()
            for document in documents {
                await document.open()
                
                if let fitFile = await document.fitFile, let workout = WorkoutImport(fitFile: fitFile) {
                    workouts.append(workout)
                } else {
                    let fileURL = await document.fileURL
                    workouts.append(WorkoutImport(invalidFilename: fileURL.lastPathComponent))
                }
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
    
    func processWorkout(_ workout: WorkoutImport) {
        guard workout.status == .new else { return }
        isProcessingImports = true
        workout.status = .processing
        
        importQueue.addOperation { [unowned self] in
            self.processWorkoutInBackground(workout)
        }
    }
    
    private func processWorkoutInBackground(_ workout: WorkoutImport) {
        Task(priority: .userInitiated) {
            do {
                try await WorkoutDataStore.shared.saveWorkoutImport(workout)
                DispatchQueue.main.async {
                    workout.status = .processed
                }
            } catch {
                DispatchQueue.main.async {
                    workout.status = .failed
                }
            }
            
            await updateProcessingWorkoutsFlag()
        }
    }
    
    @MainActor
    func updateProcessingWorkoutsFlag() {
        let processing = self.processingWorkouts
        self.isProcessingImports = processing.isPresent
    }
    
    func loadSampleWorkouts() {
        self.workouts = Self.sampleWorkouts()
    }
    
}

// MARK: Sample Workouts

extension ImportManager {
    
    static func sampleWorkouts() -> [WorkoutImport] {
        let today = Date()
        let yesterday = today.dayBefore
        
        return [
            workoutWithStatus(.new, sport: .cycling, startDate: today),
            workoutWithStatus(.new, sport: .cycling, startDate: yesterday, indoor: true),
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
    
    private static func workoutWithStatus(_ status: WorkoutImport.Status, sport: Sport, startDate: Date? = nil, indoor: Bool = false) -> WorkoutImport {
        let startDate = startDate ?? Date.dateFor(month: 1, day: 1, year: 2021)!
        let workout = WorkoutImport(status: status, sport: sport)
        workout.indoor = indoor
        workout.start = .init(valueType: .date, value: startDate.timeIntervalSince1970)
        workout.totalDistance = .init(valueType: .distance, value: 32000.0)
        return workout
    }
    
}

