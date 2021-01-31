//
//  ImportRecord.swift
//  Workouts
//
//  Created by Axel Rivera on 1/29/21.
//

import Foundation
import FitFileParser

extension WorkoutImport {
    
    struct Record {
        let timestamp: Value
        let position: Value
        let altitude: Value
        let distance: Value
        let speed: Value
        let heartRate: Value
        let cadence: Value
        let temperature: Value
        
        init(message: FitMessage) {
            timestamp = Value(valueType: .date, field: message.interpretedField(key: "timestamp"))
            position = Value(valueType: .location, field: message.interpretedField(key: "position"))
            altitude = Value(valueType: .altitude, field: message.interpretedField(key: "altitude"))
            distance = Value(valueType: .distance, field: message.interpretedField(key: "distance"))
            speed = Value(valueType: .speed, field: message.interpretedField(key: "speed"))
            heartRate = Value(valueType: .heartRate, field: message.interpretedField(key: "heart_rate"))
            cadence = Value(valueType: .cadence, field: message.interpretedField(key: "cadence"))
            temperature = Value(valueType: .temperature, field: message.interpretedField(key: "temperature"))
        }
    }
    
}
