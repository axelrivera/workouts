//
//  WorkoutLap.swift
//  Workouts
//
//  Created by Axel Rivera on 8/8/21.
//

import Foundation
import CoreLocation

// On UI show Duration, Avg Heart Rate, Pace/Cadence

struct WorkoutLap: Identifiable, Equatable, Hashable {
    var id: Int { lapNumber }
    
    let sport: Sport
    let lapNumber: Int
    let distance: Double
    let duration: Double
    let avgSpeed: Double
    let avgPace: Double
    let avgCadence: Double
    let avgHeartRate: Double
    let maxHeartRate: Double
}

extension Sample {
    
    func distance(from: Sample) -> Double {
        guard let location = location, let fromLocation = from.location else { return 0 }
        return abs(fromLocation.distance(from: location))
    }
    
}

extension Workout {
    
    func intervals(for lapDistance: Double) -> [DateInterval] {
        let locations = samples.locations()
        
        var chunks = [[CLLocation]]()
        var currentChunk = [CLLocation]()
        var accumulatedDistance: Double = 0
        
        if let first = locations.first {
            currentChunk.append(first)
        }
        
        for (prev, current) in zip(locations, locations.dropFirst()) {
            let distance = prev.distance(from: current)
            accumulatedDistance += distance
            
            if accumulatedDistance > lapDistance {
                chunks.append(currentChunk)
                accumulatedDistance = 0
                currentChunk = [current]
            } else {
                currentChunk.append(current)
            }
        }
        
        if locations.count > 1 && currentChunk.isPresent {
            chunks.append(currentChunk)
        }
        
        let intervals: [DateInterval] = chunks.compactMap { (chunk) -> DateInterval? in
            guard let start = chunk.first?.timestamp, let end = chunk.last?.timestamp else { return nil }
            return DateInterval(start: start, end: end)
        }
        return intervals
    }
    
}

extension Sequence where Iterator.Element: Sample {
    
    func sortedSamples() -> [Sample] {
        sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    func activeSamples() -> [Sample] {
        sortedSamples().filter({ $0.isActive })
    }
    
    func locations() -> [CLLocation] {
        let locations = compactMap({ $0.isLocation ? $0.location : nil })
        return locations.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    func duration(active: Bool = true) -> Double {
        let samples = active ? activeSamples() : sortedSamples()
        return Double(samples.count)
    }
    
    func distance() -> Double {
        locations().totalDistance
    }
    
    func avgHeartRate() -> Double {
        let values = activeSamples().map({ $0.heartRate })
        let totalValues = values.count
        guard totalValues > 0 else { return 0 }
        let sum = values.reduce(0, +)
        return sum / Double(totalValues)
    }
    
    func maxHeartRate() -> Double {
        let values = activeSamples().map({ $0.heartRate })
        return values.max() ?? 0
    }
    
    func avgSpeed() -> Double {
        let duration = duration()
        let distance = distance()
        guard duration > 0 else { return 0 }
        return distance / duration
    }
    
    func avgPace() -> Double {
        let duration = duration()
        let distance = distance()
        guard duration > 0 else { return 0 }
        return calculateRunningWalkingPace(distanceInMeters: distance, duration: duration) ?? 0
    }
    
    func avgCyclingCadence() -> Double {
        let values = activeSamples().compactMap({ $0.cyclingCadence > 0 ? $0.cyclingCadence : nil })
        let totalValues = values.count
        guard totalValues > 0 else { return 0 }
        let sum = values.reduce(0, +)
        return sum / Double(totalValues)
    }
    
}
