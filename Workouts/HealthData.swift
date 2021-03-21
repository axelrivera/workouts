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
        case failed
        case permissionDenied
        case unknown(Error)
    }
    
    static let healthStore = HKHealthStore()
    
    private static let userDefaults = UserDefaults.standard
    private static let anchorKeyPrefix = "ARN_Anchor_"
}

extension HealthData.DataError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .dataNotAvailable:
            return "Data Not Available"
        case .failed:
            return "Reques Failed"
        case .permissionDenied:
            return "Permission Denied"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    
}

// MARK: - Permission

extension HealthData {
    
    class func readObjectTypes() -> Set<HKObjectType> {
        [
            HKSeriesType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType.distanceCycling(),
            HKQuantityType.distanceWalkingRunning(),
            HKQuantityType.activeEnergyBurned(),
            HKQuantityType.heartRate(),
            HKQuantityType.weight()
        ]
    }
    
    class func writeSampleTypes() -> Set<HKSampleType> {
        [
            HKSeriesType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType.distanceCycling(),
            HKQuantityType.distanceWalkingRunning(),
            HKQuantityType.activeEnergyBurned(),
            HKQuantityType.heartRate(),
        ]
    }
    
    class func filteredWriteSampleTypes() throws -> Set<HKSampleType> {
        let objects = writeSampleTypes()
        var statuses = [HKSampleType: HKAuthorizationStatus]()
        
        objects.forEach { statuses[$0] = healthStore.authorizationStatus(for: $0) }
        
        Log.debug("statuses for sample types: \(statuses)")
        
        let denied = statuses.compactMap { (object, status) -> HKSampleType? in
            switch status {
            case .notDetermined:
                Log.debug("\(object.identifier): not determined")
            case .sharingAuthorized:
                Log.debug("\(object.identifier): authorized")
            case .sharingDenied:
                Log.debug("\(object.identifier): denied")
            default:
                break
            }
            
            guard status == .sharingDenied else { return nil }
            return object
        }
        
        if denied.isPresent {
            throw DataError.permissionDenied
        }
        
        let notDetermined = statuses.compactMap { (object, status) -> HKSampleType? in
            guard status == .notDetermined else { return nil }
            return object
        }
        
        return Set(notDetermined)
    }
    
    // MARK: - Request Status
    
    class func requestStatusForReading(completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        requestStatus(read: readObjectTypes(), completionHandler: completionHandler)
    }
    
    class func requestStatusForWriting(completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        requestStatus(read: [], write: writeSampleTypes(), completionHandler: completionHandler)
    }
    
    class func requestStatus(read: Set<HKObjectType> = [], write: Set<HKSampleType> = [], completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completionHandler(.failure(DataError.dataNotAvailable))
            return
        }
        
        healthStore.getRequestStatusForAuthorization(toShare: write, read: read) { (status, error) in
            if let error = error {
                Log.debug("request health authorization status error: \(error.localizedDescription)")
            }
            
            if status == .unknown {
                completionHandler(.failure(error ?? DataError.dataNotAvailable))
                return
            }
            
            completionHandler(.success(status == .shouldRequest))
        }
    }
    
    // MARK: - Authorization
    
    class func requestReadingAuthorization(for permissions: Set<HKObjectType>, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        requestHealthAuthorization(read: permissions, write: nil, completionHandler: completionHandler)
    }
    
//    class func requestWritingAuthorization(for permissions: Set<HKSampleType>, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
//        requestHealthAuthorization(read: nil, write: permissions, completionHandler: completionHandler)
//    }
    
    class func requestHealthAuthorization(read: Set<HKObjectType>?, write: Set<HKSampleType>?, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completionHandler(.failure(DataError.dataNotAvailable))
            return
        }
        
        Log.debug("request health authorization")
        healthStore.requestAuthorization(
            toShare: write,
            read: read
        ) { (success, error) in
            guard success else {
                let resultError = error ?? DataError.failed
                Log.debug("authorization error: \(resultError.localizedDescription)")
                completionHandler(.failure(resultError))
                return
            }
            
            Log.debug("health authorization succeeded")
            completionHandler(.success(true))
        }
    }
    
}
