//
//  WorkoutMetadata.swift
//  Workouts
//
//  Created by Axel Rivera on 1/29/21.
//

import Foundation
import HealthKit

protocol WorkoutMetadata {
    
    var avgTemperature: WorkoutImport.Value { get }
    var avgSpeed: WorkoutImport.Value { get }
    var maxSpeed: WorkoutImport.Value { get }
    var totalAscent: WorkoutImport.Value { get}
    var totalDescent: WorkoutImport.Value { get }
    var avgCadence: WorkoutImport.Value { get }
    var maxCadence: WorkoutImport.Value { get }
    
}

extension WorkoutMetadata {
    
    var avgTemperatureQuantity: HKQuantity? {
        HKQuantity.quantity(for: avgTemperature.temperatureValue, unit: .celcius())
    }
    
    var avgSpeedQuantity: HKQuantity? {
        HKQuantity.quantity(for: avgSpeed.speedValue, unit: .metersPerSecond())
    }
    
    var maxSpeedQuantity: HKQuantity? {
        HKQuantity.quantity(for: maxSpeed.speedValue, unit: .metersPerSecond())
    }
    
    var totalAscentQuantity: HKQuantity? {
        HKQuantity.quantity(for: totalAscent.altitudeValue, unit: .meter())
    }
    
    var totalDescentQuantity: HKQuantity? {
        HKQuantity.quantity(for: totalDescent.altitudeValue, unit: .meter())
    }
    
    var avgCadenceValue: Double? {
        avgCadence.cadenceValue
    }
    
    var maxCadenceValue: Double? {
        maxCadence.cadenceValue
    }
    
}

