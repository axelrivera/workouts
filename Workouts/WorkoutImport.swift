//
//  WorkoutImport.swift
//  Workouts
//
//  Created by Axel Rivera on 1/18/21.
//

import Foundation
import CoreLocation
import FitFileParser
import HealthKit

class WorkoutImport: ObservableObject, Identifiable {
    enum Status {
        case new, processing, processed, notSupported, failed
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
    var avgFractionalCadence: Value = .init(valueType: .cadence, value: 0)
    var maxCadence: Value = .init(valueType: .cadence, value: 0)
    var maxFractionalCadence: Value = .init(valueType: .cadence, value: 0)
    
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
        avgFractionalCadence = .init(valueType: .cadence, field: session.interpretedField(key: "avg_fractional_cadence"))
        maxCadence = .init(valueType: .cadence, field: session.interpretedField(key: "max_cadence"))
        maxFractionalCadence = .init(valueType: .cadence, field: session.interpretedField(key: "max_fractional_cadence"))
        
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
    
    var totalAvgCadence: Value {
        Value.totalCadence(for: avgCadence, fractional: avgFractionalCadence)
    }
    
    var totalMaxCadence: Value {
        Value.totalCadence(for: maxCadence, fractional: maxFractionalCadence)
    }
    
    var avgMETValue: Double? {
        let values = records.compactMap { record -> Double? in
            guard let speed = record.speed.speedValue else { return nil }
            return metValueFor(sport: sport, indoor: indoor, speed: speed)
        }
        if values.isEmpty { return nil }
        
        let sum = values.reduce(0, +)
        return sum / Double(values.count)
    }
    
    var endDate: Date? {
        guard let startDate = startDate else { return nil }
        guard let duration = totalElapsedTime.timeValue else { return nil }
        return startDate.addingTimeInterval(duration)
    }
    
    var locations: [CLLocation] {
        records.compactMap { $0.location }
    }
    
}

// MARK: - Presentation

extension WorkoutImport {
    
    var formattedTitle: String {
        String(format: "%@ %@", indoor ? "Indoor" : "Outdoor", sport.name)
    }
    
}

// MARK: - Helper Methods

extension WorkoutImport {
    
    var activityType: HKWorkoutActivityType {
        switch sport {
        case .cycling:
            return .cycling
        case .running:
            return .running
        case .walking:
            return .walking
        default:
            return .other
        }
    }
    
    var locationType: HKWorkoutSessionLocationType {
        indoor ? .indoor : .outdoor
    }
    
    var lapLength: HKQuantity? {
        var distance: Double?
        switch sport {
        case .running, .walking:
            distance = 1.0
        case .cycling:
            distance = 5.0
        default:
            break
        }
        
        guard let value = distance else { return nil }
        return HKQuantity(unit: .mile(), doubleValue: value)
    }
    
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
