//
//  WorkoutInterval.swift
//  Workouts
//
//  Created by Axel Rivera on 8/9/21.
//

import Foundation

final class WorkoutInterval {
    let start: Date
    let end: Date
    
    var distance: Double = 0
    var cummulativeDistance: Double = 0
    
    var heartRate: Double = 0
    
    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
    
    var interval: DateInterval {
        DateInterval(start: start, end: end)
    }
}
