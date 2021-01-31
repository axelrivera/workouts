//
//  WorkoutImport+Events.swift
//  Workouts
//
//  Created by Axel Rivera on 1/29/21.
//

import Foundation
import FitFileParser

extension WorkoutImport {
    
    struct Event {
        enum EventType {
            case pause, resume
            
            init?(name: String) {
                if Self.pauseKeys.contains(name) {
                    self = .pause
                } else if Self.pauseKeys.contains(name) {
                    self = .resume
                } else {
                    return nil
                }
            }
            
            static var pauseKeys = ["stop", "stop_all"]
            static var resumeKeys = ["start"]
        }
        
        var timestamp: Value
        var eventType: EventType
        
        init?(message: FitMessage) {
            guard let name = message.interpretedField(key: "event_type")?.name,
                  let eventType = EventType(name: name) else { return nil }
                        
            timestamp = .init(valueType: .date, field: message.interpretedField(key: "timestamp"))
            self.eventType = eventType
        }
    }
    
}
