//
//  WorkoutSamplesProcessor.swift
//  Workouts
//
//  Created by Axel Rivera on 8/9/21.
//

import HealthKit

class WorkoutSamplesProcessor {
    let stepInMeters: Double = 10
    
    private lazy var processQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    private(set) var workout: Workout
    
    private(set) var store = WorkoutDataStore.shared
    private(set) var workoutIntervals = [WorkoutInterval]()
    
    var sport: Sport { workout.sport }
    
    var interval: DateInterval { DateInterval(start: workout.start, end: workout.end) }
    var completionHandler: ((_ intervals: [WorkoutInterval]) -> Void)?
    
    init(workout: Workout) {
        self.workout = workout
    }
    
    func process(completionHandler: @escaping (_ intervals: [WorkoutInterval]) -> Void) {
        self.completionHandler = completionHandler
        
        store.fetchWorkout(for: workout.remoteIdentifier!) { [weak self] remoteWorkout in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let remoteWorkout = remoteWorkout {
                    Log.debug("found remote workout")
                    self.process(remoteWorkout: remoteWorkout)
                } else {
                    assertionFailure("missing remote workout")
                }
            }
        }
    }
    
    private func process(remoteWorkout: HKWorkout) {
        Log.debug("processing remote workout")
        let interval = self.interval
        let source = remoteWorkout.sourceRevision.source
        
        var operations = [Operation]()
        
        let heartRateOperation = MaxSampleOperation(quantityType: .heartRate(), unit: .bpm(), interval: interval, source: source)
        let cyclingOperation = DistanceSampleOperation(quantityType: .distanceCycling(), unit: .meter(), interval: interval, source: nil)
        let runningOperation = DistanceSampleOperation(quantityType: .distanceWalkingRunning(), unit: .meter(), interval: interval, source: nil)
        
        operations.append(heartRateOperation)
        
        if sport.isCycling {
            operations.append(cyclingOperation)
        } else if sport.isWalkingOrRunning {
            operations.append(runningOperation)
        }
        
        let completionOperation = BlockOperation { [weak self] in
            guard let self = self else { return }
            
            let heartRate = heartRateOperation.samples
            let cycling = cyclingOperation.samples
            let running = runningOperation.samples
            
            let intervals = self.intervalsForDistanceSamples(self.sport.isCycling ? cycling : running)
            
            Log.debug("intervals: \(intervals.count)")
            
            for sample in heartRate {
                guard let interval = intervals.first(where: { $0.interval.contains(sample.start) }) else {
                    Log.debug("ignoring sample for start: \(sample.start), end: \(sample.end)")
                    continue
                }
                interval.heartRate = max(interval.heartRate, sample.value)
            }
            
            let data = intervals.compactMap({$0.heartRate > 0 ? $0.heartRate : nil })
            Log.debug("heart rate data: \(data.count)")
            
            self.completionHandler?(intervals)
        }
        
        operations.forEach { completionOperation.addDependency($0) }
        operations.append(completionOperation)
        
        processQueue.addOperations(operations, waitUntilFinished: true)
        processQueue.waitUntilAllOperationsAreFinished()
    }
    
    private func intervalsForDistanceSamples(_ samples: [Quantity]) -> [WorkoutInterval] {
        var chunks = [[Quantity]]()
        var currentChunk = [Quantity]()
        var accumulatedDistance: Double = 0
        
        if let first = samples.first {
            currentChunk.append(first)
        }
        
        for distance in samples {
            accumulatedDistance += distance.value
            if accumulatedDistance > stepInMeters {
                chunks.append(currentChunk)
                accumulatedDistance = 0
                currentChunk = [distance]
            } else {
                currentChunk.append(distance)
            }
        }
        
        if samples.count > 1 && currentChunk.isPresent {
            chunks.append(currentChunk)
        }
        
        var intervals = [WorkoutInterval]()
        var totalDistance: Double = 0
        
        for chunk in chunks {
            guard let start = chunk.first?.start, let end = chunk.last?.end else { continue }
            
            let distance = chunk.map({ $0.value }).reduce(0, +)
            totalDistance += distance
            
            let interval = WorkoutInterval(start: start, end: end)
            interval.cummulativeDistance = totalDistance
            interval.distance = distance
            
            intervals.append(interval)
        }
        
        return intervals
    }
    
}
