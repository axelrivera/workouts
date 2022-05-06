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
        case .activeEnergy: return "Active Calories"
        case .exerciseTime: return "Exercise Time"
        case .steps: return "Steps"
        case .flights: return "Flights Climbed"
        case .walkingRunningDistance: return "Walking & Running"
        case .cyclingDistance: return "Cycling"
        case .swimmingDistance: return "Swimming"
        case .swimmingStrokeCount: return "Swimming Strokes"
        case .downhillSnowSportsDistance: return "Downhill Snow Sports"
        case .wheelchairDistance: return "Wheelchair"
        case .pushCount: return "Wheelchair Pushes"
        case .workouts: return "Total Workouts"
        case .workoutTime: return "Workout Time"
        }
    }
    
    var infoTitle: String {
        switch self {
        case .activeEnergy: return "Total Active Calories"
        case .exerciseTime: return "Total Exercise Time"
        case .steps: return "Total Steps"
        case .flights: return "Total Flishts Climbed"
        case .walkingRunningDistance: return "Total Walking & Running Distance"
        case .cyclingDistance: return "Total Cycling Distance"
        case .wheelchairDistance: return "Total Wheelchair Distance"
        case .pushCount: return "Total Wheelchair Push Count"
        case .swimmingDistance: return "Total Swimming Distance"
        case .swimmingStrokeCount: return "Total Swimming Stroke Count"
        case .downhillSnowSportsDistance: return "Total Downhill Sports Distance"
        case .workouts: return "Total Workouts"
        case .workoutTime: return "Total Workout Time"
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
