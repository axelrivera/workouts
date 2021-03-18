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
        case sportNotSupported
        case system(Error)
    }
    
    static let healthStore = HealthData.healthStore
    
    static func dataError(_ error: DataError, system: Error?) -> DataError {
        if let systemError = system {
            return .system(systemError)
        }
        return error
    }
    
    static func fetchWorkout(for id: UUID, completionHandler: @escaping (HKWorkout?) -> Void) {
        let predicate = HKQuery.predicateForObject(with: id)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 1, sortDescriptors: nil) { (query, samples, error) in
            let workout = samples?.first as? HKWorkout
            completionHandler(workout)
        }
        healthStore.execute(query)
    }
    
    static func fetchTotalWorkouts(completionHandler: @escaping (Result<Int, Error>) -> Void) {
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: nil,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil) { (query, samples, error) in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            
            let samples = samples as? [HKWorkout] ?? [HKWorkout]()
            completionHandler(.success(samples.count))
        }
        healthStore.execute(query)
        
    }
    
    static func predicateForActivities(_ activities: [HKWorkoutActivityType]) -> NSPredicate {
        if activities.isEmpty { fatalError("activities cannot be empty") }
        let predicates = activities.map({ HKQuery.predicateForWorkouts(with: $0) })
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
    
    static func fetchRoute(for workout: HKWorkout, completionHandler: @escaping (Result<[CLLocation], Error>) -> Void) {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKAnchoredObjectQuery(
            type: HKSeriesType.workoutRoute(),
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
            healthStore.stop(query)
                                                
            if let error = error {
                completionHandler(.failure(error))
                return
            }
                                    
            guard let samples = samples as? [HKWorkoutRoute], !samples.isEmpty else {
                completionHandler(.failure(DataError.failure))
                return
            }
                        
            var locations = [CLLocation]()
            samples.forEach { route in
                fetchLocation(for: route) { (newLocations) in
                    locations.append(contentsOf: newLocations)
                } completionHandler: { result in
                    switch result {
                    case .success:
                        completionHandler(.success(locations))
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                }
            }
        }

//        query.updateHandler = { (query, samples, deleted, anchor, error) in
//
//        }
        
        healthStore.execute(query)
    }
    
    static func fetchRoute(for id: UUID, completionHandler: @escaping (Result<[CLLocation], Error>) -> Void) {
        fetchWorkout(for: id) { (workout) in
            guard let workout = workout else {
                completionHandler(.failure(DataError.failure))
                return
            }
            
            fetchRoute(for: workout, completionHandler: completionHandler)
        }
    }
    
    private static func fetchLocation(for route: HKWorkoutRoute, updateHandler: @escaping ([CLLocation]) -> Void, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        let store = HKHealthStore()
        
        let query = HKWorkoutRouteQuery(route: route) { (query, locations, done, error) in
            let locations = locations ?? [CLLocation]()
            updateHandler(locations)
            
            if done {
                completionHandler(.success(true))
                store.stop(query)
            }
        }
        healthStore.execute(query)
    }
    
}

// MARK: - Heart Rate

extension WorkoutDataStore {
    
    typealias HeartRateStatsValue = (avg: Double?, max: Double?)
    
    static func fetchHeartRateStatsValue(workout: HKWorkout, completionHandler: @escaping (Result<HeartRateStatsValue, Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictStartDate, .strictEndDate])
        let source = workout.sourceRevision.source
        
        let query = HKStatisticsQuery(
            quantityType: .heartRate(),
            quantitySamplePredicate: predicate,
            options: [.discreteAverage, .discreteMax, .separateBySource]) { (query, statistics, error) in
            guard let statistics = statistics else {
                completionHandler(.failure(error ?? DataError.failure))
                return
            }
            
            let avg = statistics.averageQuantity(for: source)?.doubleValue(for: HKUnit.bpm())
            let max = statistics.maximumQuantity(for: source)?.doubleValue(for: HKUnit.bpm())
            
            completionHandler(.success((avg, max)))
        }
        healthStore.execute(query)
    }
    
    static func fetchHeartRateSamples(workout: HKWorkout, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictStartDate, .strictEndDate])
        let source = workout.sourceRevision.source
        
        var interval = DateComponents()
        interval.minute = 1
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: Date())
        let anchorDate = calendar.date(from: dateComponents)!
        
        let query = HKStatisticsCollectionQuery(
            quantityType: .heartRate(),
            quantitySamplePredicate: predicate,
            options: [.discreteMax, .separateBySource],
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { (query, results, error) in
            guard let results = results else {
                completionHandler(.failure(error ?? DataError.failure))
                return
            }
            
            var sortedStatistics = results.statistics().sorted(by: { $0.startDate < $1.startDate })
            if sortedStatistics.count > 2 {
                sortedStatistics = sortedStatistics.dropFirst().dropLast()
            }
            
            let values: [Quantity] = sortedStatistics.compactMap { (statistics) in
                guard let quantity = statistics.maximumQuantity(for: source) else { return nil }
                return Quantity(quantityType: .heartRate, timestamp: statistics.startDate, value: quantity.doubleValue(for: .bpm()))
            }
            completionHandler(.success(values))
        }
        healthStore.execute(query)
    }
            
    static func fetchRunningWalkingPaceSamples(workout: HKWorkout, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictStartDate, .strictEndDate])
        let source = workout.sourceRevision.source
        
        var interval = DateComponents()
        interval.minute = 1
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: Date())
        let anchorDate = calendar.date(from: dateComponents)!
        
        let query = HKStatisticsCollectionQuery(
            quantityType: .distanceWalkingRunning(),
            quantitySamplePredicate: predicate,
            options: [.cumulativeSum, .separateBySource],
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { (query, results, error) in
            guard let results = results else {
                completionHandler(.failure(error ?? DataError.failure))
                return
            }
            
            var sortedStatistics = results.statistics().sorted(by: { $0.startDate < $1.startDate })
            if sortedStatistics.count > 2 {
                sortedStatistics = sortedStatistics.dropFirst().dropLast()
            }
            
            let values: [Quantity] = sortedStatistics.compactMap { (statistics) in
                guard let quantity = statistics.sumQuantity(for: source) else { return nil }
                let distance = quantity.doubleValue(for: .meter())
                let duration = statistics.endDate.timeIntervalSince(statistics.startDate)
                let pace = calculateRunningWalkingPace(distanceInMeters: distance, duration: duration) ?? 0
                                
                return Quantity(quantityType: .pace, timestamp: statistics.startDate, value: pace)
            }
            completionHandler(.success(values))
        }
        healthStore.execute(query)
    }
    
    static func fetchCyclingCadenceSamples(workout: HKWorkout, completionHandler: @escaping (Result<[Quantity], Error>) -> Void) {
        let datePredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictStartDate, .strictEndDate])
        let cadencePredicate = HKQuery.predicateForObjects(withMetadataKey: MetadataKeySampleCadence)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, cadencePredicate])
        
        let dateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(
            sampleType: HKQuantityType.distanceCycling(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [dateSort]) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample] else {
                completionHandler(.failure(DataError.failure))
                return
            }
            
            var cleanSamples = samples
            if cleanSamples.count > 2 {
                cleanSamples = cleanSamples.dropFirst().dropLast()
            }
            let cadenceSamples: [Quantity] = cleanSamples.compactMap { sample in
                guard let cadence = sample.metadata?[MetadataKeySampleCadence] as? Double else { return nil }
                return Quantity(quantityType: .cadence, timestamp: sample.startDate, value: cadence)
            }
            completionHandler(.success(cadenceSamples))
            
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
        
        guard workoutImport.sport.isSupported else {
            completionHandler(.failure(.sportNotSupported))
            return
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutImport.activityType
        configuration.locationType = workoutImport.locationType
        
        if let lapLength = workoutImport.lapLength {
            configuration.lapLength = lapLength
        }
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: .local())
        
        builder.beginCollection(withStart: start) { (success, error) in
            guard success else {
                Log.debug("begin collection failed: \(error?.localizedDescription ?? "n/a")")
                completionHandler(.failure(dataError(.failure, system: error)))
                return
            }
        }
        
        let samples = self.samples(for: workoutImport.records, sport: workoutImport.sport, indoor: workoutImport.indoor)
        builder.add(samples) { (success, error) in
            guard success else {
                completionHandler(.failure(dataError(.failure, system: error)))
                return
            }
                        
            builder.endCollection(withEnd: end) { (success, error) in
                guard success else {
                    completionHandler(.failure(dataError(.failure, system: error)))
                    return
                }
                
                builder.addMetadata(metadata(for: workoutImport)) { (success, error) in
                    if let error = error {
                        Log.debug("failed to save metadata: \(error.localizedDescription)")
                    }
                }
                
                let locations = workoutImport.locations
                routeBuilder.insertRouteData(locations) { (success, error) in
                    if let error = error {
                        completionHandler(.failure(dataError(.failure, system: error)))
                        return
                    }
                    
                    builder.finishWorkout { (workout, error) in
                        guard let workout = workout else {
                            completionHandler(.failure(dataError(.failure, system: error)))
                            return
                        }
                        
                        routeBuilder.finishRoute(with: workout, metadata: nil) { (route, error) in
                            if let error = error {
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
    
    private static func samples(for records: [WorkoutImport.Record], sport: Sport, indoor: Bool) ->  [HKSample] {
        var samples = [HKSample]()
        
        for (prevRecord, record) in zip(records, records.dropFirst()) {
            if let sample = distanceSampleFor(record: record, prevRecord: prevRecord, sport: sport, indoor: indoor) {
                samples.append(sample)
            }
            
            if let sample = energySampleFor(record: record, prevRecord: prevRecord, sport: sport, indoor: indoor) {
                samples.append(sample)
            }
            
            if let sample = heartRateSampleFor(record: record) {
                samples.append(sample)
            }
        }
        
        return samples
    }
    
    private static func distanceSampleFor(record: WorkoutImport.Record, prevRecord: WorkoutImport.Record, sport: Sport, indoor: Bool) -> HKSample? {
        if indoor { return nil }
        guard sport.hasDistanceSamples else { return nil }
        
        var quantityType: HKQuantityType?
        switch sport {
        case .cycling:
            quantityType = .distanceCycling()
        case .walking, .running:
            quantityType = .distanceWalkingRunning()
        default:
            quantityType = nil
        }
        
        if quantityType == nil { return nil }
        
        guard let timestamp = record.timestamp.dateValue else { return nil }
        guard let endDistance = record.distance.distanceValue else { return nil }
        let startDistance = prevRecord.distance.distanceValue
        
        var distance: Double
        if let startDistance = startDistance {
            distance = endDistance - startDistance
        } else {
            distance = endDistance
        }
        
        var metadata = [String: Any]()
        if let cadence = record.totalCadence.cadenceValue, sport == .cycling {
            metadata[MetadataKeySampleCadence] = cadence
        }

        if let temperature = record.temperature.temperatureValue {
            metadata[MetadataKeySampleTemperature] = temperature
        }
        
        let sample = HKCumulativeQuantitySample(
            type: quantityType!,
            quantity: HKQuantity(unit: .meter(), doubleValue: distance),
            start: timestamp,
            end: timestamp,
            metadata: metadata.isEmpty ? nil : metadata
        )
        return sample
    }
    
    private static func energySampleFor(record: WorkoutImport.Record, prevRecord: WorkoutImport.Record, sport: Sport, indoor: Bool) -> HKSample? {
        guard let prevSpeed = prevRecord.speed.speedValue, prevSpeed > 0 else { return nil }
        guard let speed = record.speed.speedValue, speed > 0 else { return nil }
        guard let timestamp = record.timestamp.dateValue else { return nil }
        
        let end = timestamp
        let start = prevRecord.timestamp.dateValue ?? end
        let durationInSeconds = end.timeIntervalSince1970 - start.timeIntervalSince1970
        let duration = durationInSeconds / 60.0 // minutes
                
        let metValue = metValueFor(sport: sport, indoor: indoor, speed: speed)
        let weight = AppSettings.weight ?? Constants.defaultWeight
        let energyBurned = calculateCaloriesFor(duration: duration, metValue: metValue, weight: weight)
                
        let sample = HKCumulativeQuantitySample(
            type: .activeEnergyBurned(),
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: energyBurned),
            start: timestamp,
            end: timestamp
        )
        return sample
    }
    
    private static func heartRateSampleFor(record: WorkoutImport.Record) -> HKSample? {
        guard let timestamp = record.timestamp.dateValue else { return nil }
        guard let heartRate = record.heartRate.heartRateValue else { return nil }
        let sample = HKQuantitySample(
            type: .heartRate(),
            quantity: HKQuantity(unit: HKUnit.bpm(), doubleValue: heartRate),
            start: timestamp,
            end: timestamp
        )
        return sample
    }
    
    private static func metadata(for file: WorkoutImport) -> [String: Any] {
        var dictionary = [String: Any]()
        dictionary[HKMetadataKeyIndoorWorkout] = file.indoor
        dictionary[HKMetadataKeyWeatherTemperature] = file.avgTemperatureQuantity
        dictionary[HKMetadataKeyAverageSpeed] = file.avgSpeedQuantity
        dictionary[HKMetadataKeyMaximumSpeed] = file.maxSpeedQuantity
        dictionary[HKMetadataKeyElevationAscended] = file.totalAscentQuantity
        dictionary[HKMetadataKeyElevationDescended] = file.totalDescentQuantity
        dictionary[HKMetadataKeyAverageMETs] = file.avgMETQuantity
        
        if file.sport == .cycling {
            dictionary[MetadataKeyAvgCyclingCadence] = file.totalAvgCadenceValue
            dictionary[MetadataKeyMaxCyclingCadence] = file.totalMaxCadenceValue
        }
        
        return dictionary.compactMapValues({ $0 })
    }
    
}
