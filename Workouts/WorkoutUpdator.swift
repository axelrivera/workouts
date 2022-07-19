//
//  WorkoutUpdator.swift
//  Workouts
//
//  Created by Axel Rivera on 7/9/22.
//

import Foundation
import HealthKit
import CoreLocation
import Polyline
import CoreData
import MapKit

//struct WorkoutUpdatorData {
//    // Heart Rate
//    let avgHeartRate: Double?
//    let maxHeartRate: Double?
//
//    // Energy
//    let energyBurned: Double?
//
//    // Effort
//    let trimp: Int?
//    let avgHeartRateReserve: Double?
//
//    // Location
//    let coordinates: [CLLocationCoordinate2D]
//    let minElevation: Double?
//    let maxElevation: Double?
//}
//
//actor WorkoutUpdator {
//    private let identifier: UUID
//    private let provider = HealthProvider.shared
//
//    private var remoteWorkout: HKWorkout!
//    private var workout: Workout!
//    private var data: WorkoutUpdatorData?
//
//    init(identifier: UUID) {
//        self.identifier = identifier
//    }
//
//}
//
//extension WorkoutUpdator {
//    enum UpdatorError: Error, LocalizedError {
//        case missingWorkout
//        case missingRemote
//
//        var errorDescription: String? {
//            switch self {
//            case .missingWorkout:
//                return "missing workout"
//            case .missingRemote:
//                return "missing remote workout"
//            }
//        }
//    }
//
//    @discardableResult
//    func updateValues(context: NSManagedObjectContext) async throws -> Workout {
//        guard let remoteWorkout = try? await provider.fetchWorkout(uuid: identifier) else {
//            throw UpdatorError.missingRemote
//        }
//
//        guard let workout = Workout.find(using: identifier, in: context) else {
//            throw UpdatorError.missingWorkout
//        }
//
//        self.remoteWorkout = remoteWorkout
//        self.workout = workout
//
//        await loadValues()
//
//        context.performAndWait {
//            // Heart Rate & Energy
//            if let avgHeartRate = data?.avgHeartRate {
//                workout.avgHeartRate = avgHeartRate
//            }
//
//            if let maxHeartRate = data?.maxHeartRate {
//                workout.maxHeartRate = maxHeartRate
//            }
//
//            if let energyBurned = data?.energyBurned {
//                workout.energyBurned = energyBurned
//            }
//
//            // Effort
//            if let trimp = data?.trimp {
//                workout.trimp = trimp
//            }
//
//            if let avgHeartRateReserve = data?.avgHeartRateReserve {
//                workout.avgHeartRateReserve = avgHeartRateReserve
//            }
//
//            if let coordinates = data?.coordinates, coordinates.isPresent {
//                let value = Polyline(coordinates: coordinates).encodedPolyline
//                workout.coordinatesValue = value
//            }
//
//            if let minElevation = data?.minElevation {
//                workout.minElevation = minElevation
//            }
//
//            if let maxElevation = data?.maxElevation {
//                workout.maxElevation = maxElevation
//            }
//
//            // Mark as Completed
//            workout.valuesUpdated = Date()
//        }
//
//        return workout
//    }
//
//    private func loadValues() async {
//        async let (avgHeartRate, maxHeartRate) = updateHeartRate()
//        async let energy = updateTotalEnergy()
//        async let (trimp, heartRateReserve) = updateTrainingLoad()
//        async let (coordinates, minElevation, maxElevation) = updateLocationData()
//
//        data = await WorkoutUpdatorData(
//            avgHeartRate: avgHeartRate,
//            maxHeartRate: maxHeartRate,
//            energyBurned: energy,
//            trimp: trimp,
//            avgHeartRateReserve: heartRateReserve,
//            coordinates: coordinates,
//            minElevation: minElevation,
//            maxElevation: maxElevation
//        )
//
//        await generateImageData()
//    }
//
//}
//
//// MARK: - Heart Rate and Energy
//
//extension WorkoutUpdator {
//    typealias HeartRateReturn = (avg: Double?, max: Double?)
//
//    private func updateHeartRate() async -> HeartRateReturn {
//        if workout.avgHeartRate > 0 && workout.maxHeartRate > 0 {
//            Log.debug("UPDATE - ignore heart rate for \(identifier)")
//            return (nil, nil)
//        }
//
//        let avg: Double?
//        let max: Double?
//
//        do {
//            (avg, max) = try await provider.fetchHeartRateStats(for: remoteWorkout)
//        } catch {
//            Log.debug("failed to fetch heart rate samples for \(identifier): \(error.localizedDescription)")
//            avg = 0
//            max = 0
//        }
//
//        return (avg, max)
//    }
//
//    private func updateTotalEnergy() async -> Double? {
//        if workout.energyBurned > 0 {
//            Log.debug("UPDATE - ignore energy for \(identifier)")
//            return nil
//        }
//
//        let energy: Double?
//        do {
//            energy = try await provider.fetchActiveEnergy(for: remoteWorkout)
//        } catch {
//            Log.debug("UPDATE - failed energy for \(identifier)")
//            energy = remoteWorkout.totalCaloriesValue ?? remoteWorkout.totalEnergyBurnedValue
//        }
//        return energy
//    }
//
//}
//
//// MARK: - Effort
//
//extension WorkoutUpdator {
//
//    typealias TrainingLoadReturn = (trimp: Int, reserve: Double)
//
//    private func updateTrainingLoad() async -> TrainingLoadReturn {
//        do {
//            guard provider.isTrainingLoadSupported else {
//                throw WorkoutError("training load not supported")
//            }
//
//            let avgHeartRate: Double
//            if workout.avgHeartRate > 0 {
//                avgHeartRate = workout.avgHeartRate
//            } else {
//                do {
//                    avgHeartRate = try await provider.fetchAvgHeartRate(for: remoteWorkout)
//                } catch {
//                    avgHeartRate = remoteWorkout.avgHeartRateValue ?? 0
//                }
//            }
//
//            guard avgHeartRate > 0 else {
//                throw WorkoutError("missing avg heart rate")
//            }
//
//            let paddedSamples = try await provider.fetchPaddedHeartRateSamples(for: remoteWorkout)
//            let gender = provider.userGender()
//            let profileMaxHeartRate = await provider.profileMaxHeartRate()
//            let profileRestingHeartRate = await provider.profileRestingHeartRate()
//
//            let loadProcessor = TrainingLoadProcessor(
//                gender: gender,
//                maxHeartRate: profileMaxHeartRate,
//                restingHeartRate: profileRestingHeartRate,
//                paddedHeartRateSamples: paddedSamples
//            )
//
//            let trimp = loadProcessor.trimp()
//            let reserve = loadProcessor.percentHeartRateReserve(for: Int(avgHeartRate))
//
//            return (trimp, reserve)
//        } catch {
//            return (0, 0)
//        }
//    }
//
//}
//
//// MARK: - Location
//
//extension WorkoutUpdator {
//    typealias LocationReturn = (coordinates: [CLLocationCoordinate2D], min: Double?, max: Double?)
//
//    private func updateLocationData() async -> LocationReturn {
//        guard workout.hasLocationData else { return ([], nil, nil) }
//
//        let locations: [CLLocation]
//        do {
//            locations = try await provider.fetchLocations(for: remoteWorkout)
//        } catch {
//            locations = []
//        }
//
//        guard locations.isPresent else { return ([], nil, nil) }
//
//        var coordinates = [CLLocationCoordinate2D]()
//        var altitudes = [Double]()
//
//        if abs(workout.maxElevation) > 0 && abs(workout.maxElevation) > 0 {
//            coordinates = locations.map { $0.coordinate }
//        } else {
//            for location in locations {
//                coordinates.append(location.coordinate)
//                altitudes.append(location.altitude)
//            }
//        }
//
//        let min = altitudes.min()
//        let max = altitudes.max()
//
//        return (coordinates, min, max)
//    }
//
//    private func generateImageData() async {
//        guard workout.hasLocationData else { return }
//
//        let coordinates = data?.coordinates ?? [CLLocationCoordinate2D]()
//        do {
//            let darkData = try await MKMapView.workoutMapData(coordinates: coordinates, colorScheme: .dark)
//            let lightData = try await MKMapView.workoutMapData(coordinates: coordinates, colorScheme: .light)
//
//            try FileManager.writeWorkoutImageData(
//                dark: darkData,
//                light: lightData,
//                workout: workout.workoutIdentifier
//            )
//        } catch {
//            Log.debug("unable to generate images for \(workout.workoutIdentifier): \(error.localizedDescription)")
//        }
//    }
//
//}
