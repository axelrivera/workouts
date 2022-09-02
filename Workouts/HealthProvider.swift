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
    
    func anchorDateAndIntervalComponents(for dateInterval: DateInterval) -> (Date, DateComponents) {
        let queryInterval = intervalFor(start: dateInterval.start, end: dateInterval.end)
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: Date())
        let anchorDate = calendar.date(from: dateComponents)!
        return (anchorDate, queryInterval)
    }
    
    func fetchDistanceSamples(distanceType: HKQuantityType, interval: DateInterval, source: HKSource? = nil) async throws -> [Quantity] {
        let datePredicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        let predicate = HKSamplePredicate.quantitySample(type: distanceType, predicate: datePredicate)
        
        let (anchorDate, queryInterval) = anchorDateAndIntervalComponents(for: interval)
        let query = HKStatisticsCollectionQueryDescriptor(predicate: predicate, options: [.cumulativeSum, .separateBySource], anchorDate: anchorDate, intervalComponents: queryInterval)
        let result = try await query.result(for: healthStore)
        
        let sortedStatistics = result.statistics().sorted(by: { $0.startDate < $1.startDate })
        let values: [Quantity] = sortedStatistics.compactMap { (statistics) in
            guard let quantity = sumQuantity(for: source, statistics: statistics) else { return nil }
            let distance = quantity.doubleValue(for: .meter())
            return Quantity(start: statistics.startDate, end: statistics.endDate, value: distance)
        }
        
        return values
    }
    
    func fetchMaxSamples(quantityType: HKQuantityType, unit: HKUnit, interval: DateInterval, source: HKSource?) async throws -> [Quantity] {
        let datePredicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        let predicate = HKSamplePredicate.quantitySample(type: quantityType, predicate: datePredicate)
        
        let (anchorDate, queryInterval) = anchorDateAndIntervalComponents(for: interval)
        let query = HKStatisticsCollectionQueryDescriptor(predicate: predicate, options: [.discreteMax, .separateBySource], anchorDate: anchorDate, intervalComponents: queryInterval)
        let result = try await query.result(for: healthStore)
        
        let sortedStatistics = result.statistics().sorted(by: { $0.startDate < $1.startDate })
        let values: [Quantity] = sortedStatistics.compactMap { (statistics) in
            guard let quantity = maxQuantity(for: source, statistics: statistics) else { return nil }
            return Quantity(start: statistics.startDate, end: statistics.endDate, value: quantity.doubleValue(for: unit))
        }
        return values
    }
    
    func fetchCyclingCadenceSamples(interval: DateInterval) async throws -> [Quantity] {
        let datePredicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        let cadencePredicate = HKQuery.predicateForObjects(withMetadataKey: MetadataKeySampleCadence)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, cadencePredicate])
        let samplePredicate = HKSamplePredicate.quantitySample(type: HKQuantityType.distanceCycling(), predicate: predicate)
                
        let query = HKSampleQueryDescriptor(predicates: [samplePredicate], sortDescriptors: [SortDescriptor(\.startDate, order: .forward)])
        
        let samples = try await query.result(for: healthStore)
        let cadenceSamples: [Quantity] = samples.compactMap { sample in
            guard let cadence = sample.metadata?[MetadataKeySampleCadence] as? Double else { return nil }
            return Quantity(start: sample.startDate, end: sample.endDate, value: cadence)
        }
        return cadenceSamples
    }
    
    func fetchWorkout(uuid: UUID) async throws -> HKWorkout {
        let predicate = HKQuery.predicateForObject(with: uuid)
        let samplePredicate = HKSamplePredicate.sample(type: .workoutType(), predicate: predicate)
        
        let query = HKSampleQueryDescriptor(predicates: [samplePredicate], sortDescriptors: [])
        let samples = try await query.result(for: healthStore)
        
        if let workout = samples.first as? HKWorkout {
            return workout
        } else {
            throw HealthError.missingData
        }
    }
    
    func fetchWorkouts(for identifiers: [UUID]) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForObjects(with: Set(identifiers))
        let samplePredicate = HKSamplePredicate.sample(type: .workoutType(), predicate: predicate)
        
        let query = HKSampleQueryDescriptor(predicates: [samplePredicate], sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)])
        let samples = try await query.result(for: healthStore)
        
        if let workouts = samples as? [HKWorkout] {
            return workouts
        } else {
            throw HealthError.missingData
        }
    }
    
    func fetchHeartRateSamples(interval: DateInterval, source: HKSource? = nil, stoppedIntervals: [DateInterval] = [DateInterval]()) async throws -> [Quantity] {
        let datePredicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        let predicate = HKSamplePredicate.quantitySample(type: .heartRate(), predicate: datePredicate)
        
        let (anchorDate, queryInterval) = anchorDateAndIntervalComponents(for: interval)
        let query = HKStatisticsCollectionQueryDescriptor(predicate: predicate, options: [.discreteMax, .separateBySource], anchorDate: anchorDate, intervalComponents: queryInterval)
        
        let result = try await query.result(for: healthStore)
        
        let sortedStatistics = result.statistics().sorted(by: { $0.startDate < $1.startDate })
        let values: [Quantity] = sortedStatistics.compactMap { (statistics) in
            let interval = DateInterval(start: statistics.startDate, end: statistics.endDate)
            if stoppedIntervals.isPresent, let _ = stoppedIntervals.first(where: { interval.intersects($0) }) {
                return nil
            }
            
            guard let quantity = maxQuantity(for: source, statistics: statistics) else { return nil }
            return Quantity(start: statistics.startDate, end: statistics.endDate, value: quantity.doubleValue(for: .bpm()))
        }
        return values
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
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        let samplePredicate = HKSamplePredicate.quantitySample(type: .restingHeartRate(), predicate: predicate)
        
        let query = HKStatisticsQueryDescriptor(predicate: samplePredicate, options: [.discreteAverage])
        let statistics = try await query.result(for: healthStore)
        
        if let avg = statistics?.averageQuantity()?.doubleValue(for: .bpm()) {
            return avg
        } else {
            throw HealthError.failure
        }
    }
    
    typealias HeartRateStatsValue = (avg: Double, max: Double)
    
    func fetchHeartRateStats(for workout: HKWorkout) async throws -> (avg: Double, max: Double) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictStartDate, .strictEndDate])
        let samplePredicate = HKSamplePredicate.quantitySample(type: .heartRate(), predicate: predicate)
        
        let query = HKStatisticsQueryDescriptor(predicate: samplePredicate, options: [.discreteAverage, .discreteMax, .separateBySource])
        
        let statistics = try await query.result(for: healthStore)
        
        let avg = statistics?.averageQuantity(for: workout.sourceRevision.source)?.doubleValue(for: .bpm()) ?? 0
        let max = statistics?.maximumQuantity(for: workout.sourceRevision.source)?.doubleValue(for: .bpm()) ?? 0
        
        return (avg, max)
    }
    
    func fetchAvgHeartRate(for workout: HKWorkout) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictStartDate, .strictEndDate])
        let samplePredicate = HKSamplePredicate.quantitySample(type: .heartRate(), predicate: predicate)
        
        let query = HKStatisticsQueryDescriptor(predicate: samplePredicate, options: [.discreteAverage, .separateBySource])
        
        let statistics = try await query.result(for: healthStore)
        
        let avg = statistics?.averageQuantity(for: workout.sourceRevision.source)?.doubleValue(for: .bpm()) ?? 0
        return avg
    }
    
    func fetchActiveEnergy(for workout: HKWorkout) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictEndDate, .strictEndDate])
        let samplePredicate = HKSamplePredicate.quantitySample(type: .activeEnergyBurned(), predicate: predicate)
        
        let query = HKStatisticsQueryDescriptor(predicate: samplePredicate, options: [.cumulativeSum, .separateBySource])
        let statistics = try await query.result(for: healthStore)
        
        if let sum = statistics?.sumQuantity(for: workout.sourceRevision.source)?.doubleValue(for: .largeCalorie()) {
            return sum
        } else {
            throw HealthError.failure
        }
    }
    
    func fetchRoute(for workout: HKWorkout) async throws -> [HKWorkoutRoute] {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let samplePredicate = HKSamplePredicate.sample(type: HKSeriesType.workoutRoute(), predicate: predicate)
        
        let query = HKSampleQueryDescriptor(predicates: [samplePredicate], sortDescriptors: [SortDescriptor(\.startDate, order: .forward)])
        let samples = try await query.result(for: healthStore)
        
        if let routes = samples as? [HKWorkoutRoute] {
            return routes
        } else {
            throw HealthError.failure
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
        let query = HKWorkoutRouteQueryDescriptor(route)
        
        let locations = query.results(for: healthStore)
        
        var allLocations = [CLLocation]()
        for try await location in locations {
            allLocations.append(location)
        }
        
        return allLocations
    }
    
    func totalWorkouts() async throws -> Int {
        let predicate = defaultActivitiesPredicate()
        let samplePredicate = HKSamplePredicate.sample(type: .workoutType(), predicate: predicate)
        
        let query = HKSampleQueryDescriptor(predicates: [samplePredicate], sortDescriptors: [])
        let samples = try await query.result(for: healthStore)
        return samples.count
    }
    
}

// MARK: - Helper Methods

extension HealthProvider {
    
    func defaultActivitiesPredicate() -> NSPredicate {
        predicateForActivities(HKWorkoutActivityType.availableActivityTypes)
    }
    
    func predicateForActivities(_ activities: [HKWorkoutActivityType]) -> NSPredicate {
        if activities.isEmpty { fatalError("activities cannot be empty") }
        let predicates = activities.map({ HKQuery.predicateForWorkouts(with: $0) })
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
    
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
