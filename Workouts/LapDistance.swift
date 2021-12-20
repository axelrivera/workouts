//
//  LapsHelper.swift
//  Workouts
//
//  Created by Axel Rivera on 8/9/21.
//

import Foundation


enum LapDistance: Identifiable, CaseIterable {
    case option1, option2, option3, option4
    var id: Int { hashValue }
}

extension LapDistance {
    
    func title(for sport: Sport) -> String {
        String(format: "%@ %@", distance(for: sport) as NSNumber, distanceUnit)
    }
    
    func distance(for sport: Sport) -> Double {
        switch sport {
        case .cycling:
            return Locale.isMetric() ? cyclingDistanceForKilometers : cyclingDistanceForMiles
        case .walking, .running:
            return Locale.isMetric() ? walkingRunningDistanceForKilometers : walkingRunningDistanceForMiles
        default:
            return 0
        }
    }
    
    func distanceInMeters(for sport: Sport) -> Double {
        let distance: Double
        switch sport {
        case .cycling:
            distance = Locale.isMetric() ? cyclingDistanceForKilometers : cyclingDistanceForMiles
        case .walking, .running:
            distance = Locale.isMetric() ? walkingRunningDistanceForKilometers : walkingRunningDistanceForMiles
        default:
            distance = 0
        }
        return Locale.isMetric() ? kilometersToMeters(for: distance) : milesToMeters(for: distance)
    }
    
    private var distanceUnit: String {
        distanceUnitString()
    }
    
    private var cyclingDistanceForMiles: Double {
        switch self {
        case .option1:
            return 1
        case .option2:
            return 5
        case .option3:
            return 10
        case .option4:
            return 20
        }
    }
    
    private var cyclingDistanceForKilometers: Double {
        switch self {
        case .option1:
            return 1
        case .option2:
            return 5
        case .option3:
            return 10
        case .option4:
            return 20
        }
    }
    
    private var walkingRunningDistanceForMiles: Double {
        switch self {
        case .option1:
            return 0.25
        case .option2:
            return 0.5
        case .option3:
            return 1
        case .option4:
            return 2
        }
    }
    
    private var walkingRunningDistanceForKilometers: Double {
        switch self {
        case .option1:
            return 0.5
        case .option2:
            return 1
        case .option3:
            return 2
        case .option4:
            return 3
        }
    }
    
}
