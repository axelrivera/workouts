//
//  EnergyUtils.swift
//  Workouts
//
//  Created by Axel Rivera on 2/10/21.
//

import Foundation

// Cycling

struct METValues {
    // leisure riding = < 10 mph
    static let cyclingOutdoorLeisure = 4.0

    // light riding = 10.0 to 11.9 mph
    static let cyclingOutdoorLight = 6.8

    // moderate riding = 12.0 to 13.9 mph
    static let cyclingOutdoorModerate = 8.0

    // vigorous riding = 14 to 15.9
    static let cyclingOutdoorVigorous = 10.0

    // fast = 16 to 19 mph
    static let cyclingOutdoorFast = 12.0

    // very fast = > 20 mph
    static let cyclingOutdoorVeryFast = 15.8

    // cycling general
    static let cyclingOutdoorGeneral = 7.5

    static let cyclingIndoorGeneral = 7.0
    
    static func outdoorCyclingValueFor(speedInMilesPerHour speed: Double) -> Double {
        switch speed {
        case let x where x > 0 && x < 10.0:
            return cyclingOutdoorLeisure
        case let x where x >= 10.0 && x <= 11.9:
            return cyclingOutdoorLight
        case let x where x >= 12.0 && x <= 13.9:
            return cyclingOutdoorModerate
        case let x where x >= 14.0 && x <= 15.9:
            return cyclingOutdoorVigorous
        case let x where x >= 16.0 && x <= 19.9:
            return cyclingOutdoorFast
        case let x where x > 19.9:
            return cyclingOutdoorVeryFast
        default:
            return cyclingOutdoorGeneral
        }
    }
}

// Running

extension METValues {
    // running, 4 mph (15 min/mile)
    static let running_4_Mph = 7.0
    
    // running, 5 mph (12 min/mile)
    static let running_5_Mph = 8.3
    
    // running, 5.2 mph (12 min /mile)
    static let running_5_2_Mph = 9.0
    
    // running, 6 mph (10 min/mile)
    static let running_6_Mph = 9.8
    
    // running, 6.7 mph (9 min/mile)
    static let running_6_7_Mph = 10.5
    
    // running, 7 mph (8.5 min/mile)
    static let running_7_Mph = 11.0
    
    // running, 7.5 mph (8 min/mile)
    static let running_7_5_Mph = 11.8
    
    // running, 8 mph (7.5 min/mile)
    static let running_8_Mph = 11.8
    
    // running, 8.6 mph (7 min/mile)
    static let running_8_6_Mph = 12.3
    
    // running, 9 mph (6.5 min/mile)
    static let running_9_Mph = 12.8
    
    // running, 10 mph (6 min/mile)
    static let running_10_Mph = 14.5
    
    // running, 11 mph (5.5 min/mile)
    static let running_11_Mph = 16.0
    
    // running, 12 mph (5 min/mile)
    static let running_12_Mph = 19.0
    
    // running, 13 mph (4.6 min/mile)
    static let running_13_Mph = 19.8
    
    // running, 14 mph (4.3 min/mile)
    static let running_14_Mph = 23.0
    
    static func runningValueFor(speedInMilesPerHour speed: Double) -> Double {
        switch speed {
        case 4.0 ..< 5.0:
            return running_4_Mph
        case 5.0 ..< 5.2:
            return running_5_Mph
        case 5.2 ..< 6.0:
            return running_5_2_Mph
        case 6.0 ..< 6.7:
            return running_6_Mph
        case 6.7 ..< 7.0:
            return running_6_7_Mph
        case 7.0 ..< 7.5:
            return running_7_Mph
        case 7.5 ..< 8.0:
            return running_7_5_Mph
        case 8.0 ..< 8.6:
            return running_8_Mph
        case 8.6 ..< 9.0:
            return running_8_6_Mph
        case 9.0 ..< 10.0:
            return running_9_Mph
        case 10.0 ..< 11.0:
            return running_10_Mph
        case 11.0 ..< 12.0:
            return running_11_Mph
        case 12.0 ..< 13.0:
            return running_12_Mph
        case 13.0 ..< 14.0:
            return running_13_Mph
        case let x where x > 14.0:
            return running_14_Mph
        default:
            return running_4_Mph
        }
    }
}

// Walking

extension METValues {
    // walking, 2.5 mph, level, firm surface
    static let walking_2_5_Mph = 3.0
    
    // walking, 2.8 to 3.2 mph, level, moderate pace, firm surface
    static let walking_2_8_Mph = 3.5
    
    // walking, 3.5 mph, level, brisk, firm surface, walking for exercise
    static let walking_3_5_Mph = 4.3
    
    // walking, 4.0 mph, level, firm surface, very brisk pace
    static let walking_4_Mph = 5.0
    
    // walking, 4.5 mph level, firm survace, very, very brisk pace
    static let walking_4_5_Mph = 7.0
    
    // walking, 5.0 mph, level, firm surface
    static let walking_5_Mph = 8.3
    
    // walking for pleasure
    static let walkingGeneral = 3.5
    
    static func walkingValueFor(speedInMilesPerHour speed: Double) -> Double {
        switch speed {
        case 2.5 ..< 2.8:
            return walking_2_5_Mph
        case 2.8 ..< 3.5:
            return walking_2_8_Mph
        case 3.5 ..< 4.0:
            return walking_3_5_Mph
        case 4.0 ..< 4.5:
            return walking_4_Mph
        case 4.5 ..< 5.0:
            return walking_4_5_Mph
        case let x where x > 5.0:
            return walking_5_Mph
        default:
            return walkingGeneral
        }
    }
}

func metValueFor(sport: Sport, indoor: Bool, speed metersPerSecond: Double) -> Double {
    let measurement = Measurement<UnitSpeed>(value: metersPerSecond, unit: .metersPerSecond)
    let speed = measurement.converted(to: .milesPerHour).value
    
    switch sport {
    case .cycling where indoor:
        return METValues.cyclingIndoorGeneral
    case .cycling:
        return METValues.outdoorCyclingValueFor(speedInMilesPerHour: speed)
    case .running:
        return METValues.runningValueFor(speedInMilesPerHour: speed)
    case .walking:
        return METValues.walkingValueFor(speedInMilesPerHour: speed)
    default:
        return METValues.cyclingOutdoorGeneral
    }
}

// Total calories burned = Duration (in minutes)*(MET*3.5*weight in kg)/200

// duration in minutes
// weight in Kg

func calculateCaloriesFor(duration: Double, metValue: Double, weight: Double) -> Double {
    duration * (metValue * 3.5 * weight / 200.0)
}
