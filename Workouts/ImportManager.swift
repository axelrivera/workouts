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
        
        static let whitelisted: [State] = [.ok]
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
    
    func success(with completionHandler: @escaping (_ success: Bool) -> Void) {
        // Double check permissions on succeed
        // sample types must be an empty string for success
        // if response is nil or an array with values it means the user did not accept some of the permissions
        
        if let sampleTypes = try? HealthData.filteredWriteSampleTypes(), sampleTypes.isEmpty {
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
        HealthData.requestStatus(write: HealthData.writeSampleTypes()) { result in
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
        HealthData.requestHealthAuthorization(read: HealthData.readObjectTypes(), write: HealthData.writeSampleTypes()) { result in
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
                var tmpURL: URL?
                if url.isZipFile {
                    tmpURL = unzipFitFile(url: url)
                } else {
                    tmpURL = url
                }
                
                guard let fileURL = tmpURL,
                      let workout = WorkoutImport(fileURL: fileURL) else {
                    workouts.append(WorkoutImport(invalidFilename: url.lastPathComponent))
                    continue
                }
                                
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
    
    func processWorkout(_ workout: WorkoutImport) {
        guard workout.status == .new else { return }
        
        isProcessingImports = true
        
        workout.status = .processing
        let operation = ImportOperation(workout: workout)
        operation.completionBlock = {
            DispatchQueue.main.async {
                self.isProcessingImports = !self.importQueue.operations.isEmpty
            }
        }
        importQueue.addOperation(operation)
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

