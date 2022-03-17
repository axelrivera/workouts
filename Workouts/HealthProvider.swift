//
//  HealthProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 8/9/21.
//

import HealthKit
import CoreLocation

enum HealthError: Error {
    case missingData
    case missingValue
    case failure
    case sportNotSupported
    case system(Error)
}

struct HealthProvider {
    static let shared = HealthProvider()
    
    let healthStore = HKHealthStore()
    
    private init() {
        // no-op
    }
    
    let isAvailable = HKHealthStore.isHealthDataAvailable()
}

// MARK: - Async/Await Methods

extension HealthProvider {
    
    func fetchDistanceSamples(distanceType: HKQuantityType, interval: DateInterval, source: HKSource) async throws -> [Quantity] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchDistanceSamples(distanceType: distanceType, interval: interval, source: source) { result in
                switch result {
                case .success(let samples):
                    continuation.resume(returning: samples)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchMaxSamples(quantityType: HKQuantityType, unit: HKUnit, interval: DateInterval, source: HKSource?) async throws -> [Quantity] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchMaxSamples(quantityType: quantityType, unit: unit, interval: interval, source: source) { result in
                switch result {
                case .success(let samples):
                    continuation.resume(returning: samples)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchCyclingCadenceSamples(interval: DateInterval) async throws -> [Quantity] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchCyclingCadenceSamples(interval: interval) { result in
                switch result {
                case .success(let samples):
                    continuation.resume(returning: samples)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchWorkout(uuid: UUID) async throws -> HKWorkout {
        return try await withCheckedThrowingContinuation { continuation in
            fetchWorkout(uuid: uuid) { result in
                switch result {
                case .success(let workout):
                    continuation.resume(returning: workout)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchHeartRateSamples(interval: DateInterval, source: HKSource?) async throws -> [Quantity] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchHeartRateSamples(interval: interval, source: source) { result in
                switch result {
                case .success(let samples):
                    continuation.resume(returning: samples)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchHeartRateStats(for workout: HKWorkout) async throws -> (avg: Double, max: Double) {
        return try await withCheckedThrowingContinuation { continuation in
            fetchHeartRateStatsValue(workout: workout) { result in
                switch result {
                case .success(let stats):
                    continuation.resume(returning: stats)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchRoute(for workout: HKWorkout) async throws -> [HKWorkoutRoute] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchRoute(for: workout) { result in
                switch result {
                case .success(let routes):
                    return continuation.resume(returning: routes)
                case .failure(let error):
                    return continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchLocations(for workout: HKWorkout) async throws -> [CLLocation] {
        let samples = try await fetchRoute(for: workout)
        
        var allLocations = [CLLocation]()
        for route in samples {
            let locations = try await fetchLocations(for: route)
            allLocations.append(contentsOf: locations)
        }
        return allLocations
    }
    
    func fetchLocations(for route: HKWorkoutRoute) async throws -> [CLLocation] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchLocations(route: route) { result in
                switch result {
                case .success(let locations):
                    return continuation.resume(returning: locations)
                case .failure(let error):
                    return continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func totalWorkouts() async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            fetchTotalWorkouts { result in
                switch result {
                case .success(let total):
                    continuation.resume(returning: total)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
}

// MARK: - Workouts

extension HealthProvider {
    
    func defaultActivitiesPredicate() -> NSPredicate {
        predicateForActivities(HKWorkoutActivityType.availableActivityTypes)
    }
    
    func predicateForActivities(_ activities: [HKWorkoutActivityType]) -> NSPredicate {
        if activities.isEmpty { fatalError("activities cannot be empty") }
        let predicates = activities.map({ HKQuery.predicateForWorkouts(with: $0) })
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
    
    private func fetchWorkout(uuid: UUID, completionHandler: @escaping (Result<HKWorkout, Error>) -> Void) {
        let predicate = HKQuery.predicateForObject(with: uuid)
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 1, sortDescriptors: nil) { (query, samples, error) in
            if let workout = samples?.first as? HKWorkout {
                completionHandler(.success(workout))
            } else {
                completionHandler(.failure(error ?? HealthError.missingData))
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchTotalWorkouts(completionHandler: @escaping (Result<Int, Error>) -> Void) {
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: defaultActivitiesPredicate(),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil) { (query, samples, error) in
            if let error = error {
                Log.debug("total workouts failed: \(error.localizedDescription)")
                completionHandler(.failure(error))
                return
            }
            
            let samples = samples as? [HKWorkout] ?? [HKWorkout]()
            completionHandler(.success(samples.count))
        }
        
        healthStore.execute(query)
    }
    
    // MARK: Routes
    
    private func fetchRoute(for workout: HKWorkout, completionHandler: @escaping (Result<[HKWorkoutRoute], Error>) -> Void) {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKSampleQuery(
            sampleType: HKSeriesType.workoutRoute(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil) { query, samples, error in
                guard let samples = samples as? [HKWorkoutRoute] else {
                    completionHandler(.failure(error ?? HealthError.failure))
                    return
                }
                
                completionHandler(.success(samples))
            }
        healthStore.execute(query)
    }
    
    private func fetchLocations(route: HKWorkoutRoute, completionHandler: @escaping (Result<[CLLocation], Error>) -> Void) {
        var allLocations = [CLLocation]()
        
        let locationQuery = HKWorkoutRouteQuery(route: route) { locationQuery, locations, done, error in
            if let error = error {
                healthStore.stop(locationQuery)
                completionHandler(.failure(error))
                return
            }
            
            let locations = locations ?? []
            for location in locations {
                allLocations.append(location)
            }
            
            if done {
                healthStore.stop(locationQuery)
                completionHandler(.success(allLocations))
            }
        }
        healthStore.execute(locationQuery)
    }
    
}

// MARK: - Samples

extension HealthProvider {
    
    private func fetchDistanceSamples(distanceType: HKQuantityType, interval: DateInterval, source: HKSource?, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        
        let queryInterval = intervalFor(start: interval.start, end: interval.end)
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: Date())
        let anchorDate = calendar.date(from: dateComponents)!
        
        let query = HKStatisticsCollectionQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: [.cumulativeSum, .separateBySource],
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
                guard let quantity = sumQuantity(for: source, statistics: statistics) else { return nil }
                let distance = quantity.doubleValue(for: .meter())
                return Quantity(start: statistics.startDate, end: statistics.endDate, value: distance)
            }
            completionHandler(.success(values))
        }
        healthStore.execute(query)
    }
    
    private func fetchMaxSamples(quantityType: HKQuantityType, unit: HKUnit, interval: DateInterval, source: HKSource?, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
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
    
    private func fetchCyclingCadenceSamples(interval: DateInterval, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
        let datePredicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        let cadencePredicate = HKQuery.predicateForObjects(withMetadataKey: MetadataKeySampleCadence)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, cadencePredicate])
        
        let dateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(
            sampleType: HKQuantityType.distanceCycling(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [dateSort]) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample] else {
                completionHandler(.failure(HealthError.failure))
                return
            }
            
            let cadenceSamples: [Quantity] = samples.compactMap { sample in
                guard let cadence = sample.metadata?[MetadataKeySampleCadence] as? Double else { return nil }
                return Quantity(start: sample.startDate, end: sample.endDate, value: cadence)
            }
            completionHandler(.success(cadenceSamples))
            
        }
        healthStore.execute(query)
    }
    
    private func fetchHeartRateSamples(interval: DateInterval, source: HKSource?, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
        let intervalPredicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        let queryInterval = intervalFor(start: interval.start, end: interval.end)
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: Date())
        let anchorDate = calendar.date(from: dateComponents)!
        
        let query = HKStatisticsCollectionQuery(
            quantityType: .heartRate(),
            quantitySamplePredicate: intervalPredicate,
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
                return Quantity(start: statistics.startDate, end: statistics.endDate, value: quantity.doubleValue(for: .bpm()))
            }
            completionHandler(.success(values))
        }
        healthStore.execute(query)
    }
    
    typealias HeartRateStatsValue = (avg: Double, max: Double)
    
    private func fetchHeartRateStatsValue(workout: HKWorkout, completionHandler: @escaping (Result<HeartRateStatsValue, Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictStartDate, .strictEndDate])
        let source = workout.sourceRevision.source
        
        let query = HKStatisticsQuery(
            quantityType: .heartRate(),
            quantitySamplePredicate: predicate,
            options: [.discreteAverage, .discreteMax, .separateBySource]) { (query, statistics, error) in
            self.healthStore.stop(query)
            
            guard let statistics = statistics else {
                completionHandler(.failure(error ?? HealthError.failure))
                return
            }
            
            let avg = statistics.averageQuantity(for: source)?.doubleValue(for: HKUnit.bpm()) ?? 0
            let max = statistics.maximumQuantity(for: source)?.doubleValue(for: HKUnit.bpm()) ?? 0
            
            completionHandler(.success((avg, max)))
        }
        healthStore.execute(query)
    }
    
    // MARK: Helper Methods
    
    private func intervalFor(start: Date, end: Date) -> DateComponents {
        var interval = DateComponents()
        interval.second = 1
        return interval
    }
    
    private func maxQuantity(for source: HKSource?, statistics: HKStatistics) -> HKQuantity? {
        if let source = source {
            return statistics.maximumQuantity(for: source)
        } else {
            return statistics.maximumQuantity()
        }
    }
    
    private func sumQuantity(for source: HKSource?, statistics: HKStatistics) -> HKQuantity? {
        if let source = source {
            return statistics.sumQuantity(for: source)
        } else {
            return statistics.sumQuantity()
        }
    }
 
}
