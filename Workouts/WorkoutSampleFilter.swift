//
//  WorkoutSampleFilter.swift
//  WorkoutSampleFilter
//
//  Created by Axel Rivera on 8/13/21.
//

import Foundation
import HealthKit
import CoreLocation

final class WorkoutSampleFilter {
    let locations: [CLLocation]
    let heartRateSamples: [Quantity]
    let cadenceSamples: [Quantity]
    
    private var locationDictionary = [Int: CLLocation]()
    private var heartRateDictionary = [Int: Quantity]()
    private var cadenceDictionary = [Int: Quantity]()
    
    
    init(locations: [CLLocation], heartRateSamples: [Quantity], cadenceSamples: [Quantity]) {
        self.locations = locations
        self.heartRateSamples = heartRateSamples
        self.cadenceSamples = cadenceSamples
        generateCache()
    }
    
}

// MARK: - Samples

extension WorkoutSampleFilter {
    
    func filterLocations(for interval: DateInterval) -> [CLLocation] {
        if locations.isEmpty { return [] }
        
        let startIndex = indexForTimestamp(interval.start)
        let endIndex = indexForTimestamp(interval.end)
        
        var locations = [CLLocation]()
        for index in startIndex ... endIndex {
            guard let location = locationDictionary[index] else { continue }
            locations.append(location)
        }
        return locations
    }
    
    func filterHeartRateSamples(for interval: DateInterval) -> [Quantity] {
        if heartRateSamples.isEmpty { return [] }
        
        let startIndex = indexForTimestamp(interval.start)
        let endIndex = indexForTimestamp(interval.end)
        
        var samples = [Quantity]()
        for index in startIndex ... endIndex {
            guard let sample = heartRateDictionary[index] else { continue }
            samples.append(sample)
        }
        return samples
    }
    
    func filterCadenceSamples(for interval: DateInterval) -> [Quantity] {
        if cadenceSamples.isEmpty { return [] }
        
        let startIndex = indexForTimestamp(interval.start)
        let endIndex = indexForTimestamp(interval.end)
        
        var samples = [Quantity]()
        for index in startIndex ... endIndex {
            if let sample = cadenceDictionary[index] {
                samples.append(sample)
            } else {
                let timestamp = Date(timeIntervalSince1970: Double(index))
                let zeroSample = Quantity(start: timestamp, end: timestamp, value: 0)
                samples.append(zeroSample)
            }
        }
        return samples
    }
    
    
}

// MARK: - Records

extension WorkoutSampleFilter {
    
    func generateCache() {
        for location in locations {
            let index = indexForTimestamp(location.timestamp)
            
            if let existing = locationDictionary[index] {
                if location.timestamp > existing.timestamp {
                    locationDictionary[index] = location
                }
            } else {
                locationDictionary[index] = location
            }
            
        }
        
        for sample in heartRateSamples {
            let index = indexForTimestamp(sample.timestamp)
            if let existing = heartRateDictionary[index] {
                if sample.value > existing.value {
                    heartRateDictionary[index] = sample
                }
            } else {
                heartRateDictionary[index] = sample
            }
        }
        
        for sample in cadenceSamples {
            let index = indexForTimestamp(sample.timestamp)
            if let existing = cadenceDictionary[index] {
                if sample.value > existing.value {
                    cadenceDictionary[index] = sample
                }
            } else {
                cadenceDictionary[index] = sample
            }
        }
    }
    
    private func indexForTimestamp(_ timestamp: Date) -> Int {
        Int(truncating: timestamp.timeIntervalSince1970 as NSNumber)
    }
    
}
