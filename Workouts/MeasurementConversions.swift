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
