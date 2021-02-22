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
    
    static func fetchRoute(for workout: HKWorkout, completionHandler: @escaping (Result<[CLLocationCoordinate2D], Error>) -> Void) {
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
                        
            guard let samples = samples as? [HKWorkoutRoute] else {
                completionHandler(.failure(DataError.failure))
                return
            }
                        
            var coordinates = [CLLocationCoordinate2D]()
            samples.forEach { route in
                fetchLocation(for: route) { (locations) in
                    coordinates.append(contentsOf: locations.map({ $0.coordinate }))
                } completionHandler: { result in
                    switch result {
                    case .success:
                        completionHandler(.success(coordinates))
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
    
    static func fetchRoute(for id: UUID, completionHandler: @escaping (Result<[CLLocationCoordinate2D], Error>) -> Void) {
        Log.debug("fetching route for: \(id)")
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
        healthStore.execute(query)
    }
    
}

// MARK: - Heart Rate

extension WorkoutDataStore {
    
    typealias HeartRateSample = (avg: Double?, max: Double?)
    
    static func fetchHeartRateSample(for workout: UUID, completionHandler: @escaping (Result<HeartRateSample, Error>) -> Void) {
        fetchWorkout(for: workout) { (workout) in
            guard let workout = workout else {
                completionHandler(.failure(DataError.failure))
                return
            }
            fetchHeartRateSample(start: workout.startDate, end: workout.endDate, completionHandler: completionHandler)
        }
    }
    
    static func fetchHeartRateSample(start: Date, end: Date, completionHandler: @escaping (Result<HeartRateSample, Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        
        let query = HKStatisticsQuery(
            quantityType: .heartRate(),
            quantitySamplePredicate: predicate,
            options: [.discreteAverage, .discreteMax]) { (query, statistics, error) in
            guard let statistics = statistics else {
                completionHandler(.failure(error ?? DataError.failure))
                return
            }
            
            let avg = statistics.averageQuantity()?.doubleValue(for: HKUnit.bpm())
            let max = statistics.maximumQuantity()?.doubleValue(for: HKUnit.bpm())
            
            completionHandler(.success((avg, max)))
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
        configuration.lapLength = HKQuantity(unit: .mile(), doubleValue: 5.0)
        
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
                Log.debug("samples failed: \(error?.localizedDescription ?? "n/a")")
                completionHandler(.failure(dataError(.failure, system: error)))
                return
            }
            
            // TODO: Implement Events
//            let events = self.events(for: workoutImport)
//            builder.addWorkoutEvents(events) { (success, error) in
//                if let error = error {
//                    Log.debug("adding workout events failed: \(error.localizedDescription)")
//                }
//            }
                        
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
    
    private static func samples(for records: [WorkoutImport.Record], sport: Sport, indoor: Bool) ->  [HKSample] {
        var samples = [HKSample]()
        
        var prevRecord: WorkoutImport.Record?
        for record in records {
            if let sample = distanceSampleFor(record: record, prevRecord: prevRecord, sport: sport, indoor: indoor) {
                samples.append(sample)
            }
            
            if let sample = energySampleFor(record: record, prevRecord: prevRecord, sport: sport, indoor: indoor) {
                samples.append(sample)
            }
            
            if let sample = heartRateSampleFor(record: record) {
                samples.append(sample)
            }
            
            prevRecord = record
        }
        
        return samples
    }
    
    private static func distanceSampleFor(record: WorkoutImport.Record, prevRecord: WorkoutImport.Record?, sport: Sport, indoor: Bool) -> HKSample? {
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
        let startDistance = prevRecord?.distance.distanceValue
        
        var distance: Double
        if let startDistance = startDistance {
            distance = endDistance - startDistance
        } else {
            distance = endDistance
        }
        
        var metadata = [String: Any]()
        if let cadence = record.totalCadence.cadenceValue {
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
    
    private static func energySampleFor(record: WorkoutImport.Record, prevRecord: WorkoutImport.Record?, sport: Sport, indoor: Bool) -> HKSample? {
        guard let speed = record.speed.speedValue else { return nil }
        guard let timestamp = record.timestamp.dateValue else { return nil }
        
        let end = timestamp
        let start = prevRecord?.timestamp.dateValue ?? end
        let durationInSeconds = end.timeIntervalSince1970 - start.timeIntervalSince1970
        let duration = durationInSeconds / 60.0 // minutes
                
        let metValue = metValueFor(sport: sport, indoor: indoor, speed: speed)
        let weight = AppSettings.weight ?? Constants.defaultWeight
        let energyBurned = calculateCaloriesFor(duration: duration, metValue: metValue, weight: weight)
        
        Log.debug("sample calories: \(energyBurned), met: \(metValue), speed: \(speed)")
        
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
    
//    private static func events(for workoutImport: WorkoutImport) -> [HKWorkoutEvent] {
//        var events = [HKWorkoutEvent]()
//        return events
//    }
    
    private static func metadata(for file: WorkoutImport) -> [String: Any] {
        var dictionary = [String: Any]()
        dictionary[HKMetadataKeyIndoorWorkout] = file.indoor
        dictionary[HKMetadataKeyWeatherTemperature] = file.avgTemperatureQuantity
        dictionary[HKMetadataKeyAverageSpeed] = file.avgSpeedQuantity
        dictionary[HKMetadataKeyMaximumSpeed] = file.maxSpeedQuantity
        dictionary[HKMetadataKeyElevationAscended] = file.totalAscentQuantity
        dictionary[HKMetadataKeyElevationDescended] = file.totalDescentQuantity
        dictionary[HKMetadataKeyAverageMETs] = file.avgMETQuantity
        dictionary[MetadataKeyAvgCyclingCadence] = file.totalAvgCadenceValue
        dictionary[MetadataKeyMaxCyclingCadence] = file.totalMaxCadenceValue
        
        // TODO: Pending Metadata
        // Humidity
        // Elevation Ascended
        
        return dictionary.compactMapValues({ $0 })
    }
    
}
