//
//  Date+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 1/31/21.
//

import Foundation

extension Date {
  
    func isWithinNumberOfDays(_ number: Int) -> Bool {
        let calendar = Calendar.current
        let currentNumberOfDays = calendar.dateComponents([.day], from: self, to: Date()).day ?? 0
        return currentNumberOfDays <= number
    }
    
    public func isBetween(date date1: Date, andDate date2: Date) -> Bool {
        (min(date1, date2) ... max(date1, date2)).contains(self)
    }
    
}

extension Date {
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    static func dateFor(month: Int, day: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.month = month
        components.day = day
        components.year = year
        
        return Calendar.current.date(from: components)
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = Calendar.current.dateComponents([.month, .day, .year], from: self)
        components.hour = 23
        components.minute = 59
        components.second = 59
        
        return Calendar.current.date(from: components)!
    }
    
    var workoutWeekStart: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = workoutDateComponents(for: calendar)
        let sunday = calendar.date(from: components)!
        return calendar.date(byAdding: .day, value: 1, to: sunday)! // Workout weeks start on monday
    }

    var workoutWeekEnd: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = workoutDateComponents(for: calendar)
        let sunday = calendar.date(from: components)!
        let nextSunday = calendar.date(byAdding: .day, value: 7, to: sunday)!
        return nextSunday.endOfDay
    }
    
    private func workoutDateComponents(for calendar: Calendar) -> DateComponents {
        let weekDay = calendar.component(.weekday, from: self)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        if let weekOfyear = components.weekOfYear, weekDay == 1 {
            components.weekOfYear = weekOfyear - 1 // Start last week if sunday
        }
        return components
    }
    
    var startOfMonth: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: self)
        return  calendar.date(from: components)!
    }
    
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfMonth)!
    }
    
    var startOfYear: Date {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: self)
        return  calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
    }
    
    var endOfYear: Date {
        var components = DateComponents()
        components.year = 1
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfYear)!
    }
    
}

extension Date {
    static var yesterday: Date { Date().dayBefore }
    static var tomorrow: Date { Date().dayAfter }
    
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    
}

extension Date {
    
    static func dates(from fromDate: Date, to toDate: Date) -> [Date] {
        var dates: [Date] = []
        var date = fromDate
        
        while date <= toDate {
            dates.append(date)
            guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: date) else { break }
            date = newDate
        }
        return dates
    }
    
}

extension Date {
    
    func year() -> Int {
        Calendar.current.component(.year, from: self)
    }
    
    static func firstDayForYear(year: Int) -> Date? {
        Date.dateFor(month: 1, day: 1, year: year)
    }
    
    static func lastDayForYear(year: Int) -> Date? {
        guard let first = firstDayForYear(year: year) else { return nil }
        return first.endOfYear
    }
    
}

extension DateInterval {
    
    static func lastTwelveMonths() -> DateInterval {
        let end = Date()
        let start = Calendar.current.date(byAdding: .month, value: -11, to: end)!.startOfMonth
        return DateInterval(start: start, end: end)
    }
    
    static func lastFiveYears() -> DateInterval {
        let now = Date()
        let endYear = now.year()
        let startYear = endYear - 4
        
        let start = Date.firstDayForYear(year: startYear)!
        let end = now
        
        return DateInterval(start: start, end: end)
    }
    
    static func intervalForYear(_ year: Int) -> DateInterval? {
        guard let start = Date.firstDayForYear(year: year), let end = Date.lastDayForYear(year: year) else { return nil }
        return DateInterval(start: start, end: end)
    }
    
    static func lastThirtyDays() -> DateInterval? {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date())!.startOfDay
        return DateInterval(start: start, end: Date())
    }
    
    static func lastTwoWeeks() -> DateInterval? {
        let start = Calendar.current.date(byAdding: .day, value: -14, to: Date())!.startOfDay
        return DateInterval(start: start, end: Date())
    }
    
}
