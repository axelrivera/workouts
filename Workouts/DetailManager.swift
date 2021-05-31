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
    @Published var showAnalysis = false
    @Published var points = [CLLocationCoordinate2D]()
    @Published var heartRateValues = [ChartInterval]()
    @Published var speedValues = [ChartInterval]()
    @Published var cyclingCadenceValues = [ChartInterval]()
    @Published var paceValues = [ChartInterval]()
    @Published var altitudeValues = [ChartInterval]()
    @Published var minElevation: Double = 0
    @Published var maxElevation: Double = 0
    
    private var workout: Workout
    private var context: NSManagedObjectContext
    
    init(workout: Workout, context: NSManagedObjectContext) {
        self.workout = workout
        self.context = context
    }
    
}

extension DetailManager {
    
    func run() {
        context.perform { [weak self] in
            guard let self = self else { return }
            let samples = self.workout.samples.sorted(by: { $0.timestamp < $1.timestamp })
            self.updateLocationValues(with: samples)
            self.updateValues(with: samples)
        }
    }
    
    private func updateLocationValues(with samples: [Sample]) {
        let locations = samples.filter({ $0.isLocation }).compactMap { $0.location }
        let points = locations.map { $0.coordinate }
        let altitude = locations.map { $0.altitude }
        
        DispatchQueue.main.async {
            self.points = points
            self.minElevation = altitude.min() ?? 0
            self.maxElevation = altitude.max() ?? 0
        }
    }
    
    private func updateValues(with samples: [Sample]) {
        let movingSamples = samples.filter { sample in
            if workout.showMap {
                return sample.isActive && sample.speed > 0
            } else {
                return sample.isActive
            }
        }
        
        let heartRateValues = self.heartRateChartIntervals(for: movingSamples)
        let speedValues = self.speedChartIntervals(for: movingSamples)
        let cadenceValues = self.cadenceChartIntervals(for: movingSamples)
        let altitudeValues = self.altitudeChartIntervals(for: movingSamples)
        
        DispatchQueue.main.async {
            self.heartRateValues = heartRateValues
            self.speedValues = speedValues
            self.cyclingCadenceValues = cadenceValues
            self.altitudeValues = altitudeValues
        }
    }
    
    private var sampleInterval: Float {
        Float(movingTime) / 150.0
    }
    
    private var movingTime: Double {
        guard workout.movingTime > 0 else {
            return workout.elapsedTime
        }
        return workout.movingTime
    }
    
    private func interpolatedValues(for values: [Float]) -> (xStep: Double, points: [Float]) {
        guard values.isPresent else { return (0, []) }

        let points = LinearInterpolator(points: values).resample(interval: sampleInterval)
        let xStep = movingTime / Double(points.count)
        return (xStep, points)
    }
    
    private func heartRateChartIntervals(for movingSamples: [Sample]) -> [ChartInterval] {
        let (xStep, samples) = interpolatedValues(for: movingSamples.map({ Float($0.heartRate) }))
        
        return samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue: Double(value))
        }
    }
    
    private func speedChartIntervals(for movingSamples: [Sample]) -> [ChartInterval] {
        let (xStep, samples) = interpolatedValues(for: movingSamples.map({ Float($0.speed) }))
        
        return samples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            return ChartInterval(xValue: xValue, yValue: nativeSpeedToLocalizedUnit(for: Double(value)))
        }
    }
    
    private func cadenceChartIntervals(for movingSamples: [Sample]) -> [ChartInterval] {
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
            return ChartInterval(xValue: xValue, yValue: Double(value))
        }
    }
    
}
