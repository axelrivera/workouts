//
//  FormatterUtils.swift
//  Workouts
//
//  Created by Axel Rivera on 2/1/21.
//

import Foundation
import HealthKit

func formattedTimeDurationString(for duration: Double?) -> String {
    formattedTimer(for: Int(duration ?? 0))
}

func formattedRelativeDateString(for date: Date?) -> String {
    guard let date = date else { return "n/a" }
    if date.isWithinNumberOfDays(7) {
        return DateFormatter.relative.string(from: date)
    } else {
        return DateFormatter.short.string(from: date)
    }
}

func formattedTimeString(for date: Date?) -> String {
    guard let date = date else { return "n/a" }
    return DateFormatter.time.string(from: date)
}

// TODO: Implement Global Unit

func formattedDistanceString(for meters: Double?) -> String {
    let measurement = Measurement<UnitLength>(value: meters ?? 0, unit: .meters)
    let conversion = measurement.converted(to: .miles)
    return MeasurementFormatter.distance.string(from: conversion)
}

// TODO: Implement Global Unit

func formattedSpeedString(for metersPerSecond: Double?) -> String {
    let measurement = Measurement<UnitSpeed>(value: metersPerSecond ?? 0, unit: .metersPerSecond)
    let conversion = measurement.converted(to: .milesPerHour)
    return MeasurementFormatter.distance.string(from: conversion)
}

func formattedHeartRateString(for heartRate: Double?) -> String {
    let number = (heartRate ?? 0) as NSNumber
    return String(format: "%@ bpm", NumberFormatter.integer.string(from: number) ?? "n/a")
}

func formattedCyclingCadenceString(for cadence: Double?) -> String {
    let number = (cadence ?? 0) as NSNumber
    return String(format: "%@ rpm", NumberFormatter.integer.string(from: number) ?? "n/a")
}

func formattedCaloriesString(for calories: Double?) -> String {
    let number = (calories ?? 0) as NSNumber
    return String(format: "%@ cal", NumberFormatter.integer.string(from: number) ?? "n/a")
}

func formattedActivityTypeString(for activityType: HKWorkoutActivityType, indoor: Bool) -> String {
    var strings = [String]()
    
    switch activityType {
    case .cycling where indoor:
        strings = ["Indoor", "Cycle"]
    case .cycling:
        strings = ["Outdoor", "Cycle"]
    case .running where indoor:
        strings = ["Indoor", "Run"]
    case .running:
        strings = ["Outdoor", "Run"]
    case .walking where indoor:
        strings = ["Indoor", "Walk"]
    case .walking:
        strings = ["Outdoor", "Walk"]
    default:
        strings = ["Other Activity"]
    }
    return strings.joined(separator: " ")
}

// MARK: - Date Extensions

private extension DateFormatter {
    
    static let relative: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "cccc"
        return formatter
    }()
    
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let long: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Number Formatter Extensions

private extension NumberFormatter {
    
    static let distance: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let speed: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    static let integer: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

// MARK: - Measurement Extensions

private extension MeasurementFormatter {
    
    static let energy: MeasurementFormatter = {
       let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.integer
        formatter.unitStyle = .medium
        return formatter
    }()
    
    static let distance: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.distance
        formatter.unitStyle = .medium
        
        return formatter
    }()
    
    static let speed: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.speed
        formatter.unitStyle = .short
        
        return formatter
    }()
    
}
