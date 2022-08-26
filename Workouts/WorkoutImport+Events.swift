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
    
    public enum EventType: String {
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
        public var timestamp: Date
        public var eventType: EventType
        
        public init?(message: FitMessage) {
            // ignore off course events because they break distance sample calculation
            if let event = message.interpretedField(key: "event")?.name, event == "off_course" {
                return nil
            }
            
            guard let name = message.interpretedField(key: "event_type")?.name,
                  let eventType = EventType(name: name) else { return nil }
                        
            let timestamp = Value(valueType: .date, field: message.interpretedField(key: "timestamp"))
            guard let date = timestamp.dateValue else { return nil }
            
            self.timestamp = date
            self.eventType = eventType
        }
    }
    
}

extension WorkoutImport.Event {
    
    var workoutEvent: HKWorkoutEvent {
        let interval = DateInterval(start: timestamp, end: timestamp)
        return HKWorkoutEvent(type: eventType.workoutEventType, dateInterval: interval, metadata: nil)
    }
    
}

extension WorkoutImport.Event: CustomStringConvertible {
    
    public var description: String {
        String("event: \(eventType.rawValue), timestamp: \(timestamp.timeIntervalSince1970)")
    }
    
}

