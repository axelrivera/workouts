//
//  HRZonesProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 7/31/22.
//

import Foundation
import HealthKit

struct HRZonesProvider {
    
    let healthProvider = HealthProvider.shared
    func fetchZones(for remoteWorkout: HKWorkout, values: [Int]) async throws -> [HRZoneSummary] {
        let calculator = HRZonesCalculator(maxHeartRate: 0, values: values)
        
        let dateInterval = DateInterval(start: remoteWorkout.startDate, end: remoteWorkout.endDate)
        let source = remoteWorkout.sourceRevision.source
        
        let samples = try await healthProvider.fetchHeartRateSamples(interval: dateInterval, source: source)
                
        let startIndex = KeyForTimestamp(remoteWorkout.startDate)
        let endIndex = KeyForTimestamp(remoteWorkout.endDate)
        
        var dictionary = [Int: Quantity]()
        for key in startIndex ... endIndex {
            let timestamp = Date(timeIntervalSince1970: Double(key))
            dictionary[key] = Quantity(start: timestamp, end: timestamp, value: 0)
        }
        
        for sample in samples {
            let key = KeyForTimestamp(sample.timestamp)
            guard let quantity = dictionary[key] else { continue }
            
            if sample.value > quantity.value {
                let timestamp = Date(timeIntervalSince1970: Double(key))
                dictionary[key] = Quantity(start: timestamp, end: timestamp, value: sample.value)
            }
        }
        
        // padding
        let quantities = dictionary.values.sorted(by: { $0.timestamp < $1.timestamp })
        
        var currentValue: Double = quantities.first(where: { $0.value > 0 })?.value ?? 0
        var paddedQuantities = [Quantity]()
        
        for quantity in quantities {
            if quantity.value == 0 && currentValue > 0 {
                let newQuantity = Quantity(start: quantity.start, end: quantity.end, value: currentValue)
                paddedQuantities.append(newQuantity)
            } else {
                paddedQuantities.append(quantity)
            }
            
            if quantity.value > 0 {
                currentValue = quantity.value
            }
        }
        
        return try calculator.summaries(for: paddedQuantities)
    }
    
}
