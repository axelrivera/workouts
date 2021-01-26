//
//  HKQuantityType+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 1/6/21.
//

import HealthKit

extension HKQuantityType {
    
    static func distanceCycling() -> HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .distanceCycling)!
    }
    
    static func distanceWalkingRunning() -> HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    }
    
    static func activeEnergyBurned() -> HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    }
    
    static func heartRate() -> HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .heartRate)!
    }
    
}
