//
//  HKQuantityType+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 1/6/21.
//

import HealthKit

extension HKQuantityType {
    
    static func distanceCycling() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .distanceCycling)!
    }
    
    static func distanceWalkingRunning() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!
    }
    
    static func activeEnergyBurned() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!
    }
    
    static func heartRate() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .heartRate)!
    }
    
}

extension HKQuantity {
    
    static func quantity(for value: Double?, unit: HKUnit) -> HKQuantity? {
        guard let value = value else { return nil }
        return HKQuantity(unit: unit, doubleValue: value)
    }
    
}

extension HKUnit {
    
    static func bpm() -> HKUnit {
        HKUnit.count().unitDivided(by: HKUnit.minute())
    }
    
    static func celcius() -> HKUnit {
        HKUnit.degreeCelsius()
    }
    
    static func metersPerSecond() -> HKUnit {
        HKUnit.meter().unitDivided(by: .second())
    }
    
}

extension HKWorkout {
    
    var avgSpeed: HKQuantity? {
        metadata?[HKMetadataKeyAverageSpeed] as? HKQuantity
    }
    
    var maxSpeed: HKQuantity? {
        metadata?[HKMetadataKeyMaximumSpeed] as? HKQuantity
    }
    
    var avgCyclingCadence: Double? {
        metadata?[MetadataKeyAvgCyclingCadence] as? Double
    }
    
    var maxCyclingCadence: Double? {
        metadata?[MetadataKeyMaxCyclingCadence] as? Double
    }
    
}
