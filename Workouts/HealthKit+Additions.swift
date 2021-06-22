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
    
    static func weight() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .bodyMass)!
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
    
    var isIndoor: Bool {
        metadata?[HKMetadataKeyIndoorWorkout] as? Bool ?? false
    }
    
    var isOutdoor: Bool {
        !isIndoor
    }
    
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
    
    var elevationAscended: HKQuantity? {
        metadata?[HKMetadataKeyElevationAscended] as? HKQuantity
    }
    
    var elevationDescended: HKQuantity? {
        metadata?[HKMetadataKeyElevationDescended] as? HKQuantity
    }
    
}

extension HKWorkoutActivityType {
    
    func sport() -> Sport {
        switch self {
        case .cycling:
            return .cycling
        case .running:
            return .running
        case .walking:
            return .walking
        default:
            return .other
        }
    }
    
    var isCycling: Bool {
        self == .cycling
    }
    
    var isRunningWalking: Bool {
        Self.runninWalkingActivities.contains(self)
    }
    
    static let runninWalkingActivities: [HKWorkoutActivityType] = [.running, .walking]
    
}
