//
//  ImportRecord.swift
//  Workouts
//
//  Created by Axel Rivera on 1/29/21.
//

import Foundation
import FitFileParser
import CoreLocation

extension WorkoutImport {
    
    struct Record {
        let date: Date
        let timestamp: Value
        let position: Value
        let altitude: Value
        let distance: Value
        let speed: Value
        let heartRate: Value
        let cadence: Value
        let fractionalCadence: Value
        let temperature: Value
        
        init?(message: FitMessage) {
            guard let date = message.interpretedField(key: "timestamp")?.time else { return nil }
            
            self.date = date
            timestamp = Value(valueType: .date, field: message.interpretedField(key: "timestamp"))
            position = Value(valueType: .location, field: message.interpretedField(key: "position"))
            altitude = Value(valueType: .altitude, field: message.interpretedField(key: "altitude"))
            distance = Value(valueType: .distance, field: message.interpretedField(key: "distance"))
            speed = Value(valueType: .speed, field: message.interpretedField(key: "speed"))
            heartRate = Value(valueType: .heartRate, field: message.interpretedField(key: "heart_rate"))
            cadence = Value(valueType: .cadence, field: message.interpretedField(key: "cadence"))
            fractionalCadence = Value(valueType: .cadence, field: message.interpretedField(key: "fractional_cadence"))
            temperature = Value(valueType: .temperature, field: message.interpretedField(key: "temperature"))
        }
        
        var totalCadence: Value {
            Value.totalCadence(for: cadence, fractional: fractionalCadence)
        }
        
        var location: CLLocation? {
            guard let coordinate = position.coordinateValue else { return nil }
            guard let timestamp = timestamp.dateValue else { return nil }
            let altitude = self.altitude.altitudeValue ?? 0.0
            let speed = self.speed.speedValue ?? 0.0
            
            return CLLocation(
                coordinate: coordinate,
                altitude: altitude,
                horizontalAccuracy: -1,
                verticalAccuracy: -1,
                course: -1,
                speed: speed,
                timestamp: timestamp
            )
        }
        
    }
    
}
