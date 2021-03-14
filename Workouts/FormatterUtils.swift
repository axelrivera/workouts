//
//  FormatterUtils.swift
//  Workouts
//
//  Created by Axel Rivera on 2/1/21.
//

import Foundation
import HealthKit

// MARK: - Dates and Times

func formattedTimeDurationString(for duration: Double?) -> String {
    formattedTimer(for: Int(duration ?? 0))
}

func formattedHoursMinutesDurationString(for duration: Double?, includeSeconds: Bool = false) -> String {
    let seconds = Int(duration ?? 0)
    if includeSeconds {
        let (h, m, s) = secondsToHoursMinutesSeconds(seconds: seconds)
        return String(format: "%dh:%2dm:%2ds", h, m, s)
    } else {
        let (h, m) = secondsToHoursMinutes(seconds: seconds)
        return String(format: "%dh:%02dm", h, m)
    }
}

func formattedRelativeDateString(for date: Date?) -> String {
    guard let date = date else { return "n/a" }
    if Calendar.current.isDateInToday(date) {
        return DateFormatter.time.string(from: date)
    } else if date.isWithinNumberOfDays(6) {
        return DateFormatter.relative.string(from: date)
    } else {
        return DateFormatter.medium.string(from: date)
    }
}

func formattedImportRelativeDateString(for date: Date?) -> String {
    guard let date = date else { return "n/a" }
    
    let timeStr = DateFormatter.time.string(from: date)
    let dateStr: String
    
    if Calendar.current.isDateInToday(date) {
        dateStr = "Today"
    } else if date.isWithinNumberOfDays(6) {
        dateStr = DateFormatter.relative.string(from: date)
    } else {
        dateStr = DateFormatter.medium.string(from: date)
    }
    
    return String(format: "%@ @ %@", dateStr, timeStr)
}

func formattedTimeString(for date: Date?) -> String {
    guard let date = date else { return "n/a" }
    return DateFormatter.time.string(from: date)
}

func formattedMonthDayRangeString(start: Date?, end: Date?) -> String {
    guard let start = start else { return "n/a" }
    
    var strings = [DateFormatter.monthDay.string(from: start)]
    if let end = end {
        strings.append(DateFormatter.monthDay.string(from: end))
    }
    return strings.joined(separator: " - ")
}

func formattedMonthYearString(for date: Date?) -> String {
    guard let date = date else { return "n/a" }
    return DateFormatter.monthYear.string(from: date)
}

func formattedFullDateString(for date: Date?) -> String {
    guard let date = date else { return "n/a" }
    return DateFormatter.dayShortMonthFormatter.string(from: date)
}

func formattedTimeRangeString(start: Date?, end: Date?) -> String {
    guard let start = start else { return "n/a" }
    var strings = [ DateFormatter.localizedString(from: start, dateStyle: .none, timeStyle: .short) ]
    if let end = end {
        strings.append(DateFormatter.localizedString(from: end, dateStyle: .none, timeStyle: .short))
    }
    return strings.joined(separator: " - ")
}

// MARK: - Distance and Speed

func formattedDistanceString(for meters: Double?) -> String {
    let measurement = Measurement<UnitLength>(value: meters ?? 0, unit: .meters)
    return MeasurementFormatter.distance.string(from: measurement)
}

func formattedSpeedString(for metersPerSecond: Double?) -> String {
    let measurement = Measurement<UnitSpeed>(value: metersPerSecond ?? 0, unit: .metersPerSecond)
    return MeasurementFormatter.speed.string(from: measurement)
}

// MARK: - Heart Rate

func formattedHeartRateString(for heartRate: Double?) -> String {
    let number = (heartRate ?? 0) as NSNumber
    return String(format: "%@ bpm", NumberFormatter.integer.string(from: number) ?? "n/a")
}

// MARK: - Cadence

func formattedCyclingCadenceString(for cadence: Double?) -> String {
    let number = (cadence ?? 0) as NSNumber
    return String(format: "%@ rpm", NumberFormatter.integer.string(from: number) ?? "n/a")
}

// MARK: - Energy

func formattedCaloriesString(for calories: Double?) -> String {
    let number = (calories ?? 0) as NSNumber
    return String(format: "%@ cal", NumberFormatter.integer.string(from: number) ?? "n/a")
}

// MARK: - Weight

func formattedWeightString(for weight: Double?) -> String {
    guard let weight = weight else { return "n/a" }
    let measurement = Measurement<UnitMass>(value: weight, unit: .kilograms)
    return MeasurementFormatter.mass.string(from: measurement)
}

// MARK: - Elevation

func formattedElevationString(for elevation: Double?) -> String {
    guard let elevation = elevation else { return "n/a" }
    let measurement = Measurement<UnitLength>(value: elevation, unit: .meters)
    let conversion = measurement.converted(to: Locale.isMetric() ? .meters : .feet)
    return MeasurementFormatter.elevation.string(from: conversion)
}

// MARK: - Activities

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
    
    static let dayShortMonthFormat: String? = {
        let template = "EEEEMMMdyyyy"
        let locale = Locale.current
        return DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: locale)
    }()
    
    static let dayShortMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        
        if let format = dayShortMonthFormat {
            formatter.dateFormat = format
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        }
        return formatter
    }()
    
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
    
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
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
    
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter
    }()
    
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM YYYY"
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
    
    static let distance: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.distance
        formatter.unitStyle = .medium
        return formatter
    }()
    
    static let elevation: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.integer
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    static let speed: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.speed
        formatter.unitStyle = .medium
        return formatter
    }()
    
    static let mass: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.integer
        formatter.unitStyle = .medium
        return formatter
    }()
    
}
