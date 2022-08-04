//
//  WorkoutIntervalProcessor.swift
//  Workouts
//
//  Created by Axel Rivera on 8/9/21.
//

import HealthKit
import CoreLocation

class WorkoutIntervalProcessor {
    private(set) var workout: HKWorkout
    
    private var provider = HealthProvider.shared
    
    lazy var sport: Sport = {
        workout.workoutActivityType.sport()
    }()
    
    lazy var interval: DateInterval = {
        DateInterval(start: workout.startDate, end: workout.endDate)
    }()
    
    lazy var source: HKSource = {
        workout.sourceRevision.source
    }()
    
    init(workout: HKWorkout) {
        self.workout = workout
    }
    
    private func locations() async -> [CLLocation] {
        guard let locations = try? await provider.fetchLocations(for: workout) else { return [] }
        return locations
    }
    
    func intervalsForDistanceSamples(_ samples: [Quantity], lapDistance: Double?) async -> [WorkoutInterval] {
        let intervalDistance = lapDistance ?? sport.defaultDistanceValue
        
        var chunks = [[Quantity]]()
        var currentChunk = [Quantity]()
        var accumulatedDistance: Double = 0
        
        let totalSamples = samples.count
        for index in 0 ..< totalSamples {
            let current = samples[index]
            let distance = current.value
            
            if accumulatedDistance + distance > intervalDistance {
                chunks.append(currentChunk)
                accumulatedDistance = current.value
                currentChunk = [current]
            } else {
                accumulatedDistance += distance
                currentChunk.append(current)
            }
            
            let isLast = index == totalSamples - 1
            if isLast && !currentChunk.isEmpty {
                chunks.append(currentChunk)
            }
        }
                
        let locations = await self.locations()
        let heartRateSamples = (try? await provider.fetchMaxSamples(quantityType: .heartRate(), unit: .bpm(), interval: interval, source: source)) ?? []
        let cadenceSamples: [Quantity]
        if sport.isCycling {
            cadenceSamples = (try? await provider.fetchCyclingCadenceSamples(interval: interval)) ?? []
        } else {
            cadenceSamples = []
        }
        
        let sampleFilter = WorkoutSampleFilter(
            locations: locations,
            heartRateSamples: heartRateSamples,
            cadenceSamples: cadenceSamples
        )
        
        var intervalNumber = 1
        var intervals = [WorkoutInterval]()
        var totalDistance: Double = 0
        
        for chunk in chunks {
            guard let start = chunk.first?.start, let end = chunk.last?.end else { continue }
            
            let dateInterval = DateInterval(start: start, end: end)
            let distance = chunk.map({ $0.value }).reduce(0, +)
            totalDistance += distance
            
            let (partialLocations, partialHeartRateSamples, partialCadenceSamples) = await filteredSamples(filter: sampleFilter, interval: dateInterval)
            
            let interval = WorkoutInterval(number: intervalNumber, sport: sport, start: start, end: end)
            interval.cummulativeDistance = totalDistance
            interval.distance = distance
            
            let totalTime = dateInterval.duration
            let movingTime = chunk.map({ $0.duration }).reduce(0, +)
            
            let maxHeartRate = partialHeartRateSamples.maxValue()
            let avgHeartRate = partialHeartRateSamples.avgValue()
                        
            let maxCadence = partialCadenceSamples.maxValue()
            let avgCadence = partialCadenceSamples.avgValue(excludeZeros: true)
            
            let maxSpeed: Double
            let avgSpeed: Double
            
            if partialLocations.hasSpeedValues() {
                let values = partialLocations.speedValues()
                maxSpeed = values.max() ?? 0
                avgSpeed = values.reduce(0, +) / Double(values.count)
            } else {
                maxSpeed = movingTime > 0 ? distance / movingTime : 0
                avgSpeed = maxSpeed
            }
            
            let avgPace = calculateRunningWalkingPace(distanceInMeters: distance, duration: movingTime) ?? 0
            
            let altitudeValues = partialLocations.altitudeValues()
            let maxAltitude = altitudeValues.max() ?? 0
            
            interval.totalTime = totalTime
            interval.movingTime = movingTime
            interval.avgSpeed = avgSpeed
            interval.maxSpeed = maxSpeed
            interval.avgPace = avgPace
            interval.avgCadence = avgCadence
            interval.cadenceValues.append(contentsOf: partialCadenceSamples.quantityValues())
            interval.maxCadence = maxCadence
            interval.avgHeartRate = avgHeartRate
            interval.maxHeartRate = maxHeartRate
            interval.maxAltitude = maxAltitude
            
            intervals.append(interval)
            intervalNumber += 1
        }
        
        return intervals
    }
    
    func filteredSamples(filter: WorkoutSampleFilter, interval: DateInterval) async -> (location: [CLLocation], heartRate: [Quantity], cadence: [Quantity]) {
        async let partialLocations = filter.filterLocations(for: interval)
        async let partialHeartRateSamples = filter.filterHeartRateSamples(for: interval)
        async let partialCadencesamples = filter.filterCadenceSamples(for: interval)
        return (await partialLocations, await partialHeartRateSamples, await partialCadencesamples)
    }
    
}
