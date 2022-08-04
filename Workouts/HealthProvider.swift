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
    
    private var supportsMaxHeartRate: Bool {
        maxHeartRate() > 0
    }
    
    private var supportsRestingHeartRate: Bool {
        if AppSettings.useHealthRestingHeartRate {
            return true
        } else {
            return AppSettings.restingHeartRate > 0
        }
    }
    
    private var supportsGender: Bool {
        userGender().isAvailable
    }
    
    var isTrainingLoadSupported: Bool {
        supportsGender && supportsMaxHeartRate && supportsRestingHeartRate
    }
    
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
    
    func fetchWorkouts(for identifiers: [UUID]) async throws -> [HKWorkout] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchWorkouts(for: identifiers) { result in
                switch result {
                case .success(let workouts):
                    continuation.resume(returning: workouts)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchHeartRateSamples(interval: DateInterval, source: HKSource? = nil, stoppedIntervals: [DateInterval] = [DateInterval]()) async throws -> [Quantity] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchHeartRateSamples(interval: interval, source: source, stoppedIntervals: stoppedIntervals) { result in
                switch result {
                case .success(let samples):
                    continuation.resume(returning: samples)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchPaddedHeartRateSamples(for workout: HKWorkout) async throws -> [Quantity] {
        let interval = DateInterval(start: workout.startDate, end: workout.endDate)
        return try await fetchPaddedHeartRateSamples(
            interval: interval,
            source: workout.sourceRevision.source,
            stoppedIntervals: workout.stoppedIntervals()
        )
    }
    
    func fetchPaddedHeartRateSamples(interval: DateInterval, source: HKSource? = nil, stoppedIntervals: [DateInterval] = [DateInterval]()) async throws -> [Quantity] {
        let samples = try await fetchHeartRateSamples(interval: interval, source: source, stoppedIntervals: stoppedIntervals)
                        
        let startIndex = KeyForTimestamp(interval.start)
        let endIndex = KeyForTimestamp(interval.end)
        
        var dictionary = [Int: Quantity]()
        for key in startIndex ... endIndex {
            let timestamp = Date(timeIntervalSince1970: Double(key))
            if stoppedIntervals.isPresent, let _ = stoppedIntervals.first(where: { $0.contains(timestamp) }) {
                continue
            }
            
            dictionary[key] = Quantity(start: timestamp, end: timestamp, value: 0)
        }
        
        for sample in samples {
            let key = KeyForTimestamp(sample.timestamp)
            guard let quantity = dictionary[key] else { continue }
            
            if sample.value > quantity.value {
                let timestamp = Date(timeIntervalSince1970: Double(key))
                dictionary[key] = Quantity(start: timestamp, end: timestamp, value: sample.value)
            }
        }
        
        // padding
        let quantities = dictionary.values.sorted(by: { $0.timestamp < $1.timestamp })
        
        var currentValue: Double = quantities.first(where: { $0.value > 0 })?.value ?? 0
        var paddedQuantities = [Quantity]()
        
        for quantity in quantities {
            if quantity.value == 0 && currentValue > 0 {
                let newQuantity = Quantity(start: quantity.start, end: quantity.end, value: currentValue)
                paddedQuantities.append(newQuantity)
            } else {
                paddedQuantities.append(quantity)
            }
            
            if quantity.value > 0 {
                currentValue = quantity.value
            }
        }
        
        return paddedQuantities
    }
    
    func fetchRecentRestingHeartRate() async -> Int? {
        do {
            let interval = DateInterval.lastThirtyDays()
            let value = try await fetchRestingHeartRate(for: interval)
            return Int(value)
        } catch {
            Log.debug("failed to fetch resting heart rate")
            return nil
        }
    }
    
    func fetchRestingHeartRate(for interval: DateInterval) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            fetchRestingHeartRate(for: interval) { result in
                switch result {
                case .success(let avg):
                    continuation.resume(returning: avg)
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
    
    func fetchAvgHeartRate(for workout: HKWorkout) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            fetchAvgHeartRate(workout: workout) { result in
                switch result {
                case .success(let avg):
                    continuation.resume(returning: avg)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchActiveEnergy(for workout: HKWorkout) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            fetchActiveEnergy(workout: workout) { result in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
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
    
    private func fetchWorkouts(for identifiers: [UUID], completionHandler: @escaping (Result<[HKWorkout], Error>) -> Void) {
        let predicate = HKQuery.predicateForObjects(with: Set(identifiers))
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortByDate]
        ) { (query, samples, error) in
            if let workouts = samples as? [HKWorkout] {
                completionHandler(.success(workouts))
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
    
    private func fetchHeartRateSamples(
        interval: DateInterval,
        source: HKSource? = nil,
        stoppedIntervals: [DateInterval] = [DateInterval](),
        completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
            
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
                let interval = DateInterval(start: statistics.startDate, end: statistics.endDate)
                if stoppedIntervals.isPresent, let _ = stoppedIntervals.first(where: { interval.intersects($0) }) {
                    return nil
                }
                
                guard let quantity = maxQuantity(for: source, statistics: statistics) else { return nil }
                return Quantity(start: statistics.startDate, end: statistics.endDate, value: quantity.doubleValue(for: .bpm()))
            }
            completionHandler(.success(values))
        }
        healthStore.execute(query)
    }
    
    typealias HeartRateStatsValue = (avg: Double, max: Double)
    
    private func fetchAvgHeartRate(workout: HKWorkout, completionHandler: @escaping (Result<Double, Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictStartDate, .strictEndDate])
        let source = workout.sourceRevision.source
                
        let query = HKStatisticsQuery(
            quantityType: .heartRate(),
            quantitySamplePredicate: predicate,
            options: [.discreteAverage, .separateBySource]) { (query, statistics, error) in
                self.healthStore.stop(query)
                
                guard let statistics = statistics else {
                    completionHandler(.failure(error ?? HealthError.failure))
                    return
                }
                
                let avg = statistics.averageQuantity(for: source)?.doubleValue(for: HKUnit.bpm()) ?? 0
                completionHandler(.success(avg))
        }
        healthStore.execute(query)
    }
    
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
    
    private func fetchRestingHeartRate(for interval: DateInterval, completionHandler: @escaping (Result<Double, Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        
        let query = HKStatisticsQuery(
            quantityType: .restingHeartRate(),
            quantitySamplePredicate: predicate,
            options: [.discreteAverage]) { query, statistics, error in
                self.healthStore.stop(query)
                
                guard let statistics = statistics else {
                    completionHandler(.failure(error ?? HealthError.failure))
                    return
                }
                
                guard let avg = statistics.averageQuantity()?.doubleValue(for: .bpm()) else {
                    completionHandler(.failure(HealthError.failure))
                    return
                }
                
                completionHandler(.success(avg))
        }
        healthStore.execute(query)
    }
    
    private func fetchHeartRateDuration(completionHandler: @escaping (Result<[HeartRateDuration], Error>) -> Void) {
        let calendar = Calendar.current
        
        // Create a 1-second interval.
        let interval = DateComponents(second: 1)
        
        guard let anchorDate = calendar.date(bySetting: .minute, value: 1, of: Date()) else {
            completionHandler(.failure(HealthError.failure))
            return
        }
        
        let query = HKStatisticsCollectionQuery(
            quantityType: .heartRate(),
            quantitySamplePredicate: nil,
            options: .discreteMax,
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { (query, results, error) in
            self.healthStore.stop(query)
            
            guard let results = results else {
                completionHandler(.failure(error ?? HealthError.failure))
                return
            }
            
            var dictionary = [Int: Int]()
            let statistics = results.statistics()
            
            for statistic in statistics {
                guard let doubleValue = statistic.maximumQuantity()?.doubleValue(for: .bpm()) else {
                    continue
                }
                
                let intValue = Int(doubleValue)
                if let currentValue = dictionary[intValue] {
                    dictionary[intValue] = currentValue + 1
                } else {
                    dictionary[intValue] = 1
                }
            }
            
            let values = dictionary.keys.sorted().map { key in
                HeartRateDuration(value: Double(key), duration: dictionary[key]!)
            }
            
            completionHandler(.success(values))
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveEnergy(workout: HKWorkout, completionHandler: @escaping (Result<Double, Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictEndDate, .strictEndDate])
        let source = workout.sourceRevision.source
        
        Log.debug("fetching energy for start: \(workout.startDate), end: \(workout.endDate), source: \(source.name)")
        
        
        let query = HKStatisticsQuery(
            quantityType: .activeEnergyBurned(),
            quantitySamplePredicate: predicate,
            options: [.cumulativeSum, .separateBySource]) { (query, statistics, error) in
            self.healthStore.stop(query)
            
            guard let statistics = statistics else {
                completionHandler(.failure(error ?? HealthError.failure))
                return
            }
                
            let sum = statistics.sumQuantity(for: source)?.doubleValue(for: HKUnit.largeCalorie()) ?? 0
            completionHandler(.success(sum))
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
