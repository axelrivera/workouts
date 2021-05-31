//
//  WorkoutProcessor.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import Foundation
import HealthKit
import CoreLocation

final class WorkoutProcessor {
    
    private lazy var processQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    let workout: HKWorkout
    
    var records = [SampleProcessor.Record]()
    var movingTime: Double = 0
    var avgHeartRate: Double = 0
    var maxHeartRate: Double = 0
    var showMap: Bool = false
    
    // Operations
    private var locationOperation: LocationOperation?
    private var statsOperation: HRStatsOperation?
    private var heartRateOperation: SampleOperation?
    private var cadenceOperation: SampleOperation?
    private var paceOperation: SampleOperation?
    
    init(workout: HKWorkout) {
        self.workout = workout
    }
    
    func generateRecords() {
        var sampleOperations = [Operation]()
        
        if workout.isOutdoor {
            locationOperation = LocationOperation(workout: workout)
            sampleOperations.append(locationOperation!)
        }
                
        statsOperation = HRStatsOperation(workout: workout)
        heartRateOperation = SampleOperation(workout: workout, sampleType: .heartRate)
        sampleOperations.append(contentsOf: [statsOperation!, heartRateOperation!])
                
        if workout.workoutActivityType.isCycling {
            cadenceOperation = SampleOperation(workout: workout, sampleType: .cyclingCadence)
            sampleOperations.append(cadenceOperation!)
        }
        
        if workout.workoutActivityType.isRunningWalking {
            paceOperation = SampleOperation(workout: workout, sampleType: .pace)
            sampleOperations.append(paceOperation!)
        }
        
        let saveOperation = BlockOperation()
        
        saveOperation.addExecutionBlock { [unowned saveOperation, unowned self] in
            if saveOperation.isCancelled { return }
            
            var locations = [CLLocation]()
            if let locationOperation = self.locationOperation {
                locations = locationOperation.locations
            }
            
            let hrSamples = self.heartRateOperation?.samples ?? []
            let cadenceSamples = self.cadenceOperation?.samples ?? []
            let paceSamples = self.paceOperation?.samples ?? []
                        
            let generator = SampleProcessor(
                workout: self.workout,
                locations: locations,
                heartRateSamples: hrSamples,
                cadenceSamples: cadenceSamples,
                paceSamples: paceSamples
            )
            generator.process()
            
            self.showMap = locations.isPresent
            self.records = generator.validRecords
            self.movingTime = generator.movingTime
            self.avgHeartRate = self.statsOperation?.avgHeartRate ?? 0
            self.maxHeartRate = self.statsOperation?.maxHeartRate ?? 0
        }
        
        sampleOperations.forEach { saveOperation.addDependency($0) }
        
        processQueue.addOperations(
            sampleOperations + [saveOperation],
            waitUntilFinished: true
        )
    }
    
}
