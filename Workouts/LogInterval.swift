//
//  LogDay.swift
//  Workouts
//
//  Created by Axel Rivera on 7/26/21.
//

import SwiftUI
import CoreData

struct LogInterval: Identifiable {
    var id: String {
        days.map { day in
            DateFormatter.medium.string(from: day.date)
        }.joined(separator: ",")
    }
    let days: [LogDay]
}

extension LogInterval: Hashable {
    static func == (lhs: LogInterval, rhs: LogInterval) -> Bool {
        lhs.id == rhs.id
    }
}

extension LogInterval {
    
    var isEmpty: Bool {
        totalActivities == 0
    }
    
    var interval: DateInterval? {
        guard let start = start, let end = end else { return nil }
        return DateInterval(start: start, end: end)
     }
    
    var header: String {
        guard let interval = interval else { return "n/a" }
        return formattedRangeString(start: interval.start, end: interval.end)
    }

    var start: Date? {
        days.first?.date
    }
    
    var end: Date? {
        days.last?.date
    }
    
    var totalActivities: Int {
        days.map({ $0.activities.count }).reduce(0, +)
    }
    
    var trimp: Int {
        days.map({ $0.trimp }).reduce(0, +)
    }
    
    var distance: Double {
        days.map({ $0.distance }).reduce(0, +)
    }
    
    var duration: Double {
        days.map({ $0.duration }).reduce(0, +)
    }
    
    static func currentInterval() -> LogInterval {
        let interval = currentDateInterval()
        let dates = Date.dates(from: interval.start, to: interval.end)
        let days = dates.map { LogDay(date: $0, activities: []) }
        return LogInterval(days: days)
    }
    
    static func previousInterval() -> LogInterval {
        let interval = previousWeekDateInterval()
        let dates = Date.dates(from: interval.start, to: interval.end)
        let days = dates.map { LogDay(date: $0, activities: []) }
        return LogInterval(days: days)
    }
    
    static func currentDateInterval() -> DateInterval {
        let now = Date()
        return DateInterval(start: now.workoutWeekStart, end: now.workoutWeekEnd)
    }
    
    static func previousWeekDateInterval() -> DateInterval {
        let now = Date()
        let start = now.workoutWeekStart.addingTimeInterval(-1).workoutWeekStart
        let end = start.workoutWeekEnd
        return DateInterval(start: start, end: end)
    }
    
}

class LogDay: Identifiable {
    var id: Date { date }
    let date: Date
    var activities: [LogActivity]
    
    init(date: Date, activities: [LogActivity] = []) {
        self.date = date
        self.activities = activities
    }
}

extension LogDay: Hashable {
    
    static func == (lhs: LogDay, rhs: LogDay) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

extension LogDay {
    
    var remoteIdentifiers: [UUID] {
        activities.compactMap { $0.remoteIdentifier }
    }
    
    var trimp: Int {
        activities.map({ $0.trimp }).reduce(0, +)
    }
    
    var distance: Double {
        activities.map({ $0.distance }).reduce(0, +)
    }
    
    var duration: Double {
        activities.map({ $0.duration }).reduce(0, +)
    }
    
    var hasActivities: Bool {
        totalActivities > 0
    }
    
    var totalActivities: Int {
        activities.count
    }
    
    var label: String {
        DateFormatter.weekdayFirstLetter.string(from: date)
    }
    
    var color: Color {
        guard hasActivities else { return .secondary }
        
        let sportSet = Set(activities.map({ $0.sport }))
        
        if let sport = sportSet.first, sportSet.count == 1 {
            return sport.color
        } else {
            return .sport
        }
    }
    
    var distancePreferredSport: Sport? {
        guard hasActivities else { return nil }
        
        let sportSet = Set(activities.map({ $0.sport }))
        
        if let sport = sportSet.first, sportSet.count == 1 {
            return sport
        }
        
        let cycling = activities.filter({ $0.sport == .cycling }).map({ $0.distance }).reduce(0, +)
        let running = activities.filter({ $0.sport == .running }).map({ $0.distance }).reduce(0, +)
        let walking = activities.filter({ $0.sport == .walking }).map({ $0.distance }).reduce(0, +)
        
        if cycling > running || cycling > running {
            return .cycling
        }
        
        if running > walking {
            return .running
        }
        
        return .walking
    }
    
}

struct LogActivity: Identifiable {
    var id: UUID { remoteIdentifier }
    
    let remoteIdentifier: UUID
    let sport: Sport
    let trimp: Int
    let distance: Double
    let duration: Double
}

extension Workout {
    
    func logActivity() -> LogActivity {
        LogActivity(
            remoteIdentifier: workoutIdentifier,
            sport: sport,
            trimp: trimp,
            distance: distance,
            duration: movingTime
        )
    }
    
}

// MARK: - Samples

extension LogActivity {
    
    static func random() -> LogActivity {
        let sport = Sport.supportedSports.randomElement()!
        let speed: Double
        let trimp: Int
        let distance: Double
        let duration: Double
        
        switch sport {
        case .cycling:
            trimp = Int.random(in: 50...300)
            speed = 6.7056 // 15 mph
            distance = Double((32187...96560).randomElement()!) // 20 to 60 miles
        case .running:
            trimp = Int.random(in: 10...50)
            speed = 2.68224 // 6 mph
            distance = Double((4830...41842).randomElement()!) // 3 to 26 miles
        case .walking:
            trimp = Int.random(in: 5...30)
            speed = 1.34112 // 3 mph
            distance = Double((1609...4830).randomElement()!) // 1 to 3 miles
        default:
            trimp = 0
            speed = 0
            distance = 0
        }
        
        duration = speed > 0 ? distance / speed : 0
        
        return LogActivity(
            remoteIdentifier: UUID(),
            sport: sport,
            trimp: trimp,
            distance: distance,
            duration: duration
        )
    }
    
}

extension LogInterval {
    
    private static var activities = [0, 1, 2]
    
    static func sampleInterval(moc: NSManagedObjectContext?) -> LogInterval {
        let now = Date()
        
        let start = now.workoutWeekStart
        let end = now.workoutWeekEnd
        let dates = Date.dates(from: start, to: end)
        
        let days: [LogDay] = dates.map { date -> LogDay in
            let day = LogDay(date: date, activities: randomActivities(for: date))
            return day
        }
        return LogInterval(days: days)
    }
    
    private static func randomActivities(for date: Date) -> [LogActivity] {
        let total = (0...2).randomElement()!
        guard total > 0 else { return [] }
        
        var activities = [LogActivity]()
        for _ in 0 ..< total {
            activities.append(LogActivity.random())
        }
        return activities
    }
    
    static func sampleLastTwelveMonths() -> [LogInterval] {
        let interval = DateInterval.lastTwelveMonths()
        
        let start = interval.start.workoutWeekStart
        let end = interval.end.workoutWeekEnd
        let dates = Date.dates(from: start, to: end)
        
        let days: [LogDay] = dates.map { date -> LogDay in
            let activities = date <= Date() ? randomActivities(for: date) : []
            let day = LogDay(date: date, activities: activities)
            return day
        }
        
        let chunk = days.chunked(into: 7)
        let intervals: [LogInterval] = chunk.map({ LogInterval(days: $0)}).reversed()
        return intervals
    }
    
}

extension LogActivity {
    
    static func sampleActivity(sport: Sport?, date: Date?, moc: NSManagedObjectContext?) -> LogActivity {
        StorageProvider.sampleWorkout(sport: sport, date: date, moc: moc).logActivity()
    }
    
}
