//
//  DashboardMetricViewModel.swift
//  Workouts
//
//  Created by Axel Rivera on 3/5/22.
//

import SwiftUI

struct DashboardMetricViewModel: Hashable, Identifiable {
    let metric: DashboardMetric
    let value: Double
    
    var id: DashboardMetric { metric }
}

extension DashboardMetricViewModel {
    
    var isVisible: Bool {
        value > 0
    }
    
    var formattedValue: String {
        switch metric {
        case .activeEnergy:
            return formattedCaloriesString(for: value, zeroPadding: true)
        case .workoutTime, .exerciseTime:
            return formattedHoursMinutesPrettyString(for: value, showSeconds: false)
        case .steps, .flights, .workouts, .pushCount, .swimmingStrokeCount:
            let intValue = Int(value)
            return intValue.formatted()
        case .cyclingDistance, .walkingRunningDistance, .downhillSnowSportsDistance, .wheelchairDistance:
            let distanceMode: DistanceMode = value > 0 && value < 1 ? .default : .compact
            return formattedDistanceString(for: value, mode: distanceMode, zeroPadding: true)
        case .swimmingDistance:
            return formattedSwimmingDistance(for: value)
        }
    }
    
}

extension DashboardMetricViewModel {
    
    static var all: [DashboardMetricViewModel] = {
        [
           .init(metric: .activeEnergy, value: 500),
           .init(metric: .exerciseTime, value: 60 * 60 * 7),
           .init(metric: .steps, value: 99),
           .init(metric: .flights, value: 9),
           .init(metric: .workouts, value: 9),
           .init(metric: .workoutTime, value: 60 * 60 * 6),
           .init(metric: .walkingRunningDistance, value: 1600),
           .init(metric: .cyclingDistance, value: 1600),
           .init(metric: .wheelchairDistance, value: 1600),
           .init(metric: .pushCount, value: 99),
           .init(metric: .swimmingDistance, value: 1600),
           .init(metric: .swimmingStrokeCount, value: 99),
           .init(metric: .downhillSnowSportsDistance, value: 1600)
       ].sorted(by: { $0.metric.rawValue < $1.metric.rawValue })
    }()
    
    static var sample: [DashboardMetricViewModel] = {
        [
           .init(metric: .activeEnergy, value: 500),
           .init(metric: .exerciseTime, value: 60 * 60 * 7),
           .init(metric: .steps, value: 99),
           .init(metric: .flights, value: 9),
           .init(metric: .workouts, value: 9),
           .init(metric: .workoutTime, value: 60 * 60 * 6),
           .init(metric: .walkingRunningDistance, value: 1600),
           .init(metric: .cyclingDistance, value: 1600)
       ].sorted(by: { $0.metric.rawValue < $1.metric.rawValue })
    }()
    
    static var cardSample: [DashboardMetricViewModel] = {
        [
           .init(metric: .activeEnergy, value: 500),
           .init(metric: .exerciseTime, value: 60 * 60 * 7),
           .init(metric: .steps, value: 99),
           .init(metric: .flights, value: 9),
           .init(metric: .walkingRunningDistance, value: 1600),
           .init(metric: .cyclingDistance, value: 1600),
           .init(metric: .swimmingDistance, value: 1600)
       ].sorted(by: { $0.metric.rawValue < $1.metric.rawValue })
    }()
    
}
