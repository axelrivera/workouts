//
//  WorkoutImport+Value.swift
//  Workouts
//
//  Created by Axel Rivera on 1/29/21.
//

import Foundation
import FitFileParser
import CoreLocation

extension WorkoutImport {
    
    struct Value {
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
    
}
