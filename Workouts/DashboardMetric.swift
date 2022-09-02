//
//  DashboardMetric.swift
//  Workouts
//
//  Created by Axel Rivera on 3/5/22.
//

import SwiftUI
import HealthKit

enum DashboardMetric: Int, Hashable, Identifiable, CaseIterable {
    case activeEnergy
    case exerciseTime
    case steps
    case flights
    case walkingRunningDistance
    case cyclingDistance
    case swimmingDistance
    case swimmingStrokeCount
    case downhillSnowSportsDistance
    case wheelchairDistance
    case pushCount
    case workouts
    case workoutTime
    
    static let sumMetrics: [Self] = [
        .activeEnergy,
        .exerciseTime,
        .steps,
        .flights,
        .walkingRunningDistance,
        .cyclingDistance,
        .wheelchairDistance,
        .pushCount,
        .swimmingDistance,
        .swimmingStrokeCount,
        .downhillSnowSportsDistance
    ]
    
    static let cardMetrics: [Self] = [
        .activeEnergy,
        .exerciseTime,
        .steps,
        .flights,
        .walkingRunningDistance,
        .cyclingDistance,
        .swimmingDistance,
        .downhillSnowSportsDistance,
        .wheelchairDistance
    ]
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .activeEnergy: return NSLocalizedString("Active Calories", comment: "Label")
        case .exerciseTime: return NSLocalizedString("Exercise Time", comment: "Label")
        case .steps: return NSLocalizedString("Steps", comment: "Label")
        case .flights: return NSLocalizedString("Flights Climbed", comment: "Label")
        case .walkingRunningDistance: return NSLocalizedString("Walking & Running", comment: "Label")
        case .cyclingDistance: return NSLocalizedString("Cycling", comment: "Label")
        case .swimmingDistance: return NSLocalizedString("Swimming", comment: "Label")
        case .swimmingStrokeCount: return NSLocalizedString("Swimming Strokes", comment: "Label")
        case .downhillSnowSportsDistance: return NSLocalizedString("Downhill Snow Sports", comment: "Label")
        case .wheelchairDistance: return NSLocalizedString("Wheelchair", comment: "Label")
        case .pushCount: return NSLocalizedString("Wheelchair Pushes", comment: "Label")
        case .workouts: return NSLocalizedString( "Total Workouts", comment: "Label")
        case .workoutTime: return "Workout Time"
        }
    }
    
    var infoTitle: String {
        switch self {
        case .activeEnergy: return NSLocalizedString("Total Active Calories", comment: "Label")
        case .exerciseTime: return NSLocalizedString("Total Exercise Time", comment: "Label")
        case .steps: return NSLocalizedString("Total Steps", comment: "Label")
        case .flights: return NSLocalizedString("Total Flights Climbed", comment: "Label")
        case .walkingRunningDistance: return NSLocalizedString("Total Walking & Running Distance", comment: "Label")
        case .cyclingDistance: return NSLocalizedString("Total Cycling Distance", comment: "Label")
        case .wheelchairDistance: return NSLocalizedString("Total Wheelchair Distance", comment: "Label")
        case .pushCount: return NSLocalizedString("Total Wheelchair Push Count", comment: "Label")
        case .swimmingDistance: return NSLocalizedString("Total Swimming Distance", comment: "Label")
        case .swimmingStrokeCount: return NSLocalizedString("Total Swimming Stroke Count", comment: "Label")
        case .downhillSnowSportsDistance: return NSLocalizedString("Total Downhill Sports Distance", comment: "Label")
        case .workouts: return NSLocalizedString("Total Workouts", comment: "Label")
        case .workoutTime: return NSLocalizedString("Total Workout Time", comment: "Label")
        }
    }
    
    var image: UIImage {
        switch self {
        case .workouts:
            return .heartPulse()
        case.activeEnergy:
            return .systemFlame()
        case .exerciseTime:
            return .systemClock()
        case .workoutTime:
            return .systemTimer()
        case .steps:
            return .shoePrints()
        case .flights:
            return .stairs()
        case .walkingRunningDistance:
            return .personWalking()
        case .cyclingDistance:
            return .personBiking()
        case .swimmingDistance:
            return .water()
        case .swimmingStrokeCount:
            return .personSwimming()
        case .downhillSnowSportsDistance:
            return .personSkiing()
        case .wheelchairDistance:
            return .wheelchair()
        case .pushCount:
            return .wheelchairMove()
        }
    }
    
    var color: Color {
        switch self {
        case .activeEnergy: return .red
        case .exerciseTime: return .green
        case .steps: return .cyan
        case .flights: return .teal
        case .walkingRunningDistance: return Sport.walking.color
        case .cyclingDistance: return Sport.cycling.color
        case .swimmingDistance: return .saphire
        case .swimmingStrokeCount: return .apatite
        case .downhillSnowSportsDistance: return .graphite
        case .wheelchairDistance: return .cyan
        case .pushCount: return .teal
        case .workouts: return .amber
        case .workoutTime: return .orange
        }
    }
    
    var isVisible: Bool {
        Self.visible.contains(self)
    }
    
    var isVisibleInCard: Bool {
        Self.cardMetrics.contains(self)
    }
    
    func quantityAndUnit() -> (quantity: HKQuantityType, unit: HKUnit)? {
        switch self {
        case .activeEnergy: return (.activeEnergyBurned(), .largeCalorie())
        case .exerciseTime: return (.exerciseTime(), .second())
        case .steps: return (.stepCount(), .count())
        case .flights: return (.flightsClimbed(), .count())
        case .walkingRunningDistance: return (.distanceWalkingRunning(), .meter())
        case .cyclingDistance: return (.distanceCycling(), .meter())
        case .swimmingDistance: return (.distanceSwimming(), .meter())
        case .swimmingStrokeCount: return (.swimmingStrokeCount(), .count())
        case .downhillSnowSportsDistance: return (.distanceDownhillSnowSports(), .meter())
        case .wheelchairDistance: return (.distanceWheelchair(), .meter())
        case .pushCount: return (.pushCount(), .count())
        default: return nil
        }
    }
    
    static let visible: [Self] = [.activeEnergy, .exerciseTime]
    
}
