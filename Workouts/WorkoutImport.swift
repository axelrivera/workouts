//
//  WorkoutImport.swift
//  Workouts
//
//  Created by Axel Rivera on 1/18/21.
//

import SwiftUI
import CoreLocation
import FitFileParser
import HealthKit

extension WorkoutImport {
    enum Status {
        case new, duplicate, processing, processed, notSupported, failed, invalid, empty
    }
}

extension WorkoutImport.Status: Equatable, Identifiable, Hashable {
    
    var id: Self { self }
    
    var isValid: Bool {
        self != .empty
    }
    
    var title: String {
        switch self {
        case .new: return "New Workout"
        case .duplicate: return "Duplicate Workout"
        case .processing: return "Processing…"
        case .processed: return "Import Complete"
        case .notSupported: return "Sport Not Supported"
        case .failed: return "Import Failed"
        case .invalid: return "Invalid File"
        case .empty: return "Missing Workout"
        }
    }
    
    var color: Color {
        switch self {
        case .new: return .accentColor
        case .duplicate: return .orange
        case .processing: return .secondary
        case .processed: return .green
        case .notSupported, .failed, .invalid: return .red
        case .empty: return .secondary
        }
    }
    
    var imageName: String {
        switch self {
        case .new: return "flame.fill"
        case .duplicate: return "exclamationmark.circle"
        case .processing: return "hourglass"
        case .processed: return "checkmark.circle.fill"
        case .notSupported, .failed, .invalid: return "xmark.circle"
        case .empty: return "circle.slash"
        }
    }
    
}

class WorkoutImport: ObservableObject, Identifiable, Hashable {
    private(set) var id: String
    let uuidString = UUID().uuidString
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
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
    var minAltitude: Value = .init(valueType: .altitude, value: 0)
    var maxAltitude: Value = .init(valueType: .altitude, value: 0)
    
    var totalDistance: Value = .init(valueType: .distance, value: 0)
    var avgSpeed: Value = .init(valueType: .speed, value: 0)
    var maxSpeed: Value = .init(valueType: .speed, value: 0)
    
    var avgHeartRate: Value = .init(valueType: .heartRate, value: 0)
    var minHeartRate: Value = .init(valueType: .heartRate, value: 0)
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
    var locations = [CLLocation]()
    var coordinates = [CLLocationCoordinate2D]()
    
    var fileURL: URL?
    var fileName: String?
    
    init(status: Status, sport: Sport) {
        self.id = UUID().uuidString
        self.status = status
        self.sport = sport
    }
    
    init(invalidFilename: String) {
        self.id = UUID().uuidString
        self.status = .invalid
        self.fileName = invalidFilename
        self.sport = .other
        start = .init(valueType: .date, value: Date().timeIntervalSince1970)
    }
    
    init?(fitFile: FitFile) {
        guard let fileID = fitFile.messages(forMessageType: .file_id).first else { return nil }
        guard let sport = fitFile.messages(forMessageType: .sport).first else { return nil }
        guard let session = fitFile.messages(forMessageType: .session).first else { return nil }
        
        guard let date = fileID.interpretedField(key: "time_created")?.time else { return nil }
        self.id = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short).removingCharacters(in: .whitespacesAndNewlines).lowercased()
        Log.debug("initializing workout with id: \(self.id)")
        
        self.sport = Sport(string: sport.interpretedField(key: "sport")?.name ?? "")
        status = self.sport.isImportSupported ? .new : .notSupported
        indoor = Self.isIndoor(subsport: sport.interpretedField(key: "sub_sport")?.name ?? "")
                
        timestamp = .init(valueType: .date, field: session.interpretedField(key: "timestamp"))
        start = .init(valueType: .date, field: session.interpretedField(key: "start_time"))
        totalElapsedTime = .init(valueType: .time, field: session.interpretedField(key: "total_elapsed_time"))
        totalTimerTime = .init(valueType: .time, field: session.interpretedField(key: "total_timer_time"))
                
        startPosition = .init(valueType: .location, field: session.interpretedField(key: "start_position"))
        totalAscent = .init(valueType: .altitude, field: session.interpretedField(key: "total_ascent"))
        totalDescent = .init(valueType: .altitude, field: session.interpretedField(key: "total_descent"))
        minAltitude = .init(valueType: .altitude, field: session.interpretedField(key: "min_altitude"))
        maxAltitude = .init(valueType: .altitude, field: session.interpretedField(key: "max_altitude"))
        
        totalDistance = .init(valueType: .distance, field: session.interpretedField(key: "total_distance"))
        avgSpeed = .init(valueType: .speed, field: session.interpretedField(key: "avg_speed"))
        maxSpeed = .init(valueType: .speed, field: session.interpretedField(key: "max_speed"))
        
        avgHeartRate = .init(valueType: .heartRate, field: session.interpretedField(key: "avg_heart_rate"))
        minHeartRate = .init(valueType: .heartRate, field: session.interpretedField(key: "min_heart_rate"))
        maxHeartRate = .init(valueType: .heartRate, field: session.interpretedField(key: "max_heart_rate"))
        totalEnergyBurned = .init(valueType: .calories, field: session.interpretedField(key: "total_calories"))
        
        avgCadence = .init(valueType: .cadence, field: session.interpretedField(key: "avg_cadence"))
        avgFractionalCadence = .init(valueType: .cadence, field: session.interpretedField(key: "avg_fractional_cadence"))
        maxCadence = .init(valueType: .cadence, field: session.interpretedField(key: "max_cadence"))
        maxFractionalCadence = .init(valueType: .cadence, field: session.interpretedField(key: "max_fractional_cadence"))
        
        avgTemperature = .init(valueType: .temperature, field: session.interpretedField(key: "avg_temperature"))
        maxTemperature = .init(valueType: .temperature, field: session.interpretedField(key: "max_temperature"))
        
        // Records
        records = fitFile.messages(forMessageType: .record).compactMap { .init(message: $0) }
        locations = records.compactMap { $0.location }
        coordinates = locations.map { $0.coordinate }
        
        // Events
        events = fitFile.messages(forMessageType: .event).compactMap { (message) -> Event? in
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
    
    var filteredEvents: [Event] {
        let filtered = self.events
        let events = filtered.sorted { lhs, rhs in
            return lhs.timestamp < rhs.timestamp
        }
                
        let totalEvents = events.count
        var finalEvents = [Event]()
        
        for index in 0 ..< totalEvents {
            let event = events[index]
            
            if finalEvents.isEmpty && event.eventType == .resume { continue }
            if finalEvents.isEmpty && event.eventType == .pause {
                finalEvents.append(event)
                continue
            }
            
            guard let last = finalEvents.last else { continue }
            
            if last.eventType == .pause && event.eventType == .resume {
                finalEvents.append(event)
                continue
            }
            
            if last.eventType == .resume && event.eventType == .pause {
                finalEvents.append(event)
                continue
            }
        }
        
        if let last = finalEvents.last, last.eventType == .pause {
            finalEvents = finalEvents.dropLast()
        }
        
        // Clean bad events and colliding timestamps
        
        var cleanEvents = [Event]()
        var tuples = [(pause: Event, resume: Event)]()
        
        for (pause, resume) in zip(finalEvents, finalEvents.dropFirst()) {
            if pause.eventType == .pause && resume.eventType == .resume {
                tuples.append((pause, resume))
            }
        }
        
        for (prev, tuple) in zip(tuples, tuples.dropFirst()) {
            if tuple.pause.timestamp > prev.resume.timestamp {
                cleanEvents.append(tuple.pause)
                cleanEvents.append(tuple.resume)
            }
        }
                        
        return cleanEvents
    }
    
    var workoutEvents: [HKWorkoutEvent] {
        filteredEvents.map { $0.workoutEvent }
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
        return Sport(string: field.name ?? "").isImportSupported
    }
    
}

extension WorkoutImport: Equatable {
    
    static func == (lhs: WorkoutImport, rhs: WorkoutImport) -> Bool {
        lhs.id == rhs.id
    }
    
}
