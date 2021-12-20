//
//  StatsSummary.swift
//  Workouts
//
//  Created by Axel Rivera on 2/19/21.
//

import Foundation

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
    
    enum Timeframe: Identifiable, CaseIterable {
        case week, month, year, allTime
        var id: Int { hashValue }
        
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
    let id = UUID().uuidString
    let sport: Sport?
    let timeframe: Timeframe
    let interval: DateInterval
    let count: Int
    let distance: Double
    let duration: Double
    let elevation: Double
    let energyBurned: Double
    let longestDistance: Double
    let highestElevation: Double
    
    init(sport: Sport?, timeframe: Timeframe, interval: DateInterval? = nil, dictionary: [String: Any] = [String: Any]()) {
        self.sport = sport
        self.timeframe = timeframe
        self.interval = interval ?? Self.currentInterval(for: timeframe)
        count = dictionary["count"] as? Int ?? 0
        distance = dictionary["distance"] as? Double ?? 0
        duration = dictionary["movingTime"] as? Double ?? 0
        elevation = dictionary["elevation"] as? Double ?? 0
        energyBurned = dictionary["energyBurned"] as? Double ?? 0
        longestDistance = dictionary["longestDistance"] as? Double ?? 0
        highestElevation = dictionary["highestElevation"] as? Double ?? 0
    }
}

extension StatsSummary {
    
    var formattedCount: String {
        NumberFormatter.countFormatter.string(from: count as NSNumber) ?? ""
    }
    
}

extension StatsSummary {
    
    static func currentInterval(for timeframe: Timeframe) -> DateInterval {
        let date = Date()
        switch timeframe {
        case .week:
//                let start = Date.dateFor(month: 2, day: 15, year: 2021)
//                let end = Date.dateFor(month: 2, day: 21, year: 2021)
//                return (start!, end!)
            return DateInterval(start: date.workoutWeekStart, end: date.workoutWeekEnd)
        case .month:
//                return (Date.dateFor(month: 2, day: 1, year: 2021)!, Date.dateFor(month: 2, day: 28, year: 2021)!)
            return DateInterval(start: date.startOfMonth, end: date.endOfMonth)
        case .year:
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
        count == 1
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
    
    var dateRangeHeader: String {
        switch timeframe {
        case .week:
            return formattedMonthDayRangeString(start: interval.start, end: interval.end)
        case .month:
            return formattedMonthYearString(for: interval.start)
        default:
            return ""
        }
    }
    
    var timeString: String {
        formattedHoursMinutesPrettyString(for: duration)
    }
    
    var distanceString: String {
        let values: [Timeframe] = [.week, .month]
        let mode: DistanceMode = values.contains(timeframe) ? .default : .rounded
        return formattedDistanceString(for: distance, mode: mode, zeroPadding: true)
    }
    
    var caloriesString: String {
        formattedCaloriesString(for: energyBurned, zeroPadding: true)
    }
    
    var elevationString: String {
        formattedElevationString(for: elevation, zeroPadding: true)
    }
    
    var longestDistanceString: String {
        formattedDistanceString(for: longestDistance, zeroPadding: true)
    }
    
    var highestElevationString: String {
        formattedElevationString(for: highestElevation, zeroPadding: true)
    }
    
}

// MARK: - Samples

extension StatsSummary {
    
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
        return StatsSummary(sport: .cycling, timeframe: .week, dictionary: dictionary)
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
