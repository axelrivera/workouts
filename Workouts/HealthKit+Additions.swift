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
