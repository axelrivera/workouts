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
        
    let availableActivityTypes: [HKWorkoutActivityType] = [.cycling, .running, .walking]
    static let shared = WorkoutDataStore()
    
    private let healthStore = HealthData.shared.healthStore
    
    private init() {
        // no-op
    }
}

extension WorkoutDataStore {
    
    
    func dataError(_ error: DataError, system: Error?) -> DataError {
        if let systemError = system {
            return .system(systemError)
        }
        return error
    }
    
    func fetchWorkout(for id: UUID, completionHandler: @escaping (HKWorkout?) -> Void) {
        let predicate = HKQuery.predicateForObject(with: id)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 1, sortDescriptors: nil) { (query, samples, error) in
            let workout = samples?.first as? HKWorkout
            completionHandler(workout)
        }
        healthStore.execute(query)
    }
    
    func fetchTotalWorkouts(completionHandler: @escaping (Result<Int, Error>) -> Void) {
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
    
    func defaultActivitiesPredicate() -> NSPredicate {
        predicateForActivities(availableActivityTypes)
    }
    
    func predicateForActivities(_ activities: [HKWorkoutActivityType]) -> NSPredicate {
        if activities.isEmpty { fatalError("activities cannot be empty") }
        let predicates = activities.map({ HKQuery.predicateForWorkouts(with: $0) })
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
    
    func fetchRoute(for workout: HKWorkout, completionHandler: @escaping (Result<[CLLocation], Error>) -> Void) {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKAnchoredObjectQuery(
            type: HKSeriesType.workoutRoute(),
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
            self.healthStore.stop(query)
                                                
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
                self.fetchLocation(for: route) { (newLocations) in
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
        
        healthStore.execute(query)
    }
    
    func fetchRoute(for id: UUID, completionHandler: @escaping (Result<[CLLocation], Error>) -> Void) {
        fetchWorkout(for: id) { (workout) in
            guard let workout = workout else {
                completionHandler(.failure(DataError.failure))
                return
            }
            
            self.fetchRoute(for: workout, completionHandler: completionHandler)
        }
    }
    
    private func fetchLocation(for route: HKWorkoutRoute, updateHandler: @escaping ([CLLocation]) -> Void, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        let query = HKWorkoutRouteQuery(route: route) { (query, locations, done, error) in
            let locations = locations ?? [CLLocation]()
            updateHandler(locations)
            
            if done {
                self.healthStore.stop(query)
                completionHandler(.success(true))
            }
        }
        healthStore.execute(query)
    }
    
}

// MARK: - Heart Rate

extension WorkoutDataStore {
    
    typealias HeartRateStatsValue = (avg: Double?, max: Double?)
    
    private func intervalFor(start: Date, end: Date) -> DateComponents {
        var interval = DateComponents()
        interval.second = 1
        return interval
    }
    
    func fetchHeartRateStatsValue(workout: HKWorkout, completionHandler: @escaping (Result<HeartRateStatsValue, Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictStartDate, .strictEndDate])
        let source = workout.sourceRevision.source
        
        let query = HKStatisticsQuery(
            quantityType: .heartRate(),
            quantitySamplePredicate: predicate,
            options: [.discreteAverage, .discreteMax, .separateBySource]) { (query, statistics, error) in
            self.healthStore.stop(query)
            
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
    
    func fetchHeartRateSamples(workout: HKWorkout, completionHandler: @escaping (Result<[Any], Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictStartDate, .strictEndDate])
        let source = workout.sourceRevision.source
        
        let interval = intervalFor(start: workout.startDate, end: workout.endDate)
        
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
            self.healthStore.stop(query)
            
            guard let results = results else {
                completionHandler(.failure(error ?? DataError.failure))
                return
            }
            
            let sortedStatistics = results.statistics().sorted(by: { $0.startDate < $1.startDate })
            let values: [Quantity] = sortedStatistics.compactMap { (statistics) in
                guard let quantity = statistics.maximumQuantity(for: source) else { return nil }
                return Quantity(start: statistics.startDate, end: statistics.endDate, value: quantity.doubleValue(for: .bpm()))
            }
            completionHandler(.success(values))
        }
        healthStore.execute(query)
    }
            
    func fetchRunningWalkingPaceSamples(workout: HKWorkout, completionHandler: @escaping (Result<[Any], Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [.strictStartDate, .strictEndDate])
        let source = workout.sourceRevision.source
        
        let interval = intervalFor(start: workout.startDate, end: workout.endDate)
        
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
            self.healthStore.stop(query)
            
            guard let results = results else {
                completionHandler(.failure(error ?? DataError.failure))
                return
            }
            
            let sortedStatistics = results.statistics().sorted(by: { $0.startDate < $1.startDate })
            let values: [Pace] = sortedStatistics.compactMap { (statistics) in
                guard let quantity = statistics.sumQuantity(for: source) else { return nil }
                let distance = quantity.doubleValue(for: .meter())
                return Pace(start: statistics.startDate, end: statistics.endDate, distance: distance)
            }
            completionHandler(.success(values))
        }
        healthStore.execute(query)
    }
    
    func fetchCyclingCadenceSamples(workout: HKWorkout, completionHandler: @escaping (Result<[Any], Error>) -> Void) {
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
            
            let cadenceSamples: [Quantity] = samples.compactMap { sample in
                guard let cadence = sample.metadata?[MetadataKeySampleCadence] as? Double else { return nil }
                return Quantity(start: sample.startDate, end: sample.endDate, value: cadence)
            }
            completionHandler(.success(cadenceSamples))
            
        }
        healthStore.execute(query)
    }
    
}

// MARK: - Write Workouts

extension WorkoutDataStore {
    
    func saveWorkoutImport(_ workoutImport: WorkoutImport, completionHandler: @escaping (Result<Bool, DataError>) -> Void) {
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
                completionHandler(.failure(self.dataError(.failure, system: error)))
                return
            }
        }
        
        var samples = self.samples(for: workoutImport.records, sport: workoutImport.sport, indoor: workoutImport.indoor)
        if let energySample = energySample(for: workoutImport) {
            samples.append(energySample)
        }
        
        builder.add(samples) { (success, error) in
            guard success else {
                completionHandler(.failure(self.dataError(.failure, system: error)))
                return
            }
                        
            builder.endCollection(withEnd: end) { (success, error) in
                guard success else {
                    completionHandler(.failure(self.dataError(.failure, system: error)))
                    return
                }
                
                builder.addMetadata(self.metadata(for: workoutImport)) { (success, error) in
                    if let error = error {
                        Log.debug("failed to save metadata: \(error.localizedDescription)")
                    }
                }
                
                let workoutEvents = workoutImport.workoutEvents
                if workoutEvents.isPresent {
                    builder.addWorkoutEvents(workoutEvents) { success, error in
                        if let error = error {
                            Log.debug("failed to save events: \(error.localizedDescription)")
                        }
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
                        
                        // save a compressed FIT file to use in future once the workout is saved
//                        self.saveWorkoutImportFile(workoutImport)
                        
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
    
    private func samples(for records: [WorkoutImport.Record], sport: Sport, indoor: Bool) ->  [HKSample] {
        var samples = [HKSample]()
        
        for (prevRecord, record) in zip(records, records.dropFirst()) {
            if let sample = distanceSampleFor(record: record, prevRecord: prevRecord, sport: sport, indoor: indoor) {
                samples.append(sample)
            }
            
            if let sample = heartRateSampleFor(record: record) {
                samples.append(sample)
            }
        }
        
        return samples
    }
    
    private func distanceSampleFor(record: WorkoutImport.Record, prevRecord: WorkoutImport.Record, sport: Sport, indoor: Bool) -> HKSample? {
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
    
    private func energySample(for file: WorkoutImport) -> HKSample? {
        guard let start = file.startDate, let end = file.endDate else { return nil }
        guard let energyBurned = file.totalEnergyBurned.caloriesValue else { return nil }
        
        return HKCumulativeQuantitySample(
            type: .activeEnergyBurned(),
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: energyBurned),
            start: start,
            end: end
        )
    }
    
    private func heartRateSampleFor(record: WorkoutImport.Record) -> HKSample? {
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
    
    private func metadata(for file: WorkoutImport) -> [String: Any] {
        var dictionary = [String: Any]()
        dictionary[HKMetadataKeyExternalUUID] = file.uuidString
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
    
    private var workoutsDirectory: URL {
        FileUtils.workoutImportDirectory
    }
    
    private func saveWorkoutImportFile(_ file: WorkoutImport) {
        guard let fileURL = file.fileURL else { return }
        
        let fileName = String(format: "%@.zip", file.uuidString)
        let destinationURL = workoutsDirectory.appendingPathComponent(fileName)
        
        let fileManager = FileManager.default
        do {
            try createWorkoutsDirectory() // try to create directory if it doesn't exist
            try fileManager.zipItem(at: fileURL, to: destinationURL)
        } catch {
            Log.debug("failed to write workout file \(destinationURL.path), error: \(error.localizedDescription)")
        }
    }
    
    private func createWorkoutsDirectory() throws {
        try FileManager.default.createDirectory(
            at: workoutsDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
}
