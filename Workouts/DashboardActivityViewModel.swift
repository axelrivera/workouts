//
//  DashboardActivityViewModel.swift
//  Workouts
//
//  Created by Axel Rivera on 3/5/22.
//

import SwiftUI
import HealthKit

struct DashboardWorkoutViewModel {
    let WIDTH: CGFloat = 1080
    let HEIGHT_SQUARE: CGFloat = 1080
    let HEIGHT_PORTRAIT: CGFloat = 1350
    
    let title: String
    let subtitle: String
    let total: DashboardMetricViewModel
    let duration: DashboardMetricViewModel
    let activities: [DashboardActivityViewModel]
        
    var isVisible: Bool {
        total.value > 0
    }
    
    var size: CGSize {
        if isVisible {
            return CGSize(width: WIDTH, height: HEIGHT_PORTRAIT)
        } else {
            return CGSize(width: WIDTH, height: HEIGHT_SQUARE)
        }
    }
}

struct DashboardActivityViewModel: Hashable, Identifiable {
    let activity: HKWorkoutActivityType
    let total: Int
    let distance: Double
    let duration: Double
    
    var id: Self { self }
}

extension DashboardActivityViewModel {
    
    var hasMetrics: Bool {
        distance > 0 || duration > 0
    }
    
    var color: Color {
        let sport = activity.sport()
        if sport == .other {
            return .green
        } else {
            return sport.color
        }
    }
    
    private var isCountSingular: Bool {
        total == 1
    }
    
    private var altLabel: String {
        switch activity {
        case .cycling:
            return isCountSingular ? "Ride" : "Rides"
        case .running:
            return isCountSingular ? "Run" : "Runs"
        case .walking:
            return isCountSingular ? "Walk" : "Walks"
        default:
            return isCountSingular ? "Workout" : "Workouts"
        }
    }
    
    var totalLabel: String {
        String(format: "%@ %@", formattedTotal, altLabel)
    }
    
    var formattedTotal: String {
        total.formatted()
    }
    
    var formattedDistance: String? {
        guard distance > 0 else { return nil }
        return formattedDistanceString(for: distance, mode: .compact, zeroPadding: true)
    }
    
    var formattedDuration: String? {
        guard duration > 0 else { return nil }
        return formattedHoursMinutesPrettyString(for: duration, showSeconds: false)
    }
    
    var formattedValue: String {
        if let formattedDistance = formattedDistance {
            return formattedDistance
        } else if let formattedDuration = formattedDuration {
            return formattedDuration
        } else {
            return formattedTotal
        }
    }
    
}

// MARK: - Samples

extension DashboardActivityViewModel {
    
    static var all: [DashboardActivityViewModel] = {
        HKWorkoutActivityType.allActivities.map { activity in
            DashboardActivityViewModel(activity: activity, total: 1, distance: 1600, duration: 60 * 60)
        }
    }()
    
    static var sample: [DashboardActivityViewModel] = {
        let sample: [DashboardActivityViewModel] = [
            .init(activity: .cycling, total: 99, distance: 1700.0 * 100000, duration: 65.0 * 60.0 * 10000.0),
            .init(activity: .running, total: 99, distance: 1600, duration: 60 * 60),
            .init(activity: .walking, total: 99, distance: 1600, duration: 60 * 60)
        ]
        return sample
    }()
    
}
