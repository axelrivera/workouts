//
//  ProfileDataStore.swift
//  Workouts
//
//  Created by Axel Rivera on 2/10/21.
//

import HealthKit

struct ProfileDataStore {
    enum DataError: Error {
        case failure
    }
    
    static let healthStore = HealthData.shared.healthStore
    
    static func fetchWeightInKilograms(completionHandler: @escaping (Double?) -> Void) {
        fetchMostRecentSample(for: .weight()) { result in
            do {
                let sample = try result.get()
                let value = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                completionHandler(value)
            } catch {
                completionHandler(nil)
            }
        }
    }
    
    static func fetchMostRecentSample(for quantityType: HKQuantityType, completion: @escaping (Result<HKQuantitySample, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.failure(DataError.failure))
            return
        }
        
        let mostRecentPredicate = HKQuery.predicateForSamples(
            withStart: Date.distantPast,
            end: Date(),
            options: .strictEndDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let sampleQuery = HKSampleQuery(
            sampleType: quantityType,
            predicate: mostRecentPredicate,
            limit: 1,
            sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            DispatchQueue.main.async {
                guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                    completion(.failure(error ?? DataError.failure))
                    return
                }
                completion(.success(sample))
            }
        }
        healthStore.execute(sampleQuery)
    }
    
    static func saveWeight(_ weight: Double, for date : Date, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        let quantity = HKQuantity.init(unit: .gramUnit(with: .kilo), doubleValue: weight)
        let sample = HKQuantitySample(
            type: .weight(),
            quantity: quantity,
            start: date,
            end: date
        )
        
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                if success {
                    completionHandler(.success(true))
                } else {
                    completionHandler(.failure(error ?? DataError.failure))
                }
            }
        }
    }
    
}

