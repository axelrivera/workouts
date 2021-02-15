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
            
            var unit: String {
                switch self {
                case .altitude, .distance:
                    return "m"
                case .speed:
                    return "m/s"
                case .heartRate:
                    return "bpm"
                case .calories:
                    return "kcal"
                case .cadence:
                    return "rpm"
                case .temperature:
                    return "C"
                default:
                    return ""
                }
            }
            
            static func unit(for valueType: ValueType) -> String {
                valueType.unit
            }
        }
        
        let valueType: ValueType
        var value: Any?
        let unit: String
        
        init(valueType: ValueType, value: Any?) {
            self.valueType = valueType
            unit = ValueType.unit(for: valueType)
            self.value = value
        }
        
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
            guard valueType == .altitude && unit == ValueType.unit(for: .altitude) else { return nil }
            return value as? Double
        }
        
        var distanceValue: Double? {
            guard valueType == .distance && unit == ValueType.unit(for: .distance) else { return nil }
            return value as? Double
        }
        
        var speedValue: Double? {
            guard valueType == .speed && unit == ValueType.unit(for: .speed) else { return nil }
            return value as? Double
        }
        
        var heartRateValue: Double? {
            guard valueType == .heartRate && unit == ValueType.unit(for: .heartRate) else { return nil }
            return value as? Double
        }
        
        var caloriesValue: Double? {
            guard valueType == .calories && unit == ValueType.unit(for: .calories) else { return nil }
            return value as? Double
        }
            
        var cadenceValue: Double? {
            guard valueType == .cadence && unit == ValueType.unit(for: .cadence) else { return nil }
            return value as? Double
        }
        
        var temperatureValue: Double? {
            guard valueType == .temperature && unit == ValueType.unit(for: .temperature) else { return nil }
            return value as? Double
        }
        
        static func totalCadence(for cadence: Value, fractional: Value) -> Value {
            let cadenceValue = cadence.cadenceValue ?? 0
            let fractionalValue = fractional.cadenceValue ?? 0
            return Value(valueType: .cadence, value: cadenceValue + fractionalValue)
        }
    }
    
}
