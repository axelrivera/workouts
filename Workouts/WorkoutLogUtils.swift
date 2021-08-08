//
//  WorkoutLogUtils.swift
//  Workouts
//
//  Created by Axel Rivera on 7/27/21.
//

import Foundation

func logScaleFactorForCyclingDistance(for meters: Double) -> Double {
    let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
    let conversion = measurement.converted(to: .miles)
    let miles = conversion.value
    
    switch miles {
    case let x where x > 0 && x <= 5:
        return 0.5
    case let x where x > 5 && x <= 10:
        return 0.55
    case let x where x > 10 && x <= 20:
        return 0.6
    case let x where x > 20 && x <= 30:
        return 0.65
    case let x where x > 30 && x <= 40:
        return 0.7
    case let x where x > 40 && x <= 50:
        return 0.75
    case let x where x > 50 && x <= 60:
        return 0.775
    case let x where x > 60 && x <= 65:
        return 0.8
    case let x where x > 65 && x <= 70:
        return 0.825
    case let x where x > 70 && x <= 75:
        return 0.85
    case let x where x > 75 && x <= 80:
        return 0.875
    case let x where x > 80 && x <= 90:
        return 0.9
    case let x where x > 90 && x <= 100:
        return 0.925
    case let x where x > 100 && x <= 125:
        return 0.95
    case let x where x > 125 && x <= 150:
        return 0.975
    case let x where x > 150:
        return 1
    default:
        return 0.5
    }
}

func logScaleFactorForRunningDistance(for meters: Double) -> Double {
    let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
    let conversion = measurement.converted(to: .miles)
    let miles = conversion.value
    
    switch miles {
    case let x where x > 0 && x <= 1:
        return 0.5
    case let x where x > 1 && x <= 2:
        return 0.55
    case let x where x > 2 && x <= 3:
        return 0.6
    case let x where x > 3 && x <= 4:
        return 0.65
    case let x where x > 4 && x <= 5:
        return 0.7
    case let x where x > 5 && x <= 6:
        return 0.75
    case let x where x > 6 && x <= 12:
        return 0.8
    case let x where x > 12 && x <= 18:
        return 0.9
    case let x where x > 18 && x <= 24:
        return 0.95
    case let x where x > 24:
        return 1
    default:
        return 0.5
    }
}

func logScaleFactorForWalkingDistance(for meters: Double) -> Double {
    let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
    let conversion = measurement.converted(to: .miles)
    let miles = conversion.value
    
    switch miles {
    case let x where x > 0 && x <= 1:
        return 0.5
    case let x where x > 1 && x <= 2:
        return 0.6
    case let x where x > 2 && x <= 3:
        return 0.7
    case let x where x > 3 && x <= 4:
        return 0.8
    case let x where x > 4 && x <= 5:
        return 0.9
    case let x where x > 5 && x <= 6:
        return 0.95
    case let x where x > 6:
        return 1
    default:
        return 0.5
    }
}


func logScaleFactorForTime(_ duration: Double) -> Double {
    let minutes = duration / 60.0
    
    switch minutes {
    case let x where x > 0 && x <= 30:
        return 0.5
    case let x where x > 30 && x <= 60:
        return 0.6
    case let x where x > 60 && x <= 90:
        return 0.7
    case let x where x > 90 && x <= 120:
        return 0.8
    case let x where x > 120 && x <= 180:
        return 0.85
    case let x where x > 180 && x <= 240:
        return 0.90
    case let x where x > 240 && x <= 300:
        return 0.95
    case let x where x > 300:
        return 1
    default:
        return 0.5
    }
}
