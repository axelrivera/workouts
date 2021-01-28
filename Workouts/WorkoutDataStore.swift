//
//  WorkoutDataStore.swift
//  Workouts
//
//  Created by Axel Rivera on 12/21/20.
//

import HealthKit
import CoreLocation
import Combine

struct WorkoutDataStore {
    enum DataError: Error {
        case missingData
        case missingValue
        case failure
        case system(Error)
    }
    
    static let healthStore = HealthData.healthStore
    
    static func dataError(_ error: DataError, system: Error?) -> DataError {
        if let systemError = system {
            return .system(systemError)
        }
        return error
    }
    
    static func predicateForActivities(_ activities: [HKWorkoutActivityType]) -> NSPredicate {
        if activities.isEmpty { fatalError("activities cannot be empty") }
        let predicates = activities.map({ HKQuery.predicateForWorkouts(with: $0) })
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
    
    static func fetchWorkouts(for activities: [HKWorkoutActivityType], completionHandler: @escaping (Result<[HKWorkout], DataError>) -> Void) {
        let predicate = predicateForActivities(activities)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let samples = samples as? [HKWorkout] else {
                completionHandler(.failure(dataError(.missingData, system: error)))
                return
            }
            
            completionHandler(.success(samples))
        }
        healthStore.execute(query)
    }
    
    static func fetchRoute(for id: UUID, completionHandler: @escaping (Result<[HKWorkoutRoute], DataError>) -> Void) {
        
        Log.debug("fetching route for: \(id)")
        let predicate = HKQuery.predicateForObject(with: id)
        let query = HKAnchoredObjectQuery(
            type: HKSeriesType.workoutRoute(),
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
            healthStore.stop(query)
            
            Log.debug("route finished with count: \(samples?.count ?? -1)")
            
            if let error = error {
                Log.debug("route failed: \(error.localizedDescription)")
            }
            
            guard let samples = samples as? [HKWorkoutRoute] else {
                completionHandler(.failure(dataError(.missingData, system: error)))
                return
            }
            completionHandler(.success(samples))
        }

//        query.updateHandler = { (query, samples, deleted, anchor, error) in
//
//        }
        
        healthStore.execute(query)
    }
    
    static func fetchLocation(for route: HKWorkoutRoute, updateHandler: @escaping ([CLLocation]) -> Void, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        let store = HKHealthStore()
        
        let query = HKWorkoutRouteQuery(route: route) { (query, locations, done, error) in
            DispatchQueue.main.async {
                guard let locations = locations else {
                    completionHandler(.failure(error ?? DataError.missingData))
                    return
                }
                
                updateHandler(locations)
                
                if done {
                    completionHandler(.success(true))
                    store.stop(query)
                }
            }
        }
        healthStore.execute(query)
    }
    
}

// MARK: - Write Workouts

extension WorkoutDataStore {
    
    static func saveWorkoutImport(_ workoutImport: WorkoutImport, completionHandler: @escaping (Result<Bool, DataError>) -> Void) {
        Log.debug("start: \(workoutImport.startDate?.debugDescription ?? "n/a"), end: \(workoutImport.endDate?.debugDescription ?? "n/a")")
        guard let start = workoutImport.startDate, let end = workoutImport.endDate else {
            fatalError("missing dates")
        }
        
        // TODO: Add Support for Activity Type
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor
        configuration.lapLength = HKQuantity(unit: .mile(), doubleValue: 1.0)
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: .local())
        
        builder.beginCollection(withStart: start) { (success, error) in
            guard success else {
                Log.debug("begin collection failed: \(error?.localizedDescription ?? "n/a")")
                completionHandler(.failure(dataError(.failure, system: error)))
                return
            }
        }
        
        let samples = self.samples(for: workoutImport.intervals)
        builder.add(samples) { (success, error) in
            guard success else {
                Log.debug("samples failed: \(error?.localizedDescription ?? "n/a")")
                completionHandler(.failure(dataError(.failure, system: error)))
                return
            }
                        
            builder.endCollection(withEnd: end) { (success, error) in
                guard success else {
                    Log.debug("end collection failed: \(error?.localizedDescription ?? "n/a")")
                    completionHandler(.failure(dataError(.failure, system: error)))
                    return
                }
                
                builder.addMetadata(metadata(for: workoutImport)) { (success, error) in
                    if let error = error {
                        Log.debug("failed to save metadata: \(error.localizedDescription)")
                    }
                }
                
                let locations = workoutImport.locations
                Log.debug("adding \(locations.count)")
                
                routeBuilder.insertRouteData(locations) { (success, error) in
                    if let error = error {
                        Log.debug("adding route data failed: \(error.localizedDescription)")
                        completionHandler(.failure(dataError(.failure, system: error)))
                        return
                    }
                    
                    builder.finishWorkout { (workout, error) in
                        guard let workout = workout else {
                            Log.debug("finish workout failed: \(error?.localizedDescription ?? "n/a"))")
                            completionHandler(.failure(dataError(.failure, system: error)))
                            return
                        }
                        
                        routeBuilder.finishRoute(with: workout, metadata: nil) { (route, error) in
                            if let error = error {
                                Log.debug("finish route failed: \(error.localizedDescription)")
                                completionHandler(.failure(DataError.system(error)))
                                return
                            }
                            completionHandler(.success(true))
                        }
                    }
                }
            }
        }
    }
    
    static func samples(for intervals: [ImportInterval]) ->  [HKSample] {
        var samples = [HKSample]()
        
        for interval in intervals {
            guard let start = interval.startDate, let end = interval.endDate else { continue }

            // TODO: - Update distances depending on activity type
            if let distance = interval.distance {
                let sample = HKCumulativeQuantitySample(
                    type: .distanceCycling(),
                    quantity: HKQuantity(unit: .meter(), doubleValue: distance),
                    start: start, end: end
                )
                samples.append(sample)
            }
            
            if let heartRate = interval.heartRate {
                let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let sample = HKQuantitySample(
                    type: .heartRate(),
                    quantity: HKQuantity(unit: unit, doubleValue: heartRate),
                    start: start,
                    end: end
                )
                samples.append(sample)
            }
            
            if let energyBurned = interval.energyBurned {
                let sample = HKCumulativeQuantitySample(
                    type: .activeEnergyBurned(),
                    quantity: HKQuantity(unit: .kilocalorie(),
                                         doubleValue: energyBurned),
                    start: start,
                    end: end
                )
                samples.append(sample)
            }
        }
        
        return samples
    }
    
    static func metadata(for workoutImport: WorkoutImport) -> [String: Any] {
        var dictionary = [String: Any]()
        
        if let avgTemperature = workoutImport.avgTemperature.temperatureValue {
            dictionary[HKMetadataKeyWeatherTemperature] = HKQuantity(unit: .degreeCelsius(), doubleValue: avgTemperature)
        }

        if let avgSpeed = workoutImport.avgSpeed.speedValue {
            let unit = HKUnit.meter().unitDivided(by: .second())
            dictionary[HKMetadataKeyAverageSpeed] = HKQuantity(unit: unit, doubleValue: avgSpeed)
        }

        if let maxSpeed = workoutImport.maxSpeed.speedValue {
            let unit = HKUnit.meter().unitDivided(by: .second())
            dictionary[HKMetadataKeyMaximumSpeed] = HKQuantity(unit: unit, doubleValue: maxSpeed)
        }
        
        if let totalAscent = workoutImport.totalAscent.altitudeValue {
            dictionary[HKMetadataKeyElevationAscended] = HKQuantity(unit: .meter(), doubleValue: totalAscent)
        }
        
        if let totalDescent = workoutImport.totalDescent.altitudeValue {
            dictionary[HKMetadataKeyElevationDescended] = HKQuantity(unit: .meter(), doubleValue: totalDescent)
        }
        
        // TODO: Pending Metadata
        // Average METs
        // Humidity
        // Time Zone
        // Elevation Ascended
        
        return dictionary
    }
    
}

// MARK: - Quantities

extension WorkoutDataStore {
    typealias DoubleResultHandler = (Result<Double, Error>) -> Void
    typealias IntegerResultHandler = (Result<Int, Error>) -> Void
    
    static func fetchTotalWorkouts(for activities: [HKWorkoutActivityType], completionHandler: @escaping IntegerResultHandler) {
        fetchWorkouts(for: activities) { result in
            switch result {
            case .success(let workouts):
                completionHandler(.success(workouts.count))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    static func fetchTotalCalories(for activities: [HKWorkoutActivityType], completionHandler: @escaping DoubleResultHandler) {
        fetchStatisticsSumValue(
            for: HKQuantityTypeIdentifier.activeEnergyBurned,
            unit: .kilocalorie(),
            predicate: nil,
            completionHandler: completionHandler
        )
    }
    
    static func fetchTotalDistance(for activities: [HKWorkoutActivityType], completionHandler: @escaping DoubleResultHandler) {
        fetchStatisticsSumValue(
            for: HKQuantityTypeIdentifier.distanceCycling,
            unit: .mile(),
            predicate: predicateForActivities(activities),
            completionHandler: completionHandler
        )
    }
    
    private static func fetchStatisticsSumValue(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, predicate: NSPredicate? = nil, completionHandler: @escaping DoubleResultHandler) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            fatalError("invalid quantity type")
        }
        
        let options = HKStatisticsOptions.cumulativeSum
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: options) { (query, statistics, error) in
            guard let quantity = quantity(for: statistics, options: options) else {
                completionHandler(.failure(DataError.missingData))
                return
            }
            
            let value = quantity.doubleValue(for: unit)
            completionHandler(.success(value))
        }
        healthStore.execute(query)
    }
    
    private static func quantity(for statistics: HKStatistics?, options: HKStatisticsOptions) -> HKQuantity? {
        guard let statistics = statistics else { return nil }
        switch options {
        case .cumulativeSum:
            return statistics.sumQuantity()
        default:
            return nil
        }
    }
    
}
