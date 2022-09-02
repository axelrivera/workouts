//
//  WorkoutImportManager.swift
//  Workouts
//
//  Created by Axel Rivera on 8/10/22.
//

import Foundation
import CoreData
import SwiftUI
import HealthKit

extension ImportManager {
    
    enum EmptyState {
        case `default`, notAvailable
        
        var isReady: Bool {
            self == .default
        }
    }
    
    enum Screen {
        case single, multiple, empty
    }
    
}

class ImportManager: ObservableObject {
    private let IMPORT_CHUNK_SIZE = 2
    let PROCESS_WHITELIST: [WorkoutImport.Status] = [.new, .duplicate]
    
    @Published var isGeneratingWorkoutFiles = false
    @Published var isProcessing = false
    @Published var visibleScreen = Screen.empty
    @Published var emptyState = EmptyState.default
    @Published var showDocumentPicker = false
    
    @Published var workouts = [WorkoutImport]()
    @Published var singleWorkout = WorkoutImport(status: .empty, sport: .other)
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
}

// MARK: - Authorization

extension ImportManager {
    
    func success(with completionHandler: @escaping (_ success: Bool) -> Void) {
        // Double check permissions on succeed
        // sample types must be an empty string for success
        // if response is nil or an array with values it means the user did not accept some of the permissions

        if let sampleTypes = try? HealthData.shared.filteredWriteSampleTypes(), sampleTypes.isEmpty {
            updateEmptyState(.default)
            completionHandler(true)
        } else {
            updateEmptyState(.notAvailable)
            completionHandler(false)
        }
    }

    func fail(with error: Error, completionHandler: @escaping (_ success: Bool) -> Void) {
        self.updateEmptyState(.notAvailable)
        completionHandler(false)
    }
    
    func updateEmptyState(_ emptyState: EmptyState) {
        DispatchQueue.main.async {
            withAnimation {
                self.emptyState = emptyState
            }
        }
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
    
}

// MARK: - Updates

extension ImportManager {
    
    func updateScreen() {
        let screen: Screen
        if !singleWorkout.status.isValid && workouts.isEmpty {
            screen = .empty
        } else {
            if singleWorkout.status.isValid {
                screen = .single
            } else {
                screen = .multiple
            }
        }
        self.visibleScreen = screen
    }
    
    func updateSingleWorkout() {
        if workouts.count == 1 {
            self.singleWorkout = workouts[0]
        } else {
            self.singleWorkout = WorkoutImport(status: .empty, sport: .other)
        }
    }
    
    func generateWorkouts(with documents: [FitDocument]) async {
        var existingWorkouts = self.workouts.filter({ PROCESS_WHITELIST.contains($0.status) })
        
        for document in documents {
            let _ = await document.open()
            
            if let file = await document.fitFile, let workout = WorkoutImport(fitFile: file) {
                guard existingWorkouts.filter({ $0.id == workout.id }).isEmpty else {
                    continue
                }
                
                if let date = workout.startDate, Workout.isPresent(start: date, sport: workout.sport, in: viewContext) {
                    workout.status = .duplicate
                }
                
                existingWorkouts.insert(workout, at: 0)
            } else {
                let name = await document.fileURL.lastPathComponent
                existingWorkouts.insert(WorkoutImport(invalidFilename: name), at: 0)
            }
        }
        
        let workouts = existingWorkouts
        DispatchQueue.main.async {
            withAnimation {
                self.workouts = workouts
                self.updateSingleWorkout()
                self.updateScreen()
            }
        }
    }
    
    func delete(workout: WorkoutImport, completionHandler: (_ shouldDismiss: Bool) -> Void) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts.remove(at: index)
        }
        updateSingleWorkout()
        
        completionHandler(visibleScreen == .multiple)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.workouts.isEmpty {
                self.visibleScreen = .empty
            }
        }
    }
    
    func delete(at offsets: IndexSet) {
        workouts.remove(atOffsets: offsets)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.workouts.isEmpty {
                self.updateSingleWorkout()
                self.visibleScreen = .empty
            }
        }
    }
    
    func discardAll() {
        self.workouts = []
        self.updateSingleWorkout()
        self.updateScreen()
    }
    
}

// MARK: Processing

extension ImportManager {
    
    func processWorkouts(singleWorkout workout: WorkoutImport? = nil) async {
        let newWorkouts: [WorkoutImport]
        if let workout = workout {
            newWorkouts = workout.status == .new ? [workout] : []
        } else {
            newWorkouts = workouts.filter({ $0.status == .new })
        }
        
        if newWorkouts.isEmpty { return }
        
        await setIsProcessing(true)
        
        newWorkouts.forEach { workout in
            DispatchQueue.main.async {
                workout.status = .processing
            }
        }
        
        let chunks = newWorkouts.chunks(ofCount: IMPORT_CHUNK_SIZE)
        for chunk in chunks {
            let _ = await withTaskGroup(of: WorkoutImport.self) { group in
                var workouts = [WorkoutImport]()
                
                for workout in chunk {
                    group.addTask {
                        do {
                            try await WorkoutDataStore.shared.saveWorkoutImport(workout)
                            DispatchQueue.main.async {
                                workout.status = .processed
                            }
                        } catch {
                            Log.debug("import failed: \(error.localizedDescription)")
                            
                            DispatchQueue.main.async {
                                workout.status = .failed
                            }
                        }
                        return workout
                    }
                }
                
                for await workout in group {
                    workouts.append(workout)
                }
            }
        }
        
        await setIsProcessing(false)
    }
    
    @MainActor
    func setIsProcessing(_ isProcessing: Bool) {
        self.isProcessing = isProcessing
    }
    
}
