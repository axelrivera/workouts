//
//  StatsSummary.swift
//  Workouts
//
//  Created by Axel Rivera on 2/19/21.
//

import Foundation
import SwiftUI

fileprivate extension NumberFormatter {
    static let countFormatter: NumberFormatter = {
       let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

extension StatsSummary {
    
    enum Timeframe: Identifiable, Hashable, CaseIterable {
        case week, month, year, yearToDate, allTime
        var id: Self { self }
        
        var recentTitle: String {
            switch self {
            case .week:
                return "Last 12 Weeks"
            case .month:
                return "Last 12 Months"
            default:
                return ""
            }
        }
    }
    
}

extension StatsSummary: Identifiable {}
extension StatsSummary: Hashable {}

struct StatsSummary {
    let id: String
    let sport: Sport?
    let timeframe: Timeframe
    let interval: DateInterval
    let workouts: [UUID]
    
    private(set) var total: Int = 0
    private(set) var distance: Double = 0
    private(set) var avgDistance: Double = 0
    private(set) var duration: Double = 0
    private(set) var avgDuration: Double = 0
    private(set) var calories: Double = 0
    private(set) var avgCalories: Double = 0
    private(set) var elevation: Double = 0
    private(set) var avgElevation: Double = 0
    
    init(sport: Sport?, timeframe: Timeframe, interval: DateInterval? = nil, dictionary: [String: Any] = [String: Any](), workouts: [UUID] = []) {
        self.id = UUID().uuidString
        self.sport = sport
        self.timeframe = timeframe
        self.interval = interval ?? Self.currentInterval(for: timeframe)
        self.workouts = workouts
        
        total = dictionary[StatsProperties.count.key] as? Int ?? 0
        distance = dictionary[StatsProperties.distance.key] as? Double ?? 0
        avgDistance = dictionary[StatsProperties.avgDistance.key] as? Double ?? 0
        duration = dictionary[StatsProperties.duration.key] as? Double ?? 0
        avgDuration = dictionary[StatsProperties.avgDuration.key] as? Double ?? 0
        calories = dictionary[StatsProperties.energyBurned.key] as? Double ?? 0
        avgCalories = dictionary[StatsProperties.avgEnergyBurned.key] as? Double ?? 0
        elevation = dictionary[StatsProperties.elevation.key] as? Double ?? 0
        avgElevation = dictionary[StatsProperties.avgElevation.key] as? Double ?? 0
    }
}

extension StatsSummary: WorkoutSummary {
    
    var title: String {
        switch timeframe {
        case .week:
            return formattedMonthDayRangeString(start: interval.start, end: interval.end)
        case .month:
            return formattedMonthYearString(for: interval.start)
        case .year:
            return "\(interval.start.year())"
        case .yearToDate:
            return "Year to Date"
        case .allTime:
            return "All Time"
        }
    }
    
    var showSpeed: Bool {
        sport?.isCycling ?? false
    }
    
    var showPace: Bool {
        sport?.isWalkingOrRunning ?? false
    }
    
    var identifier: String { id }
    var sportValue: Sport? { sport }
    var gearValue: GearType? { nil }
}

extension StatsSummary {
    
    var formattedCount: String {
        NumberFormatter.countFormatter.string(from: total as NSNumber) ?? ""
    }
    
}

extension StatsSummary {
    
    static func currentInterval(for timeframe: Timeframe) -> DateInterval {
        let date = Date()
        switch timeframe {
        case .week:
            return DateInterval(start: date.workoutWeekStart, end: date.workoutWeekEnd)
        case .month:
            return DateInterval(start: date.startOfMonth, end: date.endOfMonth)
        case .year, .yearToDate:
            return DateInterval(start: date.startOfYear, end: date.endOfYear)
        case .allTime:
            return DateInterval(start: Date.distantPast, end: Date.distantFuture)
        }
    }
    
    static var lastTwelveWeeks: [DateInterval] {
        var date = Date()
        
        var intervals = [DateInterval]()
        for _ in 0 ..< 12 {
            let start = date.workoutWeekStart
            let end = date.workoutWeekEnd
            
            let interval = DateInterval(start: start, end: end)
            intervals.append(interval)
            
            date = start.addingTimeInterval(-1)
        }
        
        return intervals
    }
    
    static var lastTwelveMonths: [DateInterval] {
        var date = Date()
        
        var intervals = [DateInterval]()
        for _ in 0 ..< 12 {
            let start = date.startOfMonth
            let end = date.endOfMonth
            
            let interval = DateInterval(start: start, end: end)
            intervals.append(interval)
            
            date = start.addingTimeInterval(-1)
        }
        
        return intervals
    }
    
}

// MARK: Formatting

extension StatsSummary {
    
    var isCurrentInterval: Bool {
        interval.contains(Date())
    }
    
    var currentString: String? {
        guard isCurrentInterval else { return nil }
        switch timeframe {
        case .week: return "Current Week"
        case .month: return "Current Month"
        default: return nil
        }
    }
    
    private var isCountSingular: Bool {
        total == 1
    }
    
    var sportTitle: String {
        switch sport {
        case .cycling:
            return isCountSingular ? "Ride" : "Rides"
        case .running:
            return isCountSingular ? "Run" : "Runs"
        case .walking:
            return isCountSingular ? "Walk" : "Walks"
        default:
            return isCountSingular ? "Workout" : "Workouts"
        }
    }
    
    var countLabel: String {
        String(format: "%@ %@", formattedCount, sportTitle)
    }
    
}

// MARK: - Samples

extension StatsSummary {
    
    static func sample(forTimeframe timeframe: Timeframe) -> StatsSummary {
        switch timeframe {
        case .week:
            return weeklySample()
        case .month:
            return monthlySample()
        case .year:
            return yearlySample()
        default:
            return allSample()
        }
    }
    
    static func weeklySample() -> StatsSummary {
        let dictionary: [String: Any] = [
            "count": 3,
            "distance": 160934.0,
            "movingTime": 30600.0,
            "elevation": 762.0,
            "energyBurned": 5000.0
        ]
        return StatsSummary(sport: .cycling, timeframe: .week, dictionary: dictionary)
    }
    
    static func monthlySample() -> StatsSummary {
        let dictionary: [String: Any] = [
            "count": 20,
            "distance": 804672.0,
            "movingTime": 90000.0,
            "elevation": 9144.0,
            "energyBurned": 25000.0
        ]
        return StatsSummary(sport: .cycling, timeframe: .month, dictionary: dictionary)
    }
    
    static func yearlySample() -> StatsSummary {
        let dictionary: [String: Any] = [
            "count": 100,
            "distance": 1609340.0,
            "movingTime": 306000.0,
            "elevation": 7620.0,
            "energyBurned": 50000.0
        ]
        return StatsSummary(sport: .cycling, timeframe: .year, dictionary: dictionary)
    }
    
    static func allSample() -> StatsSummary {
        let dictionary: [String: Any] = [
            "count": 100,
            "distance": 1609340.0,
            "movingTime": 306000.0,
            "elevation": 7620.0,
            "energyBurned": 50000.0
        ]
        return StatsSummary(sport: .cycling, timeframe: .allTime, dictionary: dictionary)
    }
    
    static func weeklySamples() -> [StatsSummary] {
        lastTwelveWeeks.map { interval in
            let dictionary: [String: Any] = [
                "count": Int.random(in: 1...10),
                "distance": Double.random(in: 25000...50000),
                "movingTime": Double.random(in: 5000...10000),
                "elevation": Double.random(in: 100...1000),
                "energyBurned": Double.random(in: 1000...5000)
            ]
            
            return StatsSummary(sport: .cycling, timeframe: .week, interval: interval, dictionary: dictionary)
        }
    }
    
    static func monthlySamples() -> [StatsSummary] {
        lastTwelveMonths.map { interval in
            let dictionary: [String: Any] = [
                "count": Int.random(in: 5...30),
                "distance": Double.random(in: 500000...1000000),
                "movingTime": Double.random(in: 50000...100000),
                "elevation": Double.random(in: 1000...10000),
                "energyBurned": Double.random(in: 10000...50000)
            ]
            
            return StatsSummary(sport: .cycling, timeframe: .week, interval: interval, dictionary: dictionary)
        }
    }
    
}
