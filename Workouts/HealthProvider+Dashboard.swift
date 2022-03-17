//
//  HealthProvider+Dashboard.swift
//  Workouts
//
//  Created by Axel Rivera on 3/5/22.
//

import Foundation
import HealthKit

extension HealthProvider {
    
    // MARK: Meteric Sum
    
    func fetchSum(for quantityType: HKQuantityType, unit: HKUnit, interval: DateInterval) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            fetchSum(for: quantityType, unit: unit, interval: interval) { result in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func fetchSum(for quantityType: HKQuantityType, unit: HKUnit, interval: DateInterval, completionHandler: @escaping (Result<Double, Error>) -> Void) {
        let query = HKStatisticsQuery(
            quantityType: quantityType,
            quantitySamplePredicate: Self.predicateForInterval(interval),
            options: .cumulativeSum) { query, statistics, error in
                guard let statistics = statistics else {
                    completionHandler(.failure(error ?? HealthError.failure))
                    return
                }
                
                let value = statistics.sumQuantity()?.doubleValue(for: unit) ?? 0
                completionHandler(.success(value))
            }
        healthStore.execute(query)
    }
    
    // MARK: - Workout Data
    
    struct WorkoutData {
        let total: Int
        let duration: Double
        let activities: [HKWorkoutActivityType]
    }
        
    func fetchWorkoutData(for interval: DateInterval) async throws -> WorkoutData {
        try await withCheckedThrowingContinuation { continuation in
            fetchWorkoutData(for: interval) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
                
            }
        }
    }
    
    private func fetchWorkoutData(for interval: DateInterval, completionHandler: @escaping (Result<WorkoutData, Error>) -> Void) {
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: Self.predicateForInterval(interval),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { query, samples, error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            
            let samples = samples as? [HKWorkout] ?? [HKWorkout]()
            let total = samples.count
            let duration = samples.reduce(0) { partialResult, workout in
                partialResult + workout.duration
            }
            
            let activitySet: Set<HKWorkoutActivityType> = Set(samples.map({ $0.workoutActivityType }))
            let data = WorkoutData(total: total, duration: duration, activities: Array(activitySet))
            
            completionHandler(.success(data))
        }
        healthStore.execute(query)
    }
    
    // MARK: Workout Details
    
    struct ActivityTypeData {
        let total: Int
        let distance: Double
        let duration: Double
        let calories: Double
    }
    
    func fetchActivityType(for activity: HKWorkoutActivityType, interval: DateInterval) async throws -> ActivityTypeData {
        try await withCheckedThrowingContinuation { continuation in
            fetchActivityTypeData(for: activity, interval: interval) { result in
                switch result {
                case .success(let data):
                    return continuation.resume(returning: data)
                case .failure(let error):
                    return continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func fetchActivityTypeData(for activity: HKWorkoutActivityType, interval: DateInterval, completionHandler: @escaping (Result<ActivityTypeData, Error>) -> Void) {
        let activityPredicate = HKQuery.predicateForWorkouts(with: activity)
        let datePredicate = Self.predicateForInterval(interval)
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            activityPredicate,
            datePredicate
        ])
        
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { query, samples, error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            
            let workouts = samples as? [HKWorkout] ?? [HKWorkout]()
            
            let total = workouts.count
            var distance: Double = 0
            var duration: Double = 0
            var calories: Double = 0
            
            for workout in workouts {
                distance += workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                duration += workout.duration
                calories += workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
            }
            
            let data = ActivityTypeData(total: total, distance: distance, duration: duration, calories: calories)
            completionHandler(.success(data))
        }
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Data Starting Date
    
    func fetchStartDate() async throws -> Date {
        try await withCheckedThrowingContinuation { continuation in
            fetchDataStartDate { result in
                switch result {
                case .success(let date):
                    continuation.resume(returning: date)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func fetchDataStartDate(completionHandler: @escaping (Result<Date, Error>) -> Void) {
        let calendar = Calendar.current
        
        // Create a 1-week interval.
        let interval = DateComponents(day: 7)
        
        // Set the anchor for 3 a.m. on Monday.
        let components = DateComponents(calendar: calendar,
                                        timeZone: calendar.timeZone,
                                        hour: 3,
                                        minute: 0,
                                        second: 0,
                                        weekday: 2)

        guard let anchorDate = calendar.nextDate(after: Date(),
                                                 matching: components,
                                                 matchingPolicy: .nextTime,
                                                 repeatedTimePolicy: .first,
                                                 direction: .backward) else {
            completionHandler(.failure(HealthError.missingData))
            return
        }
        
        let query = HKStatisticsCollectionQuery(
            quantityType: .activeEnergyBurned(),
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { (query, results, error) in
            self.healthStore.stop(query)
            
            guard let results = results else {
                completionHandler(.failure(error ?? HealthError.failure))
                return
            }
            
            let sortedStatistics = results.statistics().sorted(by: { $0.startDate < $1.startDate })
            if let date = sortedStatistics.first?.startDate {
                completionHandler(.success(date))
            } else {
                completionHandler(.failure(HealthError.failure))
            }
        }
        
        healthStore.execute(query)
    }
    
    // Helper Methods
    
    static func predicateForInterval(_ interval: DateInterval) -> NSPredicate {
        HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [])
    }
    
}
