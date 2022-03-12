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
        
    static let shared = WorkoutDataStore()
    
    private let healthStore = HealthData.shared.healthStore
    
    private init() {
        // no-op
    }
}

extension WorkoutDataStore.DataError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .missingData:
            return "missing data"
        case .missingValue:
            return "missing value"
        case .failure:
            return "failure"
        case .sportNotSupported:
            return "sport not supported"
        case .system(let error):
            return "system error: \(error.localizedDescription)"
        }
    }
    
}

extension WorkoutDataStore {
    
    func dataError(_ error: DataError, system: Error?) -> DataError {
        if let systemError = system {
            return .system(systemError)
        }
        return error
    }
    
}

// MARK: - Write Workouts

extension WorkoutDataStore {
    
    func saveWorkoutImport(_ workoutImport: WorkoutImport, completionHandler: @escaping (Result<Bool, DataError>) -> Void) {
        guard let start = workoutImport.startDate, let end = workoutImport.endDate else {
            fatalError("missing dates")
        }
        
        guard workoutImport.sport.isImportSupported else {
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
        
        let records = workoutImport.records
        var samples = self.samples(for: records, sport: workoutImport.sport, indoor: workoutImport.indoor)
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
                if locations.isEmpty {
                    builder.finishWorkout { workout, error in
                        if let error = error {
                            completionHandler(.failure(dataError(.failure, system: error)))
                        } else {
                            completionHandler(.success(true))
                        }
                    }
                } else {
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
                                } else {
                                    completionHandler(.success(true))
                                }                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func samples(for records: [WorkoutImport.Record], sport: Sport, indoor: Bool) ->  [HKSample] {
        var samples = [HKSample]()
        
        for (prevRecord, record) in zip(records, records.dropFirst()) {
            if let sample = distanceSampleFor(record: record, prevRecord: prevRecord, sport: sport) {
                samples.append(sample)
            }
            
            if let sample = heartRateSampleFor(record: record) {
                samples.append(sample)
            }
        }
        
        return samples
    }
    
    private func distanceSampleFor(record: WorkoutImport.Record, prevRecord: WorkoutImport.Record, sport: Sport) -> HKSample? {
        guard sport.hasDistanceSamples else { return nil }
        
        var quantityType: HKQuantityType?
        switch sport {
        case .cycling:
            quantityType = .distanceCycling()
        case .walking, .running, .hiking:
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
        dictionary[MetadataKeyMaxTemperature] = file.maxTemperatureValue
        dictionary[MetadataKeyMovingTime] = file.totalTimerTimeValue
        dictionary[MetadataKeyAvgHeartRate] = file.avgHeartRateValue
        dictionary[MetadataKeyMinHeartRate] = file.minHeartRateValue
        dictionary[MetadataKeyMaxHeartRate] = file.maxHeartRateValue
        dictionary[MetadataKeyMinAltitude] = file.minAltitudeValue
        dictionary[MetadataKeyMaxAltitude] = file.maxAltitudeValue
        
        if file.sport == .cycling {
            dictionary[MetadataKeyAvgCyclingCadence] = file.totalAvgCadenceValue
            dictionary[MetadataKeyMaxCyclingCadence] = file.totalMaxCadenceValue
        }
        
        return dictionary.compactMapValues({ $0 })
    }
    
}
