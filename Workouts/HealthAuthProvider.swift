//
//  HealthAuthProvider.swift
//  HealthAuthProvider
//
//  Created by Axel Rivera on 8/20/21.
//

import Foundation
import HealthKit

actor HealthAuthProvider {
    static let shared = HealthAuthProvider()
    
    let store = HealthProvider.shared.healthStore
    private let isAvailable = HealthProvider.shared.isAvailable
    
    var isAuthorized = false
    
    private init() {
        // no-op
    }
    
}

// MARK: - Async/Await Methods

extension HealthAuthProvider {
    
    func shouldRequestStatus() async -> Bool {
        guard isAvailable else { return false }
        
        do {
            let status = try await store.statusForAuthorizationRequest(toShare: Self.writeSampleTypes(), read: Self.readObjectTypes())
            return status == .shouldRequest
        } catch {
            return false
        }
    }
    
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        
        do {
            try await store.requestAuthorization(toShare: Self.writeSampleTypes(), read: Self.readObjectTypes())
            isAuthorized = true
            return true
        } catch {
            Log.debug("health kit authorization failed: \(error)")
            return false
        }
        
    }
    
}

// MARK: Closure Methods

extension HealthAuthProvider {
    
    static func readObjectTypes() -> Set<HKObjectType> {
        [
            HKCharacteristicType.dateOfBirth(),
            HKCharacteristicType.biologicalSex(),
            HKSeriesType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType.distanceCycling(),
            HKQuantityType.distanceWalkingRunning(),
            HKQuantityType.distanceWheelchair(),
            HKQuantityType.pushCount(),
            HKQuantityType.distanceSwimming(),
            HKQuantityType.swimmingStrokeCount(),
            HKQuantityType.distanceDownhillSnowSports(),
            HKQuantityType.activeEnergyBurned(),
            HKQuantityType.flightsClimbed(),
            HKQuantityType.stepCount(),
            HKQuantityType.exerciseTime(),
            HKQuantityType.heartRate(),
            HKQuantityType.restingHeartRate()
        ]
    }
    
    static func writeSampleTypes() -> Set<HKSampleType> {
        [
            HKSeriesType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType.distanceCycling(),
            HKQuantityType.distanceWalkingRunning(),
            HKQuantityType.activeEnergyBurned(),
            HKQuantityType.heartRate(),
        ]
    }
    
    
    
}
