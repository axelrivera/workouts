//
//  HealthSamplesProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 8/9/21.
//

import HealthKit

enum HealthError: Error {
    case missingData
    case missingValue
    case failure
    case sportNotSupported
    case system(Error)
}

struct HealthSamplesProvider {
    static let shared = HealthSamplesProvider()
    private let healthStore = HealthData.shared.healthStore
    
    private init() {
        // no-op
    }
    
    private func intervalFor(start: Date, end: Date) -> DateComponents {
        var interval = DateComponents()
        interval.second = 1
        return interval
    }
    
    func fetchHeartRateSamples(interval: DateInterval, source: HKSource?, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
        //fetchSamples(quantityType: .heartRate(), unit: .bpm(), interval: interval, source: source, completionHandler: completionHandler)
    }
    
    func fetchWalkingRunningDistanceSamples(interval: DateInterval, source: HKSource?, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
        //fetchSamples(quantityType: .distanceWalkingRunning(), unit: .meter(), interval: interval, source: source, completionHandler: completionHandler)
    }
    
    func fetchCyclingSitanceSamples(interval: DateInterval, source: HKSource?, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
        //fetchSamples(quantityType: .distanceCycling(), unit: .meter(), interval: interval, source: source, completionHandler: completionHandler)
    }
    
    func fetchMaxSamples(quantityType: HKQuantityType, unit: HKUnit, interval: DateInterval, source: HKSource?, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        let queryInterval = intervalFor(start: interval.start, end: interval.end)
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: Date())
        let anchorDate = calendar.date(from: dateComponents)!
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: [.discreteMax, .separateBySource],
            anchorDate: anchorDate,
            intervalComponents: queryInterval
        )
        
        query.initialResultsHandler = { (query, results, error) in
            self.healthStore.stop(query)
            
            guard let results = results else {
                completionHandler(.failure(error ?? HealthError.failure))
                return
            }
            
            let sortedStatistics = results.statistics().sorted(by: { $0.startDate < $1.startDate })
            let values: [Quantity] = sortedStatistics.compactMap { (statistics) in
                guard let quantity = maxQuantity(for: source, statistics: statistics) else { return nil }
                return Quantity(start: statistics.startDate, end: statistics.endDate, value: quantity.doubleValue(for: unit))
            }
            completionHandler(.success(values))
        }
        healthStore.execute(query)
    }
    
    func fetchDistanceSamples(distanceType: HKQuantityType, unit: HKUnit, interval: DateInterval, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        let dateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(
            sampleType: distanceType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [dateSort]) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample] else {
                completionHandler(.failure(HealthError.missingData))
                return
            }
            
            let values = samples.compactMap { sample in
                return Quantity(start: sample.startDate, end: sample.endDate, value: sample.quantity.doubleValue(for: unit))
            }
            completionHandler(.success(values))
            
        }
        healthStore.execute(query)
    }
    
}

extension HealthSamplesProvider {
    
    private func maxQuantity(for source: HKSource?, statistics: HKStatistics) -> HKQuantity? {
        if let source = source {
            return statistics.maximumQuantity(for: source)
        } else {
            return statistics.maximumQuantity()
        }
    }
    
}
