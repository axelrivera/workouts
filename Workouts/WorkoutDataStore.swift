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
            return NSLocalizedString("Missing Data", comment: "Error")
        case .missingValue:
            return NSLocalizedString("Missing Value", comment: "Error")
        case .failure:
            return NSLocalizedString("Failure", comment: "Error")
        case .sportNotSupported:
            return NSLocalizedString("Sport Not Supported", comment: "Error")
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
    
    func saveWorkoutImport(_ workoutImport: WorkoutImport) async throws {
        guard let start = workoutImport.startDate, let end = workoutImport.endDate else {
            throw WorkoutError("missing dates in workout")
        }
        
        guard workoutImport.sport.isImportSupported else {
            throw DataError.sportNotSupported
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutImport.activityType
        configuration.locationType = workoutImport.locationType
        
        if let lapLength = workoutImport.lapLength {
            configuration.lapLength = lapLength
        }
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: .local())
        
        try await builder.beginCollection(at: start)
        
        let samples = self.samples(for: workoutImport)
        if samples.isPresent {
            try await builder.addSamples(samples)
        }
        
        try await builder.endCollection(at: end)
        
        let metadata = self.metadata(for: workoutImport)
        try await builder.addMetadata(metadata)
        
        let events = workoutImport.workoutEvents
        if events.isPresent {
            try await builder.addWorkoutEvents(events)
        }
        
        guard let workout = try await builder.finishWorkout() else {
            return
        }
        
        let locations = workoutImport.locations
        if locations.isPresent {
            try await routeBuilder.insertRouteData(locations)
            try await routeBuilder.finishRoute(with: workout, metadata: nil)
        }
    }
    
    private func samples(for file: WorkoutImport) -> [HKSample] {
        let fileSamples = file.samples()
        var samples = [HKSample]()
        
        var totalDistance = 0
        var totalEnergy = 0
        var totalHeartRate = 0
         
        for fileSample in fileSamples {
            if let distance = distanceSample(fileSample: fileSample, sport: file.sport) {
                totalDistance += 1
                samples.append(distance)
            }
            
            if let energy = energySample(fileSample: fileSample) {
                totalEnergy += 1
                samples.append(energy)
            }
            
            if let heartRate = heartRateSample(fileSample: fileSample) {
                totalHeartRate += 1
                samples.append(heartRate)
            }
        }
        
        Log.debug("total records: \(file.records.count)")
        Log.debug("total samples - distance: \(totalDistance), energy: \(totalEnergy), heartRate: \(totalHeartRate)")
        
        return samples
    }
    
    private func distanceSample(fileSample: WorkoutImport.Sample, sport: Sport) -> HKSample? {
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
        
        var metadata = [String: Any]()
        if let cadence = fileSample.cyclingCadence, sport == .cycling {
            metadata[MetadataKeySampleCadence] = cadence
        }

        if let temperature = fileSample.temperature {
            metadata[MetadataKeySampleTemperature] = temperature
        }
        
        let sample = HKCumulativeQuantitySample(
            type: quantityType!,
            quantity: HKQuantity(unit: .meter(), doubleValue: fileSample.distance),
            start: fileSample.start,
            end: fileSample.end,
            metadata: metadata.isEmpty ? nil : metadata
        )
        return sample
    }
    
    private func energySample(fileSample: WorkoutImport.Sample) -> HKSample? {
        guard let calories = fileSample.calories, calories > 0 else { return nil }
        return HKCumulativeQuantitySample(
            type: .activeEnergyBurned(),
            quantity: HKQuantity(unit: .largeCalorie(), doubleValue: calories),
            start: fileSample.start,
            end: fileSample.end
        )
    }
    
    private func heartRateSample(fileSample: WorkoutImport.Sample) -> HKSample? {
        guard let heartRate = fileSample.heartRate, heartRate > 0 else { return nil }
        return HKQuantitySample(
            type: .heartRate(),
            quantity: .init(unit: .bpm(), doubleValue: heartRate),
            start: fileSample.start,
            end: fileSample.start
        )
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
        dictionary[MetadataKeyEnergyBurned] = file.totalEnergyBurnedValue
        
        if file.sport == .cycling {
            dictionary[MetadataKeyAvgCyclingCadence] = file.totalAvgCadenceValue
            dictionary[MetadataKeyMaxCyclingCadence] = file.totalMaxCadenceValue
        }
        
        return dictionary.compactMapValues({ $0 })
    }
    
}
