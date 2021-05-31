//
//  SampleOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import Foundation
import HealthKit

extension SampleOperation {
    enum SampleType {
        case heartRate, cyclingCadence, pace, none
    }
}

final class SampleOperation: SyncOperation {
    private(set) var sampleType: SampleType
    private var workout: HKWorkout
    
    private(set) var samples = [Quantity]()
    
    init(workout: HKWorkout, sampleType: SampleType) {
        self.workout = workout
        self.sampleType = sampleType
        super.init()
    }
    
    override func start() {
        super.start()
        
        switch sampleType {
        case .heartRate:
            fetchHeartRateSamples()
        case .cyclingCadence:
            fetchCyclingCadenceSamples()
        case .pace:
            fetchRunningWalkingPaceSamples()
        default:
            finish()
        }
    }
    
}

extension SampleOperation {
    
    private func completionHandler() -> (Result<[Quantity], Error>) -> Void {
        let completion: (Result<[Quantity], Error>) -> Void = { [unowned self] result in
            if let samples = try? result.get() {
                self.samples = samples
            }
            
            self.finish()
        }
        return completion
    }
    
    func fetchHeartRateSamples() {
        WorkoutDataStore.fetchHeartRateSamples(workout: workout, completionHandler: completionHandler())
    }
    
    func fetchCyclingCadenceSamples() {
        WorkoutDataStore.fetchCyclingCadenceSamples(workout: workout, completionHandler: completionHandler())
    }
    
    func fetchRunningWalkingPaceSamples() {
        WorkoutDataStore.fetchRunningWalkingPaceSamples(workout: workout, completionHandler: completionHandler())
    }
    
}
