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

func formattedHoursMinutesSecondsDurationString(for duration: Double?) -> String {
    let seconds = Int(duration ?? 0)
    let (h, m, s) = secondsToHoursMinutesSeconds(seconds: seconds)
    
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    } else {
        return String(format: "%02d:%02d", m, s)
    }
}

func formattedChartDurationString(for duration: Double?) -> String {
    let seconds = Int(duration ?? 0)
    let (h, m, s) = secondsToHoursMinutesSeconds(seconds: seconds)
    
    if h > 0 {
        return String(format: "%d:%02d", h, m)
    } else {
        return String(format: "%02d:%02d", m, s)
    }
}

func formattedHoursMinutesPrettyString(for duration: Double?) -> String {
    let seconds = Int(duration ?? 0)
    let (h, m, s) = secondsToHoursMinutesSeconds(seconds: seconds)
    
    if h > 0 {
        return String(format: "%dh %02dm", h, m)
    } else {
        return String(format: "%dm %02ds", m, s)
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

func distanceUnitString() -> String {
    Locale.isMetric() ? "km" : "mi"
}

func speedUnitString() -> String {
    Locale.isMetric() ? "mph": "km/hr"
}

enum DistanceMode {
    case `default`, compact, rounded
}

func formattedDistanceString(for meters: Double?, mode: DistanceMode = .default, zeroPadding: Bool = false) -> String {
    guard let meters = meters, meters > 0 else { return zeroPadding ? "0 \(distanceUnitString())" : "" }
    let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
    let conversion = measurement.converted(to: Locale.isMetric() ? .kilometers : .miles)
    
    switch mode {
    case .compact: return MeasurementFormatter.distanceCompact.string(from: conversion)
    case .rounded: return MeasurementFormatter.roundedDistance.string(from: conversion)
    default: return MeasurementFormatter.distance.string(from: conversion)
    }
}

func formattedLapDistanceString(for meters: Double?) -> String {
    guard let meters = meters, meters > 0 else { return "0 \(distanceUnitString())" }
    let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
    let conversion = measurement.converted(to: Locale.isMetric() ? .kilometers : .miles)
    
    return MeasurementFormatter.distanceLap.string(from: conversion)
}

func formattedSpeedString(for metersPerSecond: Double?) -> String {
    guard let speed = metersPerSecond, speed > 0 else { return "" }
    let measurement = Measurement<UnitSpeed>(value: speed, unit: .metersPerSecond)
    let conversion = measurement.converted(to: Locale.isMetric() ? .kilometersPerHour : .milesPerHour)
    return MeasurementFormatter.speed.string(from: conversion)
}

func formattedLapSpeedString(for metersPerSecond: Double?) -> String {
    guard let speed = metersPerSecond, speed > 0 else { return "" }
    let measurement = Measurement<UnitSpeed>(value: speed, unit: .metersPerSecond)
    let conversion = measurement.converted(to: Locale.isMetric() ? .kilometersPerHour : .milesPerHour)
    return MeasurementFormatter.speedLap.string(from: conversion)
}

func formattedRunningWalkingPaceUnitString() -> String {
    let unit = runningWalkingDistanceTargetUnit().symbol
    return String(format: "/%@", unit)
}

func formattedRunningWalkingPaceString(for duration: Double?) -> String {
    guard let duration = duration, duration > 0 else { return "" }
    let pace = formattedPaceString(for: duration)
    return String(format: "%@ %@", pace, formattedRunningWalkingPaceUnitString())
}

func formattedPaceString(for duration: Double?) -> String {
    guard let duration = duration, duration > 0 else { return "" }
    let (m, s) = secondsToMinutesSeconds(seconds: Int(duration))
    return String(format: "%d:%02d", m, s)
}

// MARK: - Heart Rate

func formattedHeartRateString(for heartRate: Double?) -> String {
    let number = (heartRate ?? 0) as NSNumber
    guard number.doubleValue > 0 else { return "" }
    return String(format: "%@ bpm", NumberFormatter.integer.string(from: number) ?? "n/a")
}

// MARK: - Cadence

func formattedCyclingCadenceString(for cadence: Double?) -> String {
    let number = (cadence ?? 0) as NSNumber
    guard number.doubleValue > 0 else { return "" }
    return String(format: "%@ rpm", NumberFormatter.integer.string(from: number) ?? "n/a")
}

// MARK: - Energy

func formattedCaloriesString(for calories: Double?, zeroPadding: Bool = false) -> String {
    let number = (calories ?? 0) as NSNumber
    guard number.doubleValue > 0 else { return zeroPadding ? "0 cal" : "" }
    return String(format: "%@ cal", NumberFormatter.integer.string(from: number) ?? "n/a")
}

// MARK: - Weight

func formattedWeightString(for weight: Double?) -> String {
    guard let weight = weight else { return "n/a" }
    let measurement = Measurement<UnitMass>(value: weight, unit: .kilograms)
    return MeasurementFormatter.mass.string(from: measurement)
}

func formattedLocalizedWeightString(for weight: Double?) -> String {
    guard let weight = weight else { return "n/a" }
    let kilograms = localizedWeightUnitToKilograms(for: weight)
    return formattedWeightString(for: kilograms)
}

// MARK: - Elevation

func elevationUnitString() -> String {
    Locale.isMetric() ? "m" : "ft"
}

func formattedElevationString(for elevation: Double?, zeroPadding: Bool = false) -> String {
    guard let elevation = elevation else { return zeroPadding ? "0 \(elevationUnitString())" : "" }
    let measurement = Measurement<UnitLength>(value: elevation, unit: .meters)
    let conversion = measurement.converted(to: Locale.isMetric() ? .meters : .feet)
    return MeasurementFormatter.elevation.string(from: conversion)
}

// MARK: - Activities

func formattedActivityTypeString(for activityType: Sport, indoor: Bool) -> String {
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

extension DateFormatter {
    
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
    
    static let month: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
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
    
    static let weekdayFirstLetter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter
    }()
}

// MARK: - Number Formatter Extensions

extension NumberFormatter {
    
    static let distance: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let distanceLap: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let distanceCompact: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    static let speedLap: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
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
    
    static let percent: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        return formatter
    }()
}

// MARK: - Measurement Extensions

extension MeasurementFormatter {
    
    static let distance: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.distance
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    static let distanceLap: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.distanceLap
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    static let distanceCompact: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.distanceCompact
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    static let roundedDistance: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.integer
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
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
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    static let speedLap: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.speedLap
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    static let mass: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.integer
        formatter.unitStyle = .medium
        return formatter
    }()
    
}
