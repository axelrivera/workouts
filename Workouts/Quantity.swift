//
//  Quantity.swift
//  Workouts
//
//  Created by Axel Rivera on 3/18/21.
//

import Foundation

struct Quantity {
    let start: Date
    let end: Date
    let value: Double
    
    var timestamp: Date { start }
}

struct Pace {
    let start: Date
    let end: Date
    let distance: Double
    
    var duration: Double {
        end.timeIntervalSince(start)
    }
}
