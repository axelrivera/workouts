//
//  Charts+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 3/9/21.
//

import Foundation
import Charts

class DateValueFormatter: NSObject, AxisValueFormatter {
    
    override init() {
        super.init()
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let interval = value * 60.0
        return formattedHoursMinutesDurationString(for: interval)
    }
}
