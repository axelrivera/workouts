//
//  DetailManager.swift
//  Workouts
//
//  Created by Axel Rivera on 1/28/21.
//

import Foundation
import MapKit
import SwiftUI
import HealthKit
import CoreData

class DetailManager: ObservableObject {
    let baseIntervalPoints : Int = 600
    
    @Published var points = [CLLocationCoordinate2D]()
    @Published var heartRateValues = [ChartInterval]()
    @Published var speedValues = [ChartInterval]()
    @Published var cyclingCadenceValues = [ChartInterval]()
    @Published var altitudeValues = [ChartInterval]()
    @Published var minElevation: Double = 0
    @Published var maxElevation: Double = 0
    
    @Published var zones = [HRZoneSummary]()
    @Published var zoneManager: HRZoneManager = HRZoneManager()
    
    @Published var detail = WorkoutDetail()
    @Published var isMapDisabled = false
    
    private var context: NSManagedObjectContext?
    private var _workout: Workout?
    
    var remoteIdentifier: UUID
            
    init(remoteIdentifier: UUID) {
        self.remoteIdentifier = remoteIdentifier
    }
}

extension DetailManager {
    
    var workout: Workout {
        if _workout == nil {
            _workout = Workout.find(using: remoteIdentifier, in: context!)
        }
        return _workout!
    }
    
    func loadWorkout(with context: NSManagedObjectContext) {
        self.context = context
        self.detail = WorkoutDetail(workout: workout)
        self.run()
    }
    
    func run() {
        guard let context = context else { return }
        
        context.perform { [weak self, unowned context] in
            guard let self = self else { return }
            let workout = self.workout
            
            if workout.shouldRegenerateSamples {
                WorkoutDataStore.shared.fetchWorkout(for: self.remoteIdentifier) { remoteWorkout in
                    guard let remoteWorkout = remoteWorkout else {
                        self.updateValues(workout: workout, context: context)
                        return
                    }
                    
                    Log.debug("updating samples")
                    workout.updateSamples(remoteWorkout: remoteWorkout)
                    self.updateValues(workout: workout, context: context)
                }
            } else {
                self.updateValues(workout: workout, context: context)
            }
        }
    }
    
    private func updateValues(workout: Workout, context: NSManagedObjectContext) {
        let detail = WorkoutDetail(workout: workout)
        let samples = workout.samples.sorted(by: { $0.timestamp < $1.timestamp })
        
        let locations = samples.filter({ $0.isLocation }).compactMap { $0.location }
        let points = locations.map { $0.coordinate }
        let altitude = locations.map { $0.altitude }
        let minElevation = altitude.min() ?? 0
        let maxElevation = altitude.max() ?? 0
        
        let movingSamples = samples.filter { sample in
            if locations.isPresent {
                return sample.isActive && sample.speed > 0
            } else {
                return sample.isActive
            }
        }
        
        let movingTime = workout.movingTime
        let heartRateValues = heartRateChartIntervals(for: movingSamples, movingTime: movingTime)
        let speedValues = speedChartIntervals(for: movingSamples, movingTime: movingTime)
        let cadenceValues = cadenceChartIntervals(for: movingSamples, movingTime: movingTime)
        let altitudeValues = altitudeChartIntervals(for: movingSamples, movingTime: movingTime)

        let zoneMaxHeartRate = workout.zoneMaxHeartRate
        let zoneValues = workout.zoneValues
        let zoneManager = HRZoneManager(maxHeartRate: zoneMaxHeartRate, zoneValues: zoneValues)
        
        var zones = [HRZoneSummary]()
        if heartRateValues.isPresent {
            zones = (try? zoneManager.fetchZones(for: workout)) ?? []
        }
                    
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.points = points
            self.detail = detail
            self.maxElevation = maxElevation
            self.heartRateValues = heartRateValues
            self.speedValues = speedValues
            self.cyclingCadenceValues = cadenceValues
            self.altitudeValues = altitudeValues
            self.zoneManager = zoneManager
            self.zones = zones
            self.minElevation = minElevation
            
            Log.debug("total points: \(points.count), showMap: \(workout.showMap)")
            
            withAnimation {
                self.isMapDisabled = detail.indoor || !workout.showMap
            }
        }
    }
    
    func updateZones(maxHeartRate: Int, values: [Int]) {
        guard let context = context else { return }
        let workout = self.workout
        
        context.perform { [weak self, unowned context] in
            guard let self = self else { return }
            
            let zoneManager = HRZoneManager(maxHeartRate: maxHeartRate, zoneValues: values)
            let zones = (try? self.zoneManager.fetchZones(for: workout)) ?? []
            workout.updateHeartRateZones(with: maxHeartRate, values: values)
            context.saveOrRollback()
            
            DispatchQueue.main.async {
                withAnimation {
                    self.zoneManager = zoneManager
                    self.zones = zones
                }
            }
        }
    }
    
    private func sampleInterval(movingTime: Double) -> Float {
        var intervalPoints: Float
        
        switch movingTime {
        case let x where x > 3600:
            intervalPoints = 500
        case let x where x > 1800:
            intervalPoints = 600
        default:
            intervalPoints = 1000
        }
        return Float(movingTime) / intervalPoints
    }
    
    private func interpolatedValues(for values: [Float], movingTime: Double) -> (xStep: Double, points: [Float]) {
        guard values.isPresent else { return (0, []) }

        let resampleInterval = sampleInterval(movingTime: movingTime)
        let points = LinearInterpolator(points: values).resample(interval: resampleInterval)
        let xStep = movingTime / Double(points.count)
        return (xStep, points)
    }
    
    private func heartRateChartIntervals(for movingSamples: [Sample], movingTime: Double) -> [ChartInterval] {
        let heartRates = movingSamples.filter({ $0.heartRate > 0 }).map({ Float($0.heartRate) })
        let (xStep, samples) = interpolatedValues(for: heartRates, movingTime: movingTime)
        
        return samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue: Double(value))
        }
    }
    
    private func speedChartIntervals(for movingSamples: [Sample], movingTime: Double) -> [ChartInterval] {
        guard detail.sport.isSpeedSport else { return [] }
        
        let (xStep, samples) = interpolatedValues(for: movingSamples.map({ Float($0.speed) }), movingTime: movingTime)
        
        return samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue: nativeSpeedToLocalizedUnit(for: Double(value)))
        }
    }
    
    private func cadenceChartIntervals(for movingSamples: [Sample], movingTime: Double) -> [ChartInterval] {
        guard detail.sport.isCycling else { return [] }
        
        let (xStep, samples) = interpolatedValues(for: movingSamples.map({ Float($0.cyclingCadence) }), movingTime: movingTime)
        
        return samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue: Double(value))
        }
    }
    
    private func altitudeChartIntervals(for movingSamples: [Sample], movingTime: Double) -> [ChartInterval] {
        let (xStep, samples) = interpolatedValues(for: movingSamples.map({ Float($0.altitude) }), movingTime: movingTime)
        
        return samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue: nativeAltitudeToLocalizedUnit(for: Double(value)))
        }
    }
    
    private func paceChartIntervals(for movingSamples: [Sample], movingTime: Double) -> (best: Double, intervals: [ChartInterval]) {
        guard detail.sport.isWalkingOrRunning else { return (0, []) }
        
        let paces: [Float] = movingSamples.compactMap { sample in
            let duration = sample.paceDuration
            let distance = sample.paceDistance
            guard let value = calculateRunningWalkingPace(distanceInMeters: distance, duration: duration) else { return nil }
            return Float(value)
        }
        
        let (xStep, samples) = interpolatedValues(for: paces, movingTime: movingTime)

        let intervals: [ChartInterval] = samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue:  Double(value))
        }
        let best = paces.filter({ $0 > 0 }).min() ?? 0
        
        return (Double(best), intervals)
    }
    
}
