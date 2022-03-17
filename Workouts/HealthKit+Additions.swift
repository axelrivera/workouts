//
//  HKQuantityType+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 1/6/21.
//

import HealthKit
import CoreLocation

extension HKQuantityType {
    
    static func distanceCycling() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .distanceCycling)!
    }
    
    static func distanceWalkingRunning() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!
    }
    
    static func distanceWheelchair() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .distanceWheelchair)!
    }
    
    static func pushCount() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .pushCount)!
    }
    
    static func distanceSwimming() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .distanceSwimming)!
    }
    
    static func swimmingStrokeCount() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .swimmingStrokeCount)!
    }
    
    static func distanceDownhillSnowSports() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .distanceDownhillSnowSports)!
    }
    
    static func activeEnergyBurned() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!
    }
    
    static func exerciseTime() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .appleExerciseTime)!
    }
    
    static func stepCount() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .stepCount)!
    }
    
    static func flightsClimbed() -> HKQuantityType {
        HKSampleType.quantityType(forIdentifier: .flightsClimbed)!
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
    
    var totalElapsedTime: Double {
        endDate.timeIntervalSince(startDate)
    }
    
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
    
    var movingTime: Double? {
        metadata?[MetadataKeyMovingTime] as? Double
    }
    
    var avgHeartRate: Double? {
        metadata?[MetadataKeyAvgHeartRate] as? Double
    }
    
    var minHeartRate: Double? {
        metadata?[MetadataKeyMinHeartRate] as? Double
    }
    
    var maxHeartRate: Double? {
        metadata?[MetadataKeyMaxHeartRate] as? Double
    }
    
    var startCoordinate: CLLocationCoordinate2D? {
        guard let lat = metadata?[MetadataKeyStartLatitude] as? Double, let long = metadata?[MetadataKeyStartLongitude] as? Double else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    var maxAltitude: Double? {
        metadata?[MetadataKeyMaxAltitude] as? Double
    }
    
    var minAltitude: Double? {
        metadata?[MetadataKeyMaxAltitude] as? Double
    }
    
}
