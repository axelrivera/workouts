//
//  DetailManager.swift
//  Workouts
//
//  Created by Axel Rivera on 1/28/21.
//

import Foundation
import MapKit
import SwiftUI
import HealthKit

class DetailManager: ObservableObject {
    @Published var locations = [CLLocation]() {
        didSet {
            points = locations.map { $0.coordinate }
        }
    }
    
    private lazy var processQueue: OperationQueue = {
       let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    var isProcessing: Bool {
        processQueue.operations.isPresent
    }
    
    private var routeOperation: RouteOperation?
    private var paceOperation: PaceOperation?
    private var heartRateStatsOperation: HeartRateStatsOperation?
    private var heartRateOperation: HeartRateOperation?
    private var cadenceOperation: CyclingCadenceOperation?
    
    @Published var updateUI = false
    @Published var showAnalysis = false
    
    @Published var points = [CLLocationCoordinate2D]()
    
    @Published var showDetailMap = false
    @Published var locationName: String?
    @Published var avgHeartRate: Double?
    @Published var maxHeartRate: Double?
    
    @Published var movingTime: Double = 0
    @Published var bestPace: Double = 0
    
    @Published var avgSpeed: Double = 0
    @Published var avgMovingSpeed: Double = 0
    @Published var maxSpeed: Double = 0
    
    @Published var minElevation: Double = 0
    @Published var maxElevation: Double = 0
    
    @Published var heartRateValues = [TimeAxisValue]()
    @Published var speedValues = [TimeAxisValue]()
    @Published var cyclingCadenceValues = [TimeAxisValue]()
    @Published var paceValues = [TimeAxisValue]()
    @Published var altitudeValues = [TimeAxisValue]()
    
    var isFetchingLocation = false
    var workoutID: UUID
    private var workout: HKWorkout?
    
    init(workoutID: UUID) {
        self.workoutID = workoutID
        fetchData()
    }
    
}

extension DetailManager {
    
    func fetchData() {
        if let workout = workout {
            addOperations(workout: workout)
        } else {
            WorkoutDataStore.fetchWorkout(for: workoutID) { [weak self] (workout) in
                guard let self = self else { return }
                guard let workout = workout else { return }
                self.addOperations(workout: workout)
            }
        }
    }
    
    func addOperations(workout: HKWorkout) {
        if isProcessing { return }
        
        let completionOperation = BlockOperation { [weak self] in
            Log.debug("completed operations")
            guard let self = self else { return }
            self.updateValues()
        }
        
        let routeOperation = RouteOperation(workout: workout)
        completionOperation.addDependency(routeOperation)
        
        var paceOperation: PaceOperation?
        if Workout.paceActivities.contains(workout.workoutActivityType) {
            paceOperation = PaceOperation(workout: workout)
            completionOperation.addDependency(paceOperation!)
        }
        
        let heartRateStatsOperation = HeartRateStatsOperation(workout: workout)
        completionOperation.addDependency(heartRateStatsOperation)
        
        let heartRateOperation = HeartRateOperation(workout: workout)
        completionOperation.addDependency(heartRateOperation)
        
        var cadenceOperation: CyclingCadenceOperation?
        if workout.workoutActivityType == .cycling {
            cadenceOperation = CyclingCadenceOperation(workout: workout)
            completionOperation.addDependency(cadenceOperation!)
        }
        
        let operations: [Operation?] = [
            routeOperation,
            paceOperation,
            heartRateStatsOperation,
            heartRateOperation,
            cadenceOperation,
            completionOperation
        ]
        
        Log.debug("adding operations")
        
        operations.compactMap({ $0 }).forEach { operation in
            processQueue.addOperation(operation)
        }
        
        self.routeOperation = routeOperation
        self.paceOperation = paceOperation
        self.heartRateStatsOperation = heartRateStatsOperation
        self.heartRateOperation = heartRateOperation
        self.cadenceOperation = cadenceOperation
    }
    
    func updateValues() {
        guard let routeOperation = routeOperation,
              let heartRateStatsOperation = heartRateStatsOperation,
              let heartRateOperation = heartRateOperation else { return }
        
        let locations = routeOperation.locations
        let locationName = routeOperation.locationName
        let movingTime = routeOperation.movingTime
        let speedValues = routeOperation.speedValues
        let altitudeValues = routeOperation.altitudeValues
        let avgSpeed = routeOperation.avgSpeed
        let avgMovingSpeed = routeOperation.avgMovingSpeed
        let maxSpeed = routeOperation.maxSpeed
        let minElevation = routeOperation.minElevation
        let maxElevation = routeOperation.maxElevation
        
        let avgHeartRate = heartRateStatsOperation.avgHeartRate
        let maxHeartRate = heartRateStatsOperation.maxHeartRate
        
        let heartRateValues = heartRateOperation.heartRateValues
        
        let paceValues = paceOperation?.paceValues ?? [TimeAxisValue]()
        let bestPace = paceOperation?.bestPace ?? 0
        
        let cyclingCadenceValues = cadenceOperation?.cadenceValues ?? [TimeAxisValue]()
        
        let valuesCheck = [
            heartRateValues.isPresent,
            speedValues.isPresent,
            cyclingCadenceValues.isPresent,
            paceValues.isPresent,
            altitudeValues.isPresent
        ]
        
        let showAnalysis = valuesCheck.filter({ $0 == true }).isPresent
        let showDetailMap = locations.isPresent
        
        Log.debug("update values in UI")
        
        resetQueues()
        DispatchQueue.main.async {
            withAnimation {
                self.locations = locations
                self.locationName = locationName
                self.movingTime = movingTime
                self.speedValues = speedValues
                self.altitudeValues = altitudeValues
                self.avgSpeed = avgSpeed
                self.avgMovingSpeed = avgMovingSpeed
                self.maxSpeed = maxSpeed
                self.minElevation = minElevation
                self.maxElevation = maxElevation
                self.avgHeartRate = avgHeartRate
                self.maxHeartRate = maxHeartRate
                self.heartRateValues = heartRateValues
                self.paceValues = paceValues
                self.bestPace = bestPace
                self.cyclingCadenceValues = cyclingCadenceValues
                self.showAnalysis = showAnalysis
                self.showDetailMap = showDetailMap
                self.updateUI = true
            }
        }
    }
    
    func resetQueues() {
        if isProcessing { return }
        routeOperation = nil
        paceOperation = nil
        heartRateStatsOperation = nil
        heartRateOperation = nil
        cadenceOperation = nil
    }
    
    var showSpeedSection: Bool {
        speedValues.isPresent
    }
    
    var showHeartRateSection: Bool {
        heartRateValues.isPresent || avgHeartRate != nil || maxHeartRate != nil
    }
    
}
