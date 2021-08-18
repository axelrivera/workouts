//
//  ChartInterval.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import Foundation

struct ChartInterval {
    let xValue: Double
    let yValue: Double
}

extension ChartInterval: Comparable {
    
    static func == (lhs: ChartInterval, rhs: ChartInterval) -> Bool {
        lhs.yValue == rhs.yValue
    }
    
    static func < (lhs: ChartInterval, rhs: ChartInterval) -> Bool {
        lhs.yValue < rhs.yValue
    }
    
}

extension ChartInterval {
    enum ValueType {
        case heartRate, speed, pace, cadence, altitude
    }
}
