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

class PaceValueFormatter: NSObject, AxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        formattedPaceString(for: value)
    }
    
}
