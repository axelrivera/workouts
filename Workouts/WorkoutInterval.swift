//
//  WorkoutInterval.swift
//  Workouts
//
//  Created by Axel Rivera on 8/9/21.
//

import Foundation
import CoreLocation

typealias ChartIntervalArray = [ChartInterval]
typealias WorkoutChartIntervals = (speed: ChartIntervalArray, heartRate: ChartIntervalArray,
                                   cadence: ChartIntervalArray, pace: ChartIntervalArray,
                                   elevation: ChartIntervalArray)

final class WorkoutInterval: Identifiable {
    var id: Int { number }
    
    let number: Int
    let sport: Sport
    let start: Date
    let end: Date
    
    var distance: Double = 0
    var cummulativeDistance: Double = 0
    var movingTime: Double = 0
    var avgSpeed: Double = 0
    var maxSpeed: Double = 0
    var avgPace: Double = 0
    var avgCadence: Double = 0
    var maxCadence: Double = 0
    var cadenceValues = [Double]()
    var avgHeartRate: Double = 0
    var maxHeartRate: Double = 0
    var maxAltitude: Double?
        
    init(number: Int, sport: Sport, start: Date, end: Date) {
        self.number = number
        self.sport = sport
        self.start = start
        self.end = end
    }
}

extension WorkoutInterval {
    
//    var interval: DateInterval { DateInterval(start: start, end: end) }
    var duration: Double { end.timeIntervalSince(start) }
    
}

extension WorkoutInterval: Equatable, Hashable {
    
    static func == (lhs: WorkoutInterval, rhs: WorkoutInterval) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

extension Sequence where Iterator.Element: WorkoutInterval {
    
    func movingTime() -> Double {
        ceil(map({ $0.movingTime }).reduce(0, +))
    }
    
    func doubleValues(keyPath key: KeyPath<Element, Double>) -> [Double] {
        map { $0[keyPath: key] }
    }
    
    func floatValues(keyPath key: KeyPath<Element, Double>) -> [Float] {
        map { Float($0[keyPath: key]) }
    }
    
    func cadenceValues(avgCadence: Double) -> [Double] {
        var samples = [Double]()
        
        for interval in self {
            let set = Set(interval.cadenceValues)
            samples.append(contentsOf: set)
        }
        return samples
    }
    
    func chartIntervals(avgCadence: Double) -> WorkoutChartIntervals {
        let speed = floatValues(keyPath: \.maxSpeed)
        let heartRate = floatValues(keyPath: \.maxHeartRate).compactMap({ $0 > 0 ? $0 : nil })
        let cadence = cadenceValues(avgCadence: avgCadence)
        let pace = floatValues(keyPath: \.avgPace)
        let altitude = compactMap { interval -> Float? in
            guard let altitude = interval.maxAltitude else { return nil }
            return Float(altitude)
        }
                
        let duration = movingTime()
        let speedChart = intervals(samples: speed, movingTime: duration, valueType: .speed)
        let heartRateChart = intervals(samples: heartRate, movingTime: duration, valueType: .heartRate)
        let cadenceChart = cadenceIntervals(samples: cadence, movingTime: duration)
        let paceChart = intervals(samples: pace, movingTime: duration, valueType: .pace)
        let altitudeChart = intervals(samples: altitude, movingTime: duration, valueType: .altitude)
                
        return (speedChart, heartRateChart, cadenceChart, paceChart, altitudeChart)
    }
    
    private func cadenceIntervals(samples: [Double], movingTime: Double) -> [ChartInterval] {
        let interval: Double = 2.0
        let count = Int(floor(Double(samples.count) / interval))
        let xStep = movingTime / Double(count)
        
        return Array(0 ..< count).compactMap { index -> ChartInterval? in
            let step = index * Int(interval)
            guard step < count else { return nil }
            
            let value = samples[step]
            let xValue = Double(step) * xStep
            
            return ChartInterval(xValue: xValue, yValue: value)
        }
    }
    
    private func intervals(samples: [Float], movingTime: Double, valueType: ChartInterval.ValueType) -> [ChartInterval] {
        let (xStep, interpolatedSamples) = interpolatedValues(for: samples, movingTime: movingTime)
        
        return interpolatedSamples.enumerated().map { index, value in
            let xValue = Double(index) * xStep
            
            let doubleValue = Double(value)
            var yValue: Double
            
            switch valueType {
            case .speed:
                yValue = nativeSpeedToLocalizedUnit(for: doubleValue)
            case .altitude:
                yValue = nativeAltitudeToLocalizedUnit(for: doubleValue)
            default:
                yValue = doubleValue
            }
            
            return ChartInterval(xValue: xValue, yValue: yValue)
        }
    }
    
    private func interpolatedValues(for values: [(Float)], movingTime: Double) -> (xStep: Double, points: [Float]) {
        guard values.isPresent else { return (0, []) }

        let hour: Double = 60 * 60
        let movingTimeInHours = ceil(movingTime / hour)
        let resampleInterval = Float(movingTimeInHours) // divide moving time for every hour
        
        let points = LinearInterpolator(points: values).resample(interval: resampleInterval)
        let xStep = movingTime / Double(points.count)
        return (xStep, points)
    }
    
}
