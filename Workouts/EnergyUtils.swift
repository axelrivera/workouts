//
//  EnergyUtils.swift
//  Workouts
//
//  Created by Axel Rivera on 2/10/21.
//

import Foundation

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
}

func metValueFor(sport: Sport, indoor: Bool, speed metersPerSecond: Double) -> Double {
    let measurement = Measurement<UnitSpeed>(value: metersPerSecond, unit: .metersPerSecond)
    let speed = measurement.converted(to: .milesPerHour).value
    
    switch sport {
    case .cycling where indoor:
        return METValues.cyclingIndoorGeneral
    case .cycling:
        return outdoorCyclingValueFor(speed: speed)
    default:
        return METValues.cyclingOutdoorGeneral
    }
}

func outdoorCyclingValueFor(speed: Double) -> Double {
    switch speed {
    case let x where x > 0 && x < 10.0:
        return METValues.cyclingOutdoorLeisure
    case let x where x >= 10.0 && x <= 11.9:
        return METValues.cyclingOutdoorLight
    case let x where x >= 12.0 && x <= 13.9:
        return METValues.cyclingOutdoorModerate
    case let x where x >= 14.0 && x <= 15.9:
        return METValues.cyclingOutdoorVigorous
    case let x where x >= 16.0 && x <= 19.9:
        return METValues.cyclingOutdoorFast
    case let x where x > 19.9:
        return METValues.cyclingOutdoorVeryFast
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
