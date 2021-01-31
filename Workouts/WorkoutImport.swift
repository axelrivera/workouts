//
//  WorkoutImport.swift
//  Workouts
//
//  Created by Axel Rivera on 1/18/21.
//

import Foundation
import CoreLocation
import FitFileParser

struct WorkoutImport: WorkoutMetadata {
    var timestamp: Value
    var start: Value
    var totalElapsedTime: Value
    var totalTimerTime: Value
    
    var startPosition: Value
    var totalAscent: Value
    var totalDescent: Value
    
    var totalDistance: Value
    var avgSpeed: Value
    var maxSpeed: Value
    
    var avgHeartRate: Value
    var maxHeartRate: Value
    var totalEnergyBurned: Value
    
    var avgCadence: Value
    var maxCadence: Value
    
    var avgTemperature: Value
    var maxTemperature: Value
    
    var records = [Record]()
    var events = [Event]()
    
    init?(fit: FitFile) {
        guard let session = fit.messages(forMessageType: .session).first else { return nil }
        
        timestamp = .init(valueType: .date, field: session.interpretedField(key: "timestamp"))
        start = .init(valueType: .date, field: session.interpretedField(key: "start_time"))
        totalElapsedTime = .init(valueType: .time, field: session.interpretedField(key: "total_elapsed_time"))
        totalTimerTime = .init(valueType: .time, field: session.interpretedField(key: "total_timer_time"))
                
        startPosition = .init(valueType: .location, field: session.interpretedField(key: "start_position"))
        totalAscent = .init(valueType: .altitude, field: session.interpretedField(key: "total_ascent"))
        totalDescent = .init(valueType: .altitude, field: session.interpretedField(key: "total_descent"))
        
        totalDistance = .init(valueType: .distance, field: session.interpretedField(key: "total_distance"))
        avgSpeed = .init(valueType: .speed, field: session.interpretedField(key: "avg_speed"))
        maxSpeed = .init(valueType: .speed, field: session.interpretedField(key: "max_speed"))
        
        avgHeartRate = .init(valueType: .heartRate, field: session.interpretedField(key: "avg_heart_rate"))
        maxHeartRate = .init(valueType: .heartRate, field: session.interpretedField(key: "max_heart_rate"))
        totalEnergyBurned = .init(valueType: .calories, field: session.interpretedField(key: "total_calories"))
        
        avgCadence = .init(valueType: .cadence, field: session.interpretedField(key: "avg_cadence"))
        maxCadence = .init(valueType: .cadence, field: session.interpretedField(key: "max_cadence"))
        
        avgTemperature = .init(valueType: .temperature, field: session.interpretedField(key: "avg_temperature"))
        maxTemperature = .init(valueType: .temperature, field: session.interpretedField(key: "max_temperature"))
        
        // Records
        records = fit.messages(forMessageType: .record).map { .init(message: $0) }
        
        // Events
        events = fit.messages(forMessageType: .event).compactMap { (message) -> Event? in
            Event(message: message)
        }        
    }
}

extension WorkoutImport {
    
    var startDate: Date? {
        start.dateValue
    }
    
    var endDate: Date? {
        guard let startDate = startDate else { return nil }
        guard let duration = totalElapsedTime.timeValue else { return nil }
        return startDate.addingTimeInterval(duration)
    }
    
    var intervals: [Interval] {
        var intervals = [Interval]()
        
        var prevRecord: Record?
        for record in records {
            if let startRecord = prevRecord {
                let interval = Interval(start: startRecord, end: record)
                intervals.append(interval)
            }
            prevRecord = record
        }
        
        return intervals
    }
    
    var locations: [CLLocation] {
        records.compactMap { record in
            guard let coordinate = record.position.coordinateValue else { return nil }
            guard let timestamp = record.timestamp.dateValue else { return nil }
            let altitude = record.altitude.altitudeValue ?? 0.0
            let speed = record.speed.speedValue ?? 0.0
            
            return CLLocation(
                coordinate: coordinate,
                altitude: altitude,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                course: -1,
                speed: speed,
                timestamp: timestamp
            )
        }
    }
    
}
