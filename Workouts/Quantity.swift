//
//  Quantity.swift
//  Workouts
//
//  Created by Axel Rivera on 3/18/21.
//

import Foundation

struct Quantity {
    let timestamp: Date
    let value: Double
}

struct Pace {
    let start: Date
    let end: Date
    let distance: Double
    
    var duration: Double {
        end.timeIntervalSince(start)
    }
}
