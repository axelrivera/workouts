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
    struct Constants {
        static let baseSpeed: Double = 2.68 // This should be good for cycling but needs to be updated depending on sport
    }
    
    let workout: HKWorkout
    let locations: [CLLocation]
    let heartRateSamples: [Quantity]
    let cadenceSamples: [Quantity]
    let paceSamples: [Quantity]
    
    private(set) var records = [Record]()
    private(set) var movingTime: Double = 0
    
    private var dictionary = [Int: Record]()
    private var stoppedIntervals = [DateInterval]()
        
    lazy var baseSpeed: Double = {
        Constants.baseSpeed
    }()
    
    init(workout: HKWorkout, locations: [CLLocation], heartRateSamples: [Quantity], cadenceSamples: [Quantity], paceSamples: [Quantity]) {
        self.workout = workout
        self.locations = locations
        self.heartRateSamples = heartRateSamples
        self.cadenceSamples = cadenceSamples
        self.paceSamples = paceSamples
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
    
    static let validEvents: [HKWorkoutEventType] = [.pause, .resume]
    
    private func generateStoppedIntervals() {
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
        
        Log.debug("total duration: \(duration)")
        Log.debug("stopped: \(stoppedIntervals.map { $0.duration }.reduce(0, +))")
        Log.debug("events: \(events.count), intervals: \(stoppedIntervals.count)")
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
    }
    
    private func processLocationSamples() {
        guard isLocationSupported else { return }
        
        for location in locations {
            let key = keyForTimestamp(location.timestamp)
            guard let record = dictionary[key] else { continue }
            
            record.isLocation = true
            record.speed = location.speed
            record.latitude = location.coordinate.latitude
            record.longitude = location.coordinate.longitude
            record.altitude = location.altitude
        }

//        let sortedLocations = locations.sorted(by: { $0.timestamp < $1.timestamp })
//        for (prev, current) in zip(sortedLocations, sortedLocations.dropFirst()) {
//            let start = prev.timestamp
//            let end = current.timestamp
////            let intervalDuration = end.timeIntervalSince(start)
//
//            let key = keyForTimestamp(start)
//            guard let record = dictionary[key] else { continue }
//
//            record.isLocation = true
//            record.speed = current.speed
//            record.latitude = current.coordinate.latitude
//            record.longitude = current.coordinate.longitude
//            record.altitude = current.altitude
//
////            if intervalDuration > 0 {
////                let distance = current.distance(from: prev)
////                let speed = distance / intervalDuration
////                record.speed = speed
////            }
//            record.isActive = record.speed > 2.0
//        }
        
        movingTime = Double(records.filter({ $0.isActive }).count)
    }
    
    private func processHeartRateSamples() {
        guard heartRateSamples.isPresent else { return }
        
        for sample in heartRateSamples {
            let key = keyForTimestamp(sample.timestamp)
            guard let record = dictionary[key] else { continue }
            
            record.heartRate = max(record.heartRate, sample.value)
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
    
    private func processPaceSamples() {
        guard workout.workoutActivityType.isRunningWalking && paceSamples.isPresent else { return }
        
        for sample in paceSamples {
            let key = keyForTimestamp(sample.timestamp)
            guard let record = dictionary[key] else { continue }
            
            record.pace = max(record.pace, sample.value)
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
        var pace: Double = 0
        var temperature: Double = 0
        
        init(timestamp: Date) {
            self.timestamp = timestamp
        }
        
        var isEmpty: Bool {
            let sum = [latitude, longitude, speed, altitude, heartRate, cyclingCadence, pace, temperature].reduce(0, +)
            return sum == 0
        }
        
        var isPresent: Bool {
            !isEmpty
        }
    }
    
}
