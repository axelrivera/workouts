//
//  MeasurementConversions.swift
//  Workouts
//
//  Created by Axel Rivera on 3/10/21.
//

import Foundation

func nativeSpeedToLocalizedUnit(for metersPerSecond: Double) -> Double {
    let measurement = Measurement<UnitSpeed>(value: metersPerSecond, unit: .metersPerSecond)
    let conversion = measurement.converted(to: Locale.isMetric() ? .kilometersPerHour : .milesPerHour)
    return conversion.value
}

func nativeAltitudeToLocalizedUnit(for meters: Double) -> Double {
    let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
    let conversion = measurement.converted(to: Locale.isMetric() ? .meters : .feet)
    return conversion.value
}

func kilogramsToLocalizedWeightUnit(for kilograms: Double) -> Double {
    if Locale.isMetric() {
        return kilograms
    } else {
        let measurement = Measurement<UnitMass>(value: kilograms, unit: .kilograms)
        let conversion = measurement.converted(to: .pounds)
        return conversion.value
    }
}

func localizedWeightUnitToKilograms(for weight: Double) -> Double {
    if Locale.isMetric() {
        return trunc(weight)
    } else {
        let measurement = Measurement<UnitMass>(value: weight, unit: .pounds)
        let conversion = measurement.converted(to: .kilograms)
        return conversion.value
    }
}
