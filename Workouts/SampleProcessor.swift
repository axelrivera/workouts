//
//  SampleProcessor.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import Foundation
import CoreLocation
import HealthKit

class SampleProcessor {
    let workout: HKWorkout
    let locations: [CLLocation]
    let heartRateSamples: [Quantity]
    let cadenceSamples: [Quantity]
    
    private(set) var sampleMaxSpeed: Double = 0
    private(set) var avgMovingSpeed: Double = 0
    private(set) var records = [Record]()
    private(set) var movingTime: Double = 0
    
    private var dictionary = [Int: Record]()
    private var stoppedIntervals = [DateInterval]()
    
    init(workout: HKWorkout, locations: [CLLocation], heartRateSamples: [Quantity], cadenceSamples: [Quantity]) {
        self.workout = workout
        self.locations = locations.sorted(by: { $0.timestamp < $1.timestamp })
        self.heartRateSamples = heartRateSamples
        self.cadenceSamples = cadenceSamples
    }
    
    var start: Date {
        workout.startDate
    }
    
    var end: Date {
        workout.endDate
    }
    
    var validRecords: [Record] {
        records.filter({ $0.isPresent })
    }
    
}

extension SampleProcessor {
    
    func process() {
        generateStoppedIntervals()
        generateRecords()
        processSamples()
    }
    
    var duration: Double {
        end.timeIntervalSince(start)
    }
    
    var isLocationSupported: Bool {
        locations.isPresent
    }
    
    var workoutEvents: [HKWorkoutEvent] {
        workout.workoutEvents ?? [HKWorkoutEvent]()
    }
    
    var hasSystemEvents: Bool {
        workoutEvents.isPresent
    }
    
    static let validEvents: [HKWorkoutEventType] = [.pause, .resume]
    
    private func generateStoppedIntervals() {
        if hasSystemEvents {
            generateSystemEventIntervals()
        } else {
            generateManualEventIntervals()
        }
    }
    
    private func generateSystemEventIntervals() {
        let events = workout.workoutEvents ?? [HKWorkoutEvent]()
        let sortedEvents = events.sorted(by: { $0.dateInterval.start < $1.dateInterval.start })
        
        var pauseEvent: HKWorkoutEvent?
        
        for event in sortedEvents {
            guard Self.validEvents.contains(event.type) else { continue }
            
            if event.type == .pause && pauseEvent == nil {
                pauseEvent = event
                continue
            }
            
            if event.type == .pause && pauseEvent != nil { continue }
            
            if let pause = pauseEvent, event.type == .resume {
                let interval = DateInterval(start: pause.dateInterval.start, end: event.dateInterval.start)
                stoppedIntervals.append(interval)
                pauseEvent = nil
            }
        }
    }
    
    func totalDistance() -> Double {
        workout.totalDistance?.doubleValue(for: .meter()) ?? 0
    }
    
    func avgSpeed() -> Double {
        if let speed = workout.avgSpeed?.doubleValue(for: .metersPerSecond()) {
            return speed
        }
        
        guard workout.duration > 0 else { return 0 }
        let distance = totalDistance()
        return distance / workout.duration
    }
    
    func maxSpeed() -> Double {
        if let speed = workout.maxSpeed?.doubleValue(for: .metersPerSecond()) {
            return speed
        }
        return sampleMaxSpeed
    }
    
    func avgPace() -> Double {
        let sport = workout.workoutActivityType.sport()
        guard sport.isWalkingOrRunning else { return 0 }
        
        let duration = movingTime
        let distance = totalDistance()
        return calculateRunningWalkingPace(distanceInMeters: distance, duration: duration) ?? 0
    }
    
    private func generateManualEventIntervals() {
        let speed = avgSpeed()
        let baseDistance = max(speed * 0.25, 1.0)
        
        var pauseTimestamp: Date?
        
        for (prev, current) in zip(locations, locations.dropFirst()) {
            let distance = current.distance(from: prev)
                        
            if distance <= baseDistance && pauseTimestamp == nil {
                pauseTimestamp = current.timestamp
                continue
            }
            
            if distance <= baseDistance && pauseTimestamp != nil { continue }
            
            if let pause = pauseTimestamp, distance > baseDistance {
                let interval = DateInterval(start: pause, end: current.timestamp)
                
                if interval.duration > 1.0 {
                    stoppedIntervals.append(interval)
                }
                pauseTimestamp = nil
            }
        }
        
        if let pause = pauseTimestamp, let last = locations.last?.timestamp {
            let interval = DateInterval(start: pause, end: last)
            if interval.duration > 0.0 {
                stoppedIntervals.append(interval)
            }
        }
    }
    
    private func isTimestampActive(_ timestamp: Date) -> Bool {
        guard stoppedIntervals.isPresent else { return true }
        
        var stopped = false
        for interval in stoppedIntervals {
            if timestamp.isBetween(date: interval.start, andDate: interval.end) {
                stopped = true
                break
            }
        }
        return !stopped
    }
    
    private func generateRecords() {
        guard duration >= 0 else {
            assertionFailure("negative duration not supported")
            return
        }
        
        let startIndex = keyForTimestamp(start)
        let endIndex = keyForTimestamp(end)
        
        for key in startIndex ... endIndex {
            let timestamp = Date(timeIntervalSince1970: Double(key))
            let record = Record(timestamp: timestamp)
            record.isActive = isTimestampActive(timestamp)
            records.append(record)
            dictionary[key] = record
        }
    }
    
    func keyForTimestamp(_ timestamp: Date) -> Int {
        Int(truncating: timestamp.timeIntervalSince1970 as NSNumber)
    }
    
    private func processSamples() {
        processLocationSamples()
        processHeartRateSamples()
        processCadenceSamples()
        
        if locations.isPresent {
            movingTime = Double(records.filter({ $0.isActive }).count)
        }
        
        if movingTime == 0 {
            movingTime = duration
        }
        
        let distance = totalDistance()
        avgMovingSpeed = distance / movingTime
    }
    
    private func processLocationSamples() {
        guard isLocationSupported else { return }
        
        Log.debug("LOCATION - id: \(workout.uuid)")
        Log.debug("LOCATION - before: \(metersToMiles(for: locations.totalDistance))")
        
        for location in locations {
            let key = keyForTimestamp(location.timestamp)
            guard let record = dictionary[key] else { continue }
            
            record.isLocation = true
            record.speed = location.speed
            record.latitude = location.coordinate.latitude
            record.longitude = location.coordinate.longitude
            record.altitude = location.altitude
            
            sampleMaxSpeed = max(sampleMaxSpeed, location.speed)
        }
        
        let recordLocations = records.compactMap({ $0.isLocation ? CLLocation(latitude: $0.latitude, longitude: $0.longitude) : nil })
        Log.debug("LOCATION - after: \(metersToMiles(for: recordLocations.totalDistance))")
    }
    
    private func processHeartRateSamples() {
        guard heartRateSamples.isPresent else { return }
        
        for sample in heartRateSamples {
            let key = keyForTimestamp(sample.timestamp)
            guard let record = dictionary[key] else { continue }
            record.heartRate = max(record.heartRate, sample.value)
        }
        
        // padding
        
        var heartRate: Double = 0
        for record in records {
            if record.heartRate == 0 && heartRate > 0 {
                record.heartRate = heartRate
            }
            heartRate = record.heartRate
        }
    }
    
    private func processCadenceSamples() {
        guard workout.workoutActivityType.isCycling && cadenceSamples.isPresent else { return }
        
        for sample in cadenceSamples {
            let key = keyForTimestamp(sample.timestamp)
            guard let record = dictionary[key] else { continue }
            
            record.cyclingCadence = max(record.cyclingCadence, sample.value)
        }
    }
    
}

extension SampleProcessor {
    
    final class Record {
        var timestamp: Date
        var isActive = false
        var isLocation = false
        var latitude: Double = 0
        var longitude: Double = 0
        var speed: Double = 0
        var altitude: Double = 0
        var heartRate: Double = 0
        var cyclingCadence: Double = 0
        var temperature: Double = 0
        
        init(timestamp: Date) {
            self.timestamp = timestamp
        }
        
        var isEmpty: Bool {
            if isLocation { return false }
            
            let sum = [
                speed,
                altitude,
                heartRate,
                cyclingCadence,
                temperature
            ].reduce(0, +)
            return sum == 0
        }
        
        var isPresent: Bool {
            !isEmpty
        }
    }
    
}
