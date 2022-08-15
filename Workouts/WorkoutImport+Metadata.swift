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
    
    var maxTemperatureValue: Double? {
        maxTemperature.temperatureValue
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
    
    var totalTimerTimeValue: Double? {
        totalTimerTime.timeValue
    }
    
    var totalElapsedTimeValue: Double? {
        totalElapsedTime.timeValue
    }
    
    var pausedTimeValue: Double? {
        guard let total = totalElapsedTimeValue, let moving = totalTimerTimeValue  else {
            return nil
        }
        return total - moving
    }
    
    var showMap: Bool {
        sport.hasDistanceSamples && !indoor
    }
    
    var formattedTitle: String {
        if case .invalid = status, let fileName = fileName {
            return fileName
        } else {
            return String(format: "%@ %@", indoor ? "Indoor" : "Outdoor", sport.name)
        }
    }
    
    var distanceValue: Double? {
        totalDistance.distanceValue
    }
    
    var elevationGainValue: Double? {
        totalAscent.altitudeValue
    }
    
    var avgHeartRateValue: Double? {
        avgHeartRate.heartRateValue
    }
    
    var minHeartRateValue: Double? {
        minHeartRate.heartRateValue
    }
    
    var maxHeartRateValue: Double? {
        maxHeartRate.heartRateValue
    }
    
    var startLatitudeValue: Double? {
        startPosition.coordinateValue?.latitude
    }
    
    var startLongitudeValue: Double? {
        startPosition.coordinateValue?.longitude
    }
    
    var minAltitudeValue: Double? {
        minAltitude.altitudeValue
    }
    
    var maxAltitudeValue: Double? {
        maxAltitude.altitudeValue
    }
    
    var totalAvgCadenceValue: Double? {
        totalAvgCadence.cadenceValue
    }
    
    var totalMaxCadenceValue: Double? {
        totalMaxCadence.cadenceValue
    }
    
    var totalEnergyBurnedValue: Double? {
        totalEnergyBurned.caloriesValue
    }
    
}

