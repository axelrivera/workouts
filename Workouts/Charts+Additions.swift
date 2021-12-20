//
//  Charts+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 3/9/21.
//

import Foundation
import Charts

class DateValueFormatter: NSObject, AxisValueFormatter {
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        formattedChartDurationString(for: value)
    }
    
}

class UnitValueFormatter: NSObject, AxisValueFormatter {
    enum Unit {
        case distance, calories, elevation
    }
    
    let unit: Unit
    
    init(unit: Unit) {
        self.unit = unit
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        switch unit {
        case .distance:
            let number = NumberFormatter.distanceCompact.string(from: value as NSNumber) ?? "0"
            let suffix = distanceUnitString()
            return String(format: "%@ %@", number, suffix)
        case .calories:
            return formattedCaloriesString(for: value, zeroPadding: true)
        case .elevation:
            let number = NumberFormatter.distanceCompact.string(from: value as NSNumber) ?? "0"
            let suffix = elevationUnitString()
            return String(format: "%@ %@", number, suffix)
        }
    }
}

class MonthValueFormatter: NSObject, AxisValueFormatter {

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        return DateFormatter.monthDay.string(from: date)
    }

}

class PaceValueFormatter: NSObject, AxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        formattedPaceString(for: value)
    }
    
}
