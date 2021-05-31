//
//  WorkoutImport+Events.swift
//  Workouts
//
//  Created by Axel Rivera on 1/29/21.
//

import Foundation
import FitFileParser
import HealthKit

extension WorkoutImport.Event {
    
    public enum EventType {
        case pause, resume
        
        public init?(name: String) {
            if Self.pauseKeys.contains(name) {
                self = .pause
            } else if Self.resumeKeys.contains(name) {
                self = .resume
            } else {
                return nil
            }
        }
        
        public var workoutEventType: HKWorkoutEventType {
            switch self {
            case .pause:
                return .pause
            case .resume:
                return .resume
            }
        }
        
        static var pauseKeys = ["stop", "stop_all"]
        static var resumeKeys = ["start"]
    }
    
}

extension WorkoutImport {
    
    public struct Event {
        public var timestamp: Value
        public var eventType: EventType
        
        public init?(message: FitMessage) {
            guard let name = message.interpretedField(key: "event_type")?.name,
                  let eventType = EventType(name: name) else { return nil }
                        
            timestamp = .init(valueType: .date, field: message.interpretedField(key: "timestamp"))
            self.eventType = eventType
        }
    }
    
}

extension WorkoutImport.Event {
    
    var workoutEvent: HKWorkoutEvent? {
        guard let timestamp = timestamp.dateValue else { return nil }
        
        let interval = DateInterval(start: timestamp, end: timestamp)
        return HKWorkoutEvent(type: eventType.workoutEventType, dateInterval: interval, metadata: nil)
    }
    
}

