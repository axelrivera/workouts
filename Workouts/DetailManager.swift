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
    @Published var paceValues = [ChartInterval]()
    @Published var altitudeValues = [ChartInterval]()
    @Published var minElevation: Double = 0
    @Published var maxElevation: Double = 0
    @Published var showMap: Bool = false
    
    @Published var avgPace: Double = 0
    @Published var bestPace: Double = 0
    @Published var city: String?
    @Published var state: String?
    
    @Published var workout: Workout
    private var context: NSManagedObjectContext
    private var geocoder = CLGeocoder()
        
    init(workout: Workout) {
        self.workout = workout
        self.showMap = workout.showMap
        self.city = workout.locationCity
        self.state = workout.locationState
        self.context = workout.managedObjectContext!
    }
}

extension DetailManager {
    
    var locationName: String? {
        let strings: [String] = [city, state].compactMap{ $0 }
        if strings.isEmpty { return nil }
        return strings.joined(separator: ", ")
    }
    
    func run() {
        Log.debug("running samples - retries: \(workout.totalRetries)")
        
        if workout.shouldRegenerateSamples {
            Log.debug("regenerating samples")
            WorkoutDataStore.shared.fetchWorkout(for: workout.remoteIdentifier!) { [weak self] remoteWorkout in
                guard let self = self else { return }
                guard let remoteWorkout = remoteWorkout else {
                    self.context.perform {
                        self.updateValues(animated: false)
                    }
                    return
                }
                
                self.context.perform {
                    self.workout.updateSamples(remoteWorkout: remoteWorkout)
                    self.updateValues(animated: self.workout.showMap)
                }
            }
        } else {
            Log.debug("samples in place")
            
            context.perform { [weak self] in
                guard let self = self else { return }
                self.updateValues(animated: false)
            }
        }
    }
    
    private func updateValues(animated: Bool = true) {
        let samples = workout.samples.sorted(by: { $0.timestamp < $1.timestamp })
        
        let showMap = workout.showMap
        let locations = samples.filter({ $0.isLocation }).compactMap { $0.location }
        let points = locations.map { $0.coordinate }
        let altitude = locations.map { $0.altitude }
        let minElevation = altitude.min() ?? 0
        let maxElevation = altitude.max() ?? 0
        
        let movingSamples = samples.filter { sample in
            if workout.showMap {
                return sample.isActive && sample.speed > 0
            } else {
                return sample.isActive
            }
        }
        
        let heartRateValues = heartRateChartIntervals(for: movingSamples)
        let speedValues = speedChartIntervals(for: movingSamples)
        let cadenceValues = cadenceChartIntervals(for: movingSamples)
        let altitudeValues = altitudeChartIntervals(for: movingSamples)

        var avgPace: Double = 0
        if workout.sport.isWalkingOrRunning {
            let duration = workout.movingTime > 0 ? workout.movingTime : workout.duration
            let distance = workout.distance
            avgPace = calculateRunningWalkingPace(distanceInMeters: distance, duration: duration) ?? 0
        }
                    
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            withAnimation(animated ? .default : nil) {
                self.showMap = showMap
                self.points = points
                self.minElevation = minElevation
                self.maxElevation = maxElevation
                self.heartRateValues = heartRateValues
                self.speedValues = speedValues
                self.cyclingCadenceValues = cadenceValues
                self.altitudeValues = altitudeValues
                self.avgPace = avgPace
                
                if let location = locations.first, self.city == nil || self.state == nil {
                    self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                        if let placemark = placemarks?.first {
                            if let city = placemark.locality {
                                self.city = city
                                self.workout.locationCity = city
                            }

                            if let state = placemark.administrativeArea {
                                self.state = state
                                self.workout.locationState = state
                            }
                        }
                        
                        if self.context.hasChanges {
                            self.context.saveOrRollback()
                        }
                    }
                }
            }
        }
    }
    
    private var sampleInterval: Float {
        let movingTime = self.movingTime
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
    
    private var movingTime: Double {
        if workout.movingTime > 0 && workout.movingTime < workout.duration {
            return workout.movingTime
        }
        return workout.duration
    }
    
    private func interpolatedValues(for values: [Float], interval: Float? = nil) -> (xStep: Double, points: [Float]) {
        guard values.isPresent else { return (0, []) }

        let resampleInterval = interval ?? sampleInterval
        let points = LinearInterpolator(points: values).resample(interval: resampleInterval)
        let xStep = movingTime / Double(points.count)
        return (xStep, points)
    }
    
    private func heartRateChartIntervals(for movingSamples: [Sample]) -> [ChartInterval] {
        let heartRates = movingSamples.filter({ $0.heartRate > 0 }).map({ Float($0.heartRate) })
        let (xStep, samples) = interpolatedValues(for: heartRates)
        
        return samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue: Double(value))
        }
    }
    
    private func speedChartIntervals(for movingSamples: [Sample]) -> [ChartInterval] {
        guard workout.sport.isSpeedSport else { return [] }
        
        let (xStep, samples) = interpolatedValues(for: movingSamples.map({ Float($0.speed) }))
        
        return samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue: nativeSpeedToLocalizedUnit(for: Double(value)))
        }
    }
    
    private func cadenceChartIntervals(for movingSamples: [Sample]) -> [ChartInterval] {
        guard workout.sport.isCycling else { return [] }
        
        let (xStep, samples) = interpolatedValues(for: movingSamples.map({ Float($0.cyclingCadence) }))
        
        return samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue: Double(value))
        }
    }
    
    private func altitudeChartIntervals(for movingSamples: [Sample]) -> [ChartInterval] {
        let (xStep, samples) = interpolatedValues(for: movingSamples.map({ Float($0.altitude) }))
        
        return samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue: nativeAltitudeToLocalizedUnit(for: Double(value)))
        }
    }
    
    private func paceChartIntervals(for movingSamples: [Sample]) -> (best: Double, intervals: [ChartInterval]) {
        guard workout.sport.isWalkingOrRunning else { return (0, []) }
        
        let paces: [Float] = movingSamples.compactMap { sample in
            let duration = sample.paceDuration
            let distance = sample.paceDistance
            guard let value = calculateRunningWalkingPace(distanceInMeters: distance, duration: duration) else { return nil }
            return Float(value)
        }
        
        let (xStep, samples) = interpolatedValues(for: paces)

        let intervals: [ChartInterval] = samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue:  Double(value))
        }
        let best = paces.filter({ $0 > 0 }).min() ?? 0
        
        return (Double(best), intervals)
    }
    
}
