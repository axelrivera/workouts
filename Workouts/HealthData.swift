//
//  HealthData.swift
//  Workouts
//
//  Created by Axel Rivera on 12/31/20.
//

import Foundation
import HealthKit

final class HealthData {
    enum DataError: Error {
        case dataNotAvailable
        case requestFailed
        case unknown(Error)
    }
    
    static let healthStore = HKHealthStore()
    
    private static let userDefaults = UserDefaults.standard
    private static let anchorKeyPrefix = "ARN_Anchor_"
}

// MARK: - Permission

extension HealthData {
    
    class func readPermissions() -> Set<HKObjectType> {
        [
            HKSeriesType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType.distanceCycling(),
            HKQuantityType.distanceWalkingRunning(),
            HKQuantityType.activeEnergyBurned(),
            HKQuantityType.heartRate()
        ]
    }
    
    class func writePermissions() -> Set<HKSampleType> {
        [
            HKSeriesType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType.distanceCycling(),
            HKQuantityType.distanceWalkingRunning(),
            HKQuantityType.activeEnergyBurned(),
            HKQuantityType.heartRate()
        ]
    }
    
    class func requestHealthAuthorization(completion: @escaping (Result<Bool, DataError>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.failure(.dataNotAvailable))
            return
        }
        
        healthStore.requestAuthorization(
            toShare: writePermissions(),
            read: readPermissions()) { (success, error) in
            guard success else {
                completion(.success(true))
                return
            }
            
            let failureError: DataError = error == nil ? .requestFailed : .unknown(error!)
            completion(.failure(failureError))
        }
    }
    
}

// MARK: - Anchors

extension HealthData {
    
    private class func anchorKey(for type: HKSampleType) -> String {
        anchorKeyPrefix + type.identifier
    }
    
    class func getAnchor(for type: HKSampleType) -> HKQueryAnchor? {
        guard let data = userDefaults.object(forKey: anchorKey(for: type)) as? Data else {
            return nil
        }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
    }
    
    class func updateAnchor(_ anchor: HKQueryAnchor?, from query: HKAnchoredObjectQuery) {
        guard let sampleType = query.objectType as? HKSampleType else {
            Log.debug("unable to save anchor for: \(query.objectType?.identifier ?? "n/a")")
            return
        }
        setAnchor(anchor, for: sampleType)
    }
    
    private class func setAnchor(_ anchor: HKQueryAnchor?, for type: HKSampleType) {
        guard let anchor = anchor else { return }
        let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
        userDefaults.set(data, forKey: anchorKey(for: type))
    }
    
}
