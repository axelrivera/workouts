//
//  RunWalkUtils.swift
//  Workouts
//
//  Created by Axel Rivera on 3/15/21.
//

import Foundation

// Pace = Minutes / Miles or Minutes / Kilometers

func calculateRunningWalkingPace(distanceInMeters meters: Double, duration: Double) -> Double? {
    let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
    let value = measurement.converted(to: runningWalkingDistanceTargetUnit()).value
    
    guard value > 0 else { return nil }
    return duration / value
}

func runningWalkingDistanceTargetUnit() -> UnitLength {
    Locale.isMetric() ? .kilometers : .miles
}
