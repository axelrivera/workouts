//
//  Calendar+Interval.swift
//  Calendar+Interval
//
//  Created by Axel Rivera on 8/10/21.
//

import Foundation

extension Calendar {
    
    func divide(interval dividend: DateInterval, by component: Calendar.Component, value divisor: Int) -> [DateInterval] {
        var intervals: [DateInterval] = []

        var previousDate = dividend.start
        
        while let nextDate = date(byAdding: component, value: divisor, to: previousDate), dividend.contains(nextDate) {
            let interval = DateInterval(start: previousDate, end: nextDate)
            intervals.append(interval)
            previousDate = date(byAdding: .second, value: 1, to: nextDate)!
        }
        
        if let last = intervals.popLast() {
            intervals.append(DateInterval(start: last.start, end: dividend.end))
        }

        return intervals
    }
    
}
