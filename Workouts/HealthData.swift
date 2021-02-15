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
        case unauthorized
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
            return "Data not available"
        case .failed:
            return "Reques failed"
        case .unauthorized:
            return "Unauthorized"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    
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
            HKQuantityType.heartRate(),
            HKQuantityType.weight()
        ]
    }
    
    class func writePermissions() -> Set<HKSampleType> {
        [
            HKSeriesType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType.distanceCycling(),
            HKQuantityType.distanceWalkingRunning(),
            HKQuantityType.activeEnergyBurned(),
            HKQuantityType.heartRate(),
        ]
    }
    
    // MARK: - Request Status
    
    class func requestStatusForReading(completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        requestStatus(read: readPermissions(), completionHandler: completionHandler)
    }
    
//    class func requestStatusForWriting(completionHandler: @escaping (Result<Bool, Error>) -> Void) {
//        requestStatus(read: readPermissions(), write: writePermissions(), completionHandler: completionHandler)
//    }
    
    class func requestStatus(read: Set<HKObjectType> = [], write: Set<HKSampleType> = [], completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completionHandler(.failure(DataError.dataNotAvailable))
            return
        }
        
        Log.debug("requesting permissions for reading")
        healthStore.getRequestStatusForAuthorization(toShare: write, read: read) { (status, error) in
            Log.debug("got status: \(status.rawValue)")
            if let error = error {
                Log.debug("error: \(error.localizedDescription)")
            }
            
            if status == .unknown {
                completionHandler(.failure(error ?? DataError.dataNotAvailable))
                return
            }
            
            completionHandler(.success(status == .shouldRequest))
        }
    }
    
    class func validateWritingStatus() -> HKAuthorizationStatus {
        let permissions = writePermissions()
        
        var notDeterminedResults = [Bool]()
        var deniedResults = [Bool]()
        var authorizedResults = [Bool]()
        
        for object in permissions {
            let status = healthStore.authorizationStatus(for: object)
            switch status {
            case .notDetermined:
                notDeterminedResults.append(true)
            case .sharingDenied:
                deniedResults.append(true)
            case .sharingAuthorized:
                authorizedResults.append(true)
            default:
                break
            }
        }
        
        var resultStatus: HKAuthorizationStatus
        if !notDeterminedResults.isEmpty {
            resultStatus = .notDetermined
        } else if !deniedResults.isEmpty {
            resultStatus = .sharingDenied
        } else {
            resultStatus = .sharingAuthorized
        }
        return resultStatus
    }
    
    // MARK: - Authorization
    
    class func requestReadingAuthorization(completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        requestHealthAuthorization(read: readPermissions(), write: nil, completionHandler: completionHandler)
    }
    
    class func requestWritingAuthorization(completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        requestHealthAuthorization(read: readPermissions(), write: writePermissions(), completionHandler: completionHandler)
    }
    
    private class func requestHealthAuthorization(read: Set<HKObjectType>?, write: Set<HKSampleType>?, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completionHandler(.failure(DataError.dataNotAvailable))
            return
        }
        
        Log.debug("request authorization")
                
        healthStore.requestAuthorization(
            toShare: write,
            read: read
        ) { (success, error) in
            Log.debug("success: \(success)")
            if let error = error {
                Log.debug("error: \(error.localizedDescription)")
            }
            
            guard success else {
                completionHandler(.failure(error ?? DataError.failed))
                return
            }
            
            completionHandler(.success(true))
        }
    }
    
}
