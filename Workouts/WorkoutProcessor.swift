//
//  WorkoutProcessor.swift
//  Workouts
//
//  Created by Axel Rivera on 7/3/22.
//

import Foundation
import HealthKit
import CoreData
import MapKit
import Polyline

fileprivate let gregorianCalendar = Calendar.init(identifier: .gregorian)

extension WorkoutProcessor {
    struct Values {
        // Heart Rate
        let avgHeartRate: Double
        let maxHeartRate: Double
        
        // Energy
        let energyBurned: Double
        
        // Effort
        let trimp: Int
        let avgHeartRateReserve: Double
        
        // Location
        let coordinates: [CLLocationCoordinate2D]
        let minElevation: Double
        let maxElevation: Double
        
        static func empty() -> Values {
            Values(
                avgHeartRate: 0,
                maxHeartRate: 0,
                energyBurned: 0,
                trimp: 0,
                avgHeartRateReserve: 0,
                coordinates: [],
                minElevation: 0,
                maxElevation: 0
            )
        }
    }
}

actor WorkoutProcessor {
    private let workout: HKWorkout
    private let profileMaxHR: Int
    private let profileRestingHR: Int
    private let profileGender: UserGender
    private let provider = HealthProvider.shared
    
    
    var weekday: Int {
        gregorianCalendar.component(.weekday, from: start)
    }
    
    var values = Values.empty()
    
    init(workout: HKWorkout, maxHR: Int, restingHR: Int, gender: UserGender) {
        self.workout = workout
        self.profileMaxHR = maxHR
        self.profileRestingHR = restingHR
        self.profileGender = gender
    }
    
}

extension WorkoutProcessor {
    
    func process() async {
        await loadValues()
    }
    
}

// MARK: Values

extension WorkoutProcessor {
    
    private func loadValues() async {
        let (avgHeartRate, maxHeartRate) = await updateHeartRate()
        async let energy = updateTotalEnergy()
        async let (trimp, heartRateReserve) = updateTrainingLoad(avgHeartRate: avgHeartRate)
        async let (coordinates, minElevation, maxElevation) = updateLocationData()
        
        values = await Values(
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            energyBurned: energy,
            trimp: trimp,
            avgHeartRateReserve: heartRateReserve,
            coordinates: coordinates,
            minElevation: minElevation,
            maxElevation: maxElevation
        )
        
        await generateImageData()
    }
    
    // MARK: - Heart Rate and Energy
    
    typealias HeartRateReturn = (avg: Double, max: Double)
    
    private func updateHeartRate() async -> HeartRateReturn {
        if workoutAvgHeartRate > 0, workoutMaxHeartRate > 0 {
            Log.debug("UPDATE - ignore heart rate for \(identifier)")
            return (workoutAvgHeartRate, workoutMaxHeartRate)
        }
        
        let avg: Double
        let max: Double
        
        do {
            (avg, max) = try await provider.fetchHeartRateStats(for: workout)
        } catch {
            Log.debug("failed to fetch heart rate samples for \(identifier): \(error.localizedDescription)")
            avg = 0
            max = 0
        }
        
        return (avg, max)
    }

    private func updateTotalEnergy() async -> Double {
        if workoutTotalEnergyBurned > 0 {
            Log.debug("UPDATE - ignore energy for \(identifier)")
            return workoutTotalEnergyBurned
        }
        
        let energy: Double
        do {
            energy = try await provider.fetchActiveEnergy(for: workout)
        } catch {
            Log.debug("UPDATE - failed energy for \(identifier)")
            energy = 0
        }
        return energy
    }
    
    // MARK: Training Load
    
    typealias TrainingLoadReturn = (trimp: Int, reserve: Double)
    
    private func updateTrainingLoad(avgHeartRate: Double) async -> TrainingLoadReturn {
        do {
            guard provider.isTrainingLoadSupported else {
                throw WorkoutError("training load not supported")
            }
            
            guard avgHeartRate > 0 else {
                throw WorkoutError("missing avg heart rate")
            }

            let paddedSamples = try await provider.fetchPaddedHeartRateSamples(for: workout)
            let loadProcessor = TrainingLoadProcessor(
                gender: profileGender,
                maxHeartRate: profileMaxHR,
                restingHeartRate: profileRestingHR,
                paddedHeartRateSamples: paddedSamples
            )

            let trimp = loadProcessor.trimp()
            let reserve = loadProcessor.percentHeartRateReserve(for: Int(avgHeartRate))
            
            return (trimp, reserve)
        } catch {
            return (0, 0)
        }
    }
    
    // MARK: Location
    
    typealias LocationReturn = (coordinates: [CLLocationCoordinate2D], min: Double, max: Double)
    
    private func updateLocationData() async -> LocationReturn {
        guard hasLocationData else { return ([], 0, 0) }
        
        let locations: [CLLocation]
        do {
            locations = try await provider.fetchLocations(for: workout)
        } catch {
            locations = []
        }
        
        guard locations.isPresent else { return ([], 0, 0) }

        var coordinates = [CLLocationCoordinate2D]()
        var altitudes = [Double]()
        
        if abs(workoutMinElevation) > 0 && abs(workoutMaxElevation) > 0 {
            coordinates = locations.map { $0.coordinate }
        } else {
            for location in locations {
                coordinates.append(location.coordinate)
                altitudes.append(location.altitude)
            }
        }
        
        let min = altitudes.min() ?? workoutMinElevation
        let max = altitudes.max() ?? workoutMaxElevation
        
        return (coordinates, min, max)
    }
    
    private func generateImageData() async {
        guard hasLocationData else { return }
        
        do {
            try await Self.generateAndSaveImageData(for: identifier, coordinates: values.coordinates)
        } catch {
            Log.debug("unable to generate images for \(identifier): \(error.localizedDescription)")
        }
    }
    
    static func generateAndSaveImageData(for identifier: UUID, coordinates: [CLLocationCoordinate2D]) async throws {
        async let dark = try MKMapView.workoutMapData(coordinates: coordinates, colorScheme: .dark)
        async let light = try MKMapView.workoutMapData(coordinates: coordinates, colorScheme: .light)
        let images: (dark: Data, light: Data) = try await (dark, light)
        
        try WorkoutImageProvider.writeImageData(dark: images.dark, light: images.light, workout: identifier)
    }
    
}

// MARK: Helper Methods

extension WorkoutProcessor {
    
    var identifier: UUID {
        workout.uuid
    }
    
    var sport: Sport {
        workout.workoutActivityType.sport()
    }
    
    var hasLocationData: Bool {
        workout.isOutdoor && sport.hasDistanceSamples
    }
    
    var indoor: Bool {
        workout.isIndoor
    }
    
    var start: Date {
        workout.startDate
    }
    
    var end: Date {
        workout.endDate
    }
    
    var duration: Double {
        workout.totalElapsedTime
    }
    
    var movingTime: Double {
        workout.movingTime
    }
    
    var distance: Double {
        workout.totalDistanceValue
    }
    
    var avgSpeed: Double {
        workout.avgSpeedValue
    }
    
    var avgMovingSpeed: Double {
        workout.avgMovingSpeedValue
    }
    
    var maxSpeed: Double {
        workout.maxSpeedValue
    }
    
    var avgPace: Double {
        workout.avgPaceValue
    }
    
    var avgMovingPace: Double {
        workout.avgMovingPaceValue
    }
    
    var avgCyclingCadence: Double {
        workout.avgCyclingCadenceValue
    }
    
    var maxCyclingCadence: Double {
        workout.maxCyclingCadenceValue
    }
    
    var elevationAscended: Double {
        workout.elevationDescendedValue
    }
    
    var elevationDescended: Double {
        workout.elevationDescendedValue
    }
    
    var source: String {
        workout.sourceRevision.source.name
    }
    
    var device: String? {
        workout.device?.name
    }
    
    // MARK: Data Values
    
    var avgHeartRate: Double {
        values.avgHeartRate
    }
    
    var maxHeartRate: Double {
        values.maxHeartRate
    }
    
    var energyBurned: Double {
        values.energyBurned
    }
    
    var trimp: Int {
        values.trimp
    }
    
    var avgHeartRateReserve: Double {
        values.avgHeartRateReserve
    }
    
    var coordinatesValue: String {
        Polyline(coordinates: values.coordinates).encodedPolyline
    }
    
    var minElevation: Double {
        values.minElevation
    }
    
    var maxElevation: Double {
        values.maxElevation
    }
    
    // MARK: Procesing Values
    
    var workoutAvgHeartRate: Double {
        workout.avgHeartRateValue ?? 0
    }
    
    var workoutMaxHeartRate: Double {
        workout.maxHeartRateValue ?? 0
    }
    
    var workoutTotalEnergyBurned: Double {
        if workout.totalEnergyBurnedValue > 0 {
            return workout.totalEnergyBurnedValue
        } else {
            return workout.totalCaloriesValue ?? 0
        }
    }
    
    var workoutMaxElevation: Double {
        workout.maxAltitudeValue ?? 0
    }
    
    var workoutMinElevation: Double {
        workout.minAltitudeValue ?? 0
    }
    
}

extension WorkoutProcessor {
    
    struct Result {
        let dayOfWeek: Int
        let avgCyclingCadence: Double
        let maxCyclingCadence: Double
        let avgHeartRate: Double
        let maxHeartRate: Double
        let energyBurned: Double
        let coordinatesValue: String
        let minElevation: Double
        let maxElevation: Double
        let trimp: Int
        let avgHeartRateReserve: Double
        
        static let empty: Result = {
            Result(
                dayOfWeek: 0,
                avgCyclingCadence: 0,
                maxCyclingCadence: 0,
                avgHeartRate: 0,
                maxHeartRate: 0,
                energyBurned: 0,
                coordinatesValue: "",
                minElevation: 0,
                maxElevation: 0,
                trimp: 0,
                avgHeartRateReserve: 0
            )
        }()
    }
    
    var result: Result {
        Result(
            dayOfWeek: weekday,
            avgCyclingCadence: avgCyclingCadence,
            maxCyclingCadence: maxCyclingCadence,
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            energyBurned: energyBurned,
            coordinatesValue: coordinatesValue,
            minElevation: minElevation,
            maxElevation: maxElevation,
            trimp: trimp,
            avgHeartRateReserve: avgHeartRateReserve
        )
    }
    
    static func calculateHeartRateZones(for percents: [Int], maxHeartRate: Int) -> HRZoneTuple {
        let values = HRZonesCalculator.values(for: percents, maxHeartRate: maxHeartRate)
        
        var value1: Int = 0
        var value2: Int = 0
        var value3: Int = 0
        var value4: Int = 0
        var value5: Int = 0
        if values.count == 5 {
            value1 = values[0]
            value2 = values[1]
            value3 = values[2]
            value4 = values[3]
            value5 = values[4]
        }
        
        return (value1, value2, value3, value4, value5)
    }
    
    var dictionary: [String: Any] {
        let zoneHeartRate = provider.maxHeartRate()
        let zonePercents = provider.heartRateZonesPercents()
        let (value1, value2, value3, value4, value5) = Self.calculateHeartRateZones(for: zonePercents, maxHeartRate: zoneHeartRate)
        
        let now = Date()
        let dict: [WorkoutSchema: Any] = [
            .dayOfWeek: weekday,
            .avgCyclingCadence: avgCyclingCadence,
            .maxCyclingCadence: maxCyclingCadence,
            .zoneMaxHeartRate: zoneHeartRate,
            .zoneValue1: value1,
            .zoneValue2: value2,
            .zoneValue3: value3,
            .zoneValue4: value4,
            .zoneValue5: value5,
            .avgHeartRate: avgHeartRate,
            .maxHeartRate: maxHeartRate,
            .energyBurned: energyBurned,
            .coordinatesValue: coordinatesValue,
            .minElevation: minElevation,
            .maxElevation: maxElevation,
            .trimp: trimp,
            .avgHeartRateReserve: avgHeartRateReserve,
            .valuesUpdated: now,
            .markedForDeletionDate: NSNull()
        ]
        
        return dict.rawValuesDictionary
    }
    
}
