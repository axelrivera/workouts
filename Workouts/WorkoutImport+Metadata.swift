//
//  WorkoutImport+Metadata.swift
//  Workouts
//
//  Created by Axel Rivera on 1/29/21.
//

import Foundation
import HealthKit

extension WorkoutImport {
    
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
    
    var avgMETQuantity: HKQuantity? {
        let unit = HKUnit(from: "kcal/(kg*hr)")
        return HKQuantity.quantity(for: avgMETValue, unit: unit)
    }
    
    var totalAvgCadenceValue: Double? {
        totalAvgCadence.cadenceValue
    }
    
    var totalMaxCadenceValue: Double? {
        totalMaxCadence.cadenceValue
    }
    
}

