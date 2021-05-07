//
//  StatsProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 2/17/21.
//

import HealthKit
import Combine

struct StatsProvider {
    
    enum DataError: Error {
        case failure
    }
}

// MARK: - HKQuery

extension StatsProvider {
    
    static func fetchStatsSummary(sport: Sport, timeframe: StatsSummary.Timeframe) -> AnyPublisher<StatsSummary, Error> {
        var activityType: HKWorkoutActivityType
        switch sport {
        case .cycling:
            activityType = .cycling
        case .running:
            activityType = .running
        case .walking:
            activityType = .walking
        default:
            fatalError("invalid workout type")
        }
        
        let (start, end) = timeframe.interval
        
        let sportPredicate = HKQuery.predicateForWorkouts(with: activityType)
        let datePredicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: [.strictStartDate, .strictEndDate]
        )
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sportPredicate, datePredicate])
        
        return runSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        )
        .compactMap { samples in
            samples as? [HKWorkout]
        }
        .map { workouts in
            let count = workouts.count
            var distance: Double = 0
            var duration: Double = 0
            var elevation: Double = 0
            var energyBurned: Double = 0
            
            for workout in workouts {
                distance += workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                duration += workout.duration
                energyBurned += workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                
                let workoutElevation = workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity
                elevation += workoutElevation?.doubleValue(for: .meter()) ?? 0
            }
            
            let longestDistance: Double = workouts.compactMap { (workout) -> Double in
                workout.totalDistance?.doubleValue(for: .meter()) ?? 0
            }.max() ?? 0
            
            let highestElevation = workouts.compactMap { workout -> Double in
                let workoutElevation = workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity
                return workoutElevation?.doubleValue(for: .meter()) ?? 0
            }.max() ?? 0
            
            var summary = StatsSummary(sport: sport, timeframe: timeframe)
            summary.count = count
            summary.distance = distance
            summary.duration = duration
            summary.elevation = elevation
            summary.energyBurned = energyBurned
            summary.longestDistance = longestDistance
            summary.highestElevation = highestElevation
            return summary
        }
        .eraseToAnyPublisher()
    }
    
    static func runSampleQuery(sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?) -> Publishers.SampleQueryPublisher {
        Publishers.SampleQueryPublisher(
            sampleType: sampleType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: sortDescriptors
        )
    }
    
}

// MARK: - HKStatisticsQuery

extension StatsProvider {
    
    static func fetchTotalDistance(quantityType: HKQuantityType, start: Date, end: Date) -> AnyPublisher<Double, Error> {
        switch quantityType {
        case .distanceCycling():
            return fetchTotalCyclingDistance(start: start, end: end)
        default:
            return fetchTotalRunningWalkingDistance(start: start, end: end)
        }
    }
    
    static func fetchTotalCyclingDistance(start: Date, end: Date) -> AnyPublisher<Double, Error> {
        fetchSumValue(quantityType: .distanceCycling(), unit: .meter(), start: start, end: end)
    }
    
    static func fetchTotalRunningWalkingDistance(start: Date, end: Date) -> AnyPublisher<Double, Error> {
        fetchSumValue(quantityType: .distanceWalkingRunning(), unit: .meter(), start: start, end: end)
    }
    
    static func fetchTotalEnergyBurned(quan start: Date, end: Date) -> AnyPublisher<Double, Error> {
        fetchSumValue(quantityType: .activeEnergyBurned(), unit: .kilocalorie(), start: start, end: end)
    }
    
    static func fetchSumValue(quantityType: HKQuantityType, unit: HKUnit, start: Date, end: Date, predicate: NSPredicate? = nil) -> AnyPublisher<Double, Error> {
        runStatisticsQuery(quantityType: quantityType, options: .cumulativeSum, start: start, end: end, predicate: predicate)
            .tryMap { statistics in
                if let value = statistics.sumQuantity()?.doubleValue(for: unit) {
                    return value
                } else {
                    throw DataError.failure
                }
            }
            .eraseToAnyPublisher()
    }
    
    static func runStatisticsQuery(quantityType: HKQuantityType, options: HKStatisticsOptions, start: Date, end: Date, predicate: NSPredicate? = nil) -> Publishers.StatisticsPublisher {
        Publishers.StatisticsPublisher(quantityType: quantityType, options: options, predicate: predicate, start: start, end: end)
    }
    
}
