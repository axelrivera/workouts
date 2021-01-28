//
//  WorkoutImport.swift
//  Workouts
//
//  Created by Axel Rivera on 1/18/21.
//

import Foundation
import CoreLocation
import FitFileParser

struct WorkoutImport {
    var timestamp: ImportValue
    var start: ImportValue
    var totalElapsedTime: ImportValue
    var totalTimerTime: ImportValue
    
    var startPosition: ImportValue
    var totalAscent: ImportValue
    var totalDescent: ImportValue
    
    var totalDistance: ImportValue
    var avgSpeed: ImportValue
    var maxSpeed: ImportValue
    
    var avgHeartRate: ImportValue
    var maxHeartRate: ImportValue
    var totalEnergyBurned: ImportValue
    
    var avgCadence: ImportValue
    var maxCadence: ImportValue
    
    var avgTemperature: ImportValue
    var maxTemperature: ImportValue
    
    var records = [ImportRecord]()
    
    init?(fit: FitFile) {
        guard let session = fit.messages(forMessageType: .session).first else { return nil }
        
        timestamp = ImportValue(valueType: .date, field: session.interpretedField(key: "timestamp"))
        start = ImportValue(valueType: .date, field: session.interpretedField(key: "start_time"))
        totalElapsedTime = ImportValue(valueType: .time, field: session.interpretedField(key: "total_elapsed_time"))
        totalTimerTime = ImportValue(valueType: .time, field: session.interpretedField(key: "total_timer_time"))
                
        startPosition = ImportValue(valueType: .location, field: session.interpretedField(key: "start_position"))
        totalAscent = ImportValue(valueType: .altitude, field: session.interpretedField(key: "total_ascent"))
        totalDescent = ImportValue(valueType: .altitude, field: session.interpretedField(key: "total_descent"))
        
        totalDistance = ImportValue(valueType: .distance, field: session.interpretedField(key: "total_distance"))
        avgSpeed = ImportValue(valueType: .speed, field: session.interpretedField(key: "avg_speed"))
        maxSpeed = ImportValue(valueType: .speed, field: session.interpretedField(key: "max_speed"))
        
        avgHeartRate = ImportValue(valueType: .heartRate, field: session.interpretedField(key: "avg_heart_rate"))
        maxHeartRate = ImportValue(valueType: .heartRate, field: session.interpretedField(key: "max_heart_rate"))
        totalEnergyBurned = ImportValue(valueType: .calories, field: session.interpretedField(key: "total_calories"))
        
        avgCadence = ImportValue(valueType: .cadence, field: session.interpretedField(key: "avg_cadence"))
        maxCadence = ImportValue(valueType: .cadence, field: session.interpretedField(key: "max_cadence"))
        
        avgTemperature = ImportValue(valueType: .temperature, field: session.interpretedField(key: "avg_temperature"))
        maxTemperature = ImportValue(valueType: .temperature, field: session.interpretedField(key: "max_temperature"))
        records = fit.messages(forMessageType: .record).map { ImportRecord(message: $0) }
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
    
    var intervals: [ImportInterval] {
        var intervals = [ImportInterval]()
        
        var prevRecord: ImportRecord?
        for record in records {
            if let startRecord = prevRecord {
                let interval = ImportInterval(start: startRecord, end: record)
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

struct ImportRecord {
    let timestamp: ImportValue
    let position: ImportValue
    let altitude: ImportValue
    let distance: ImportValue
    let speed: ImportValue
    let heartRate: ImportValue
    let cadence: ImportValue
    let temperature: ImportValue
    
    init(message: FitMessage) {
        timestamp = ImportValue(valueType: .date, field: message.interpretedField(key: "timestamp"))
        position = ImportValue(valueType: .location, field: message.interpretedField(key: "position"))
        altitude = ImportValue(valueType: .altitude, field: message.interpretedField(key: "altitude"))
        distance = ImportValue(valueType: .distance, field: message.interpretedField(key: "distance"))
        speed = ImportValue(valueType: .speed, field: message.interpretedField(key: "speed"))
        heartRate = ImportValue(valueType: .heartRate, field: message.interpretedField(key: "heart_rate"))
        cadence = ImportValue(valueType: .cadence, field: message.interpretedField(key: "cadence"))
        temperature = ImportValue(valueType: .temperature, field: message.interpretedField(key: "temperature"))
    }
}

struct ImportValue {
    enum ValueType {
        case date, time, location, altitude, distance, speed, heartRate, calories, cadence, temperature
    }
    
    let valueType: ValueType
    var value: Any?
    let unit: String
    
    init(valueType: ValueType, field: FitFieldValue?) {
        self.valueType = valueType
        
        switch valueType {
        case .date:
            value = field?.time?.timeIntervalSince1970
            unit = ""
        case .location:
            value = field?.coordinate
            unit = ""
        default:
            value = field?.valueUnit?.value
            unit = field?.valueUnit?.unit ?? ""
        }
    }
    
    var dateValue: Date? {
        guard let value = value as? Double, valueType == .date else { return nil }
        return Date(timeIntervalSince1970: value)
    }
    
    var timeValue: Double? {
        guard valueType == .time else { return nil }
        return value as? Double
    }
    
    var coordinateValue: CLLocationCoordinate2D? {
        guard valueType == .location else { return nil }
        return value as? CLLocationCoordinate2D
    }
    
    var altitudeValue: Double? {
        guard valueType == .altitude && unit == "m" else { return nil }
        return value as? Double
    }
    
    var distanceValue: Double? {
        guard valueType == .distance && unit == "m" else { return nil }
        return value as? Double
    }
    
    var speedValue: Double? {
        guard valueType == .speed && unit == "m/s" else { return nil }
        return value as? Double
    }
    
    var heartRateValue: Double? {
        guard valueType == .heartRate && unit == "bpm" else { return nil }
        return value as? Double
    }
    
    var caloriesValue: Double? {
        guard valueType == .calories && unit == "kcal" else { return nil }
        return value as? Double
    }
        
    var cadenceValue: Double? {
        guard valueType == .cadence && unit == "rpm" else { return nil }
        return value as? Double
    }
    
    var temperatureValue: Double? {
        guard valueType == .temperature && unit == "C" else { return nil }
        return value as? Double
    }
}

struct ImportInterval {
    let startRecord: ImportRecord
    let endRecord: ImportRecord
    
    init(start: ImportRecord, end: ImportRecord) {
        startRecord = start
        endRecord = end
    }
}

extension ImportInterval {
    
    var startDate: Date? {
        startRecord.timestamp.dateValue
    }
    
    var endDate: Date? {
        endRecord.timestamp.dateValue
    }
    
    var distance: Double? {
        guard let start = startRecord.position.coordinateValue, let end = endRecord.position.coordinateValue else { return nil }
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation)
    }
    
    var heartRate: Double? {
        guard let start = startRecord.heartRate.heartRateValue, let end = endRecord.heartRate.heartRateValue else { return nil }
        return (start + end) / 2.0
    }
    
    var duration: Double? {
        guard let start = startRecord.timestamp.dateValue, let end = endRecord.timestamp.dateValue else { return nil }
        return end.timeIntervalSince1970 - start.timeIntervalSince1970
    }
    
    var energyBurned: Double? {
        guard let duration = duration else { return 0 }
        
        let caloriesPerHour: Double = 450.0
        let hours: Double = duration / 3600.0
        return caloriesPerHour * hours
    }
    
}


