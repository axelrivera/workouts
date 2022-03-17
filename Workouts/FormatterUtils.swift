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

func formattedHoursMinutesPrettyString(for duration: Double?, showSeconds: Bool = true) -> String {
    let seconds = Int(duration ?? 0)
    guard seconds > 0 else {
        return String(format: "0m")
    }
    
    let (h, m, s) = secondsToHoursMinutesSeconds(seconds: seconds)
    
    if h > 0 {
        if m == 0 {
            return String(format: "%@h", h.formatted())
        } else {
            return String(format: "%@h %02dm", h.formatted(), m)
        }
    } else {
        if showSeconds && s > 0 {
            return String(format: "%dm %02ds", m, s)
        } else {
            return String(format: "%dm", m)
        }
    }
}

func formattedHoursMinutesPrettyStringInTags(for duration: Double?) -> String {
    let seconds = Int(duration ?? 0)
    guard seconds > 0 else {
        return String(format: "0m")
    }
    
    let (h, m, s) = secondsToHoursMinutesSeconds(seconds: seconds)
    
    if h > 0 {
        if h > 1_000 {
            return String(format: "%@h", h.formatted())
        } else {
            return String(format: "%dh %02dm", h, m)
        }
    } else {
        return String(format: "%dm %02ds", m, s)
    }
}

func formattedRelativeDateString(for date: Date?, shortDay: Bool = false, showTime: Bool = false) -> String {
    guard let date = date else { return "n/a" }
    
    var dateString: String
    var isCurrentDay = false
    if Calendar.current.isDateInToday(date) {
        isCurrentDay = true
        dateString = DateFormatter.time.string(from: date)
    } else if date.isWithinNumberOfDays(6) {
        dateString = DateFormatter.relative.string(from: date)
    } else {
        if shortDay {
            dateString = DateFormatter.shortDayShortMonthFormatter.string(from: date)
        } else {
            dateString = DateFormatter.longDayShortMonthFormatter.string(from: date)
        }
    }
    
    if showTime {
        if isCurrentDay {
            return String(format: "Today at %@", dateString)
        } else {
            return String(format: "%@ at %@", dateString, DateFormatter.time.string(from: date))
        }
    } else {
        return dateString
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

func formattedWorkoutShareDateString(for date: Date?) -> String? {
    guard let date = date else { return nil }
    
    return String(
        format: "%@ @ %@",
        DateFormatter.medium.string(from: date),
        DateFormatter.time.string(from: date)
    )
}

func formattedTimeString(for date: Date?) -> String {
    guard let date = date else { return "n/a" }
    return DateFormatter.time.string(from: date)
}

func formattedRangeString(start: Date?, end: Date?) -> String {
    guard let start = start else { return "n/a" }
    guard let end = end else {
        return DateFormatter.medium.string(from: start)
    }
    
    // date format: MMM dd YYYY
    let startMonth = DateFormatter.shortMonth.string(from: start)
    let startDay = DateFormatter.day.string(from: start)

    let endMonth = DateFormatter.shortMonth.string(from: end)
    let endDay = DateFormatter.day.string(from: end)
    let endYear = "\(end.year())"

    if startMonth == endMonth {
        return String(format: "%@ %@﹣%@, %@", startMonth, startDay, endDay, endYear)
    } else {
        return String(format: "%@ %@﹣%@ %@, %@", startMonth, startDay, endMonth, endDay, endYear)
    }
}

func formattedMonthYearString(for date: Date?) -> String {
    guard let date = date else { return "n/a" }
    return DateFormatter.monthYear.string(from: date)
}

func formattedFullDateString(for date: Date?) -> String {
    guard let date = date else { return "n/a" }
    return DateFormatter.longDayShortMonthFormatter.string(from: date)
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
    Locale.isMetric() ? "km/hr" : "mph"
}

enum DistanceMode {
    case `default`, compact, rounded
}

func formattedDistanceString(for meters: Double?, mode: DistanceMode = .default, zeroPadding: Bool = false) -> String {
    guard let meters = meters, meters > 0 else { return zeroPadding ? "0 \(distanceUnitString())" : "" }
    let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
    let conversion = measurement.converted(to: Locale.isMetric() ? .kilometers : .miles)
    
    switch mode {
    case .compact:
        return MeasurementFormatter.distanceCompact.string(from: conversion)
    case .rounded:
        return MeasurementFormatter.roundedDistance.string(from: conversion)
    default:
        return MeasurementFormatter.distance.string(from: conversion)
    }
}

func formattedSwimmingDistance(for meters: Double?) -> String {
    let distance = meters ?? 0
    let measurement = Measurement<UnitLength>(value: distance, unit: .meters)
    let conversion = measurement.converted(to: Locale.isMetric() ? .meters : .yards)
    return MeasurementFormatter.roundedDistance.string(from: conversion)
}

func formattedDistanceStringInTags(for meters: Double) -> String {
    let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
    let conversion = measurement.converted(to: Locale.isMetric() ? .kilometers : .miles)
    if conversion.value > 10_000 {
        return MeasurementFormatter.roundedDistance.string(from: measurement)
    } else {
        return MeasurementFormatter.distanceCompact.string(from: conversion)
    }
}

func formattedLapDistanceString(for meters: Double?) -> String {
    guard let meters = meters, meters > 0 else { return "0 \(distanceUnitString())" }
    let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
    let conversion = measurement.converted(to: Locale.isMetric() ? .kilometers : .miles)
    
    if conversion.value > 0.9 {
        return MeasurementFormatter.distanceLap.string(from: conversion)
    } else {
        return MeasurementFormatter.distanceLapFraction.string(from: conversion)
    }
}

func formattedSpeedString(for metersPerSecond: Double?) -> String {
    let speed = metersPerSecond ?? 0
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
    guard let duration = duration else { return "0:00 \(formattedRunningWalkingPaceUnitString())"}
    let pace = formattedPaceString(for: duration)
    return String(format: "%@ %@", pace, formattedRunningWalkingPaceUnitString())
}

func formattedPaceString(for duration: Double?) -> String {
    guard let duration = duration, duration > 0 else { return "0:00" }
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
    
    static let longDayShortMonthFormat: String? = {
        let template = "EEEEMMMdyyyy"
        let locale = Locale.current
        return DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: locale)
    }()
    
    static let shortDayShortMonthFormat: String? = {
        let template = "EEEMMMdyyyy"
        let locale = Locale.current
        return DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: locale)
    }()
    
    static let longDayShortMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        
        if let format = longDayShortMonthFormat {
            formatter.dateFormat = format
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        }
        return formatter
    }()
    
    static let shortDayShortMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        
        if let format = shortDayShortMonthFormat {
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
    
    static let year: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY"
        return formatter
    }()
    
    static let month: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    static let shortMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }()
    
    static let range: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "MMM/dd/YYYY"
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
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let distanceLap: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    static let distanceLapFraction: NumberFormatter = {
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
    
    static let distanceLapFraction: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter = NumberFormatter.distanceLapFraction
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
