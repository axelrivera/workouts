//
//  Quantity.swift
//  Workouts
//
//  Created by Axel Rivera on 3/18/21.
//

import Foundation

struct Quantity {
    enum QuantityType {
        case heartRate, cadence, pace
    }
    
    let quantityType: QuantityType
    let timestamp: Date
    let value: Double
}
