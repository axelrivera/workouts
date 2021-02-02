//
//  WorkoutImport.swift
//  Workouts
//
//  Created by Axel Rivera on 1/18/21.
//

import Foundation
import CoreLocation
import FitFileParser

class WorkoutImport: ObservableObject, Identifiable, WorkoutMetadata {
    enum Status {
        case new, processing, processed, notSupported, failed
    }
    
    enum Sport: String {
        case cycling, running, walking, other
        
        init(string: String) {
            self = Sport(rawValue: string) ?? .other
        }
        
        var isSupported: Bool {
            Self.supportedSports.contains(self)
        }
        
        var title: String {
            switch self {
            case .cycling:
                return "Cycle"
            case .running:
                return "Run"
            case .walking:
                return "Walk"
            default:
                return "Generic Activity"
            }
        }
        
        static var supportedSports: [Sport] = [.cycling]
    }
    
    let id = UUID()
    
    @Published var status: Status
    
    var sport: Sport
    var indoor = false
    
    var timestamp: Value = .init(valueType: .date, value: 0)
    var start: Value = .init(valueType: .date, value: 0)
    var totalElapsedTime: Value = .init(valueType: .time, value: 0)
    var totalTimerTime: Value = .init(valueType: .time, value: 0)
    
    var startPosition: Value = .init(valueType: .location, value: nil)
    var totalAscent: Value = .init(valueType: .altitude, value: 0)
    var totalDescent: Value = .init(valueType: .altitude, value: 0)
    
    var totalDistance: Value = .init(valueType: .distance, value: 0)
    var avgSpeed: Value = .init(valueType: .speed, value: 0)
    var maxSpeed: Value = .init(valueType: .speed, value: 0)
    
    var avgHeartRate: Value = .init(valueType: .heartRate, value: 0)
    var maxHeartRate: Value = .init(valueType: .heartRate, value: 0)
    var totalEnergyBurned: Value = .init(valueType: .calories, value: 0)
    
    var avgCadence: Value = .init(valueType: .cadence, value: 0)
    var maxCadence: Value = .init(valueType: .cadence, value: 0)
    
    var avgTemperature: Value = .init(valueType: .temperature, value: 0)
    var maxTemperature: Value = .init(valueType: .temperature, value: 0)
    
    var records = [Record]()
    var events = [Event]()
    
    init(status: Status, sport: Sport) {
        self.status = status
        self.sport = sport
    }
    
    init?(fit: FitFile) {
        guard let sport = fit.messages(forMessageType: .sport).first else { return nil }
        guard let session = fit.messages(forMessageType: .session).first else { return nil }
        
        self.sport = Sport(string: sport.interpretedField(key: "sport")?.name ?? "")
        status = self.sport.isSupported ? .new : .notSupported
        indoor = Self.isIndoor(subsport: sport.interpretedField(key: "sub_sport")?.name ?? "")
        
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

// MARK: - Presentation

extension WorkoutImport {
    
    var formattedTitle: String {
        String(format: "%@ %@", indoor ? "Indoor" : "Outdoor", sport.title)
    }
    
    var formattedDistance: String {
        let distance = Measurement<UnitLength>(value: totalDistance.distanceValue ?? 0, unit: .meters)
        let distanceInMiles = distance.converted(to: .miles)
        let formatter = MeasurementFormatter()
        return formatter.string(from: distanceInMiles)
    }
    
    var formattedDate: String {
        guard let date = startDate else { return "" }
        
        if date.isWithinNumberOfDays(7) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(for: date) ?? ""
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(for: date) ?? ""
        }
    }
    
}

// MARK: - Helper Methods

extension WorkoutImport {
    
    private static let indoorSubsports = [
        "treadmill",
        "indoor_cycling",
        "indoor_walking",
        "indoor_running",
        "virtual_activity"
    ]
    
    static func isIndoor(subsport: String) -> Bool {
        indoorSubsports.contains(subsport)
    }
    
    static func isFileSupported(fit: FitFile) -> Bool {
        guard let field = fit.messages(forMessageType: .sport).first?.interpretedField(key: "sport") else { return false }
        return Sport(string: field.name ?? "").isSupported
    }
    
}

extension WorkoutImport: Equatable {
    
    static func == (lhs: WorkoutImport, rhs: WorkoutImport) -> Bool {
        lhs.id == rhs.id
    }
    
}
