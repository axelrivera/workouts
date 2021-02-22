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
    
}

extension Date {
    
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
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)

        let sunday = calendar.date(from: components)!
        return calendar.date(byAdding: .day, value: 1, to: sunday)! // Workout weeks start on monday
    }

    var workoutWeekEnd: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        
        let sunday = calendar.date(from: components)!
        let nextSunday = calendar.date(byAdding: .day, value: 7, to: sunday)!
        return nextSunday.endOfDay
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

