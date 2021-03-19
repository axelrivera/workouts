//
//  CyclingCadenceSamplesOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 3/19/21.
//

import HealthKit

class CyclingCadenceOperation: SyncOperation {
    private var workout: HKWorkout
    
    private(set) var cadenceValues = [TimeAxisValue]()
    
    init(workout: HKWorkout) {
        self.workout = workout
        super.init()
    }
    
    override func start() {
        super.start()
        
        WorkoutDataStore.fetchCyclingCadenceSamples(workout: workout) { result in
            guard let samples = try? result.get(), !samples.isEmpty else {
                self.finish()
                return
            }
            self.updateCyclingCadenceSamples(samples)
        }
    }
    
    private func updateCyclingCadenceSamples(_ samples: [Quantity]) {
        var cadenceValues = [TimeAxisValue]()
                
        let grouped = samples.slicedByMinute(for: \.timestamp)
        let sortedDates = grouped.keys.sorted()
        let startDate = sortedDates[0]
        
        for date in sortedDates {
            let sampleDuration = date.timeIntervalSince(startDate)
            
            if let slice = grouped[date]?.map({ Double($0.value) }), let max = slice.max() {
                cadenceValues.append(TimeAxisValue(duration: sampleDuration, value: max))
            }
        }
        
        self.cadenceValues = cadenceValues
        finish()
    }
    
}
