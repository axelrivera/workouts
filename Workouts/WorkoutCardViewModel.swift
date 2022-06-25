//
//  WorkoutCardViewModel.swift
//  WorkoutCardViewModel
//
//  Created by Axel Rivera on 8/25/21.
//

import SwiftUI
import CoreLocation

extension WorkoutCardViewModel {
    enum Metric: String, Identifiable, CaseIterable {
        case none, speed, maxSpeed, pace, heartRate, maxHeartRate, elevation, calories
        var id: String { rawValue }
        
        var title: String { Self.titleDictionary[self]! }
        var displayTitle: String? { Self.displayDictionary[self] }
        
        static let cyclingMetrics: [Metric] = [.none, .speed, maxSpeed, .heartRate, .maxHeartRate, .elevation, .calories]
        static let runningMetrics: [Metric] = [.none, .pace, .heartRate, maxHeartRate, .calories]
        static let indoorMetrics: [Metric] = [.none, .heartRate, maxHeartRate, .calories]
        static let otherMetrics: [Metric] = [.none, .heartRate, maxHeartRate, .calories]
        
        private static let titleDictionary: [Metric: String] = [
            .none: "No Metric",
            .speed: "Avg Speed",
            .maxSpeed: "Max Speed",
            .pace: "Pace",
            .heartRate: "Avg Heart Rate",
            .maxHeartRate: "Max Heart Rate",
            .elevation: "Elevation",
            .calories: "Calories"
        ]
        
        private static let displayDictionary: [Metric: String] = [
            .speed: "Avg Speed",
            .maxSpeed: "Max Speed",
            .pace: "Avg Pace",
            .heartRate: "Avg HR",
            .maxHeartRate: "Max HR",
            .elevation: "Elevation",
            .calories: "Calories"
        ]
    }
}

struct WorkoutCardViewModel {
    let sport: Sport
    let indoor: Bool
    let title: String
    let date: String?
    let duration: String
    let distance: String?
    let speed: String?
    let maxSpeed: String?
    let pace: String?
    let heartRate: String?
    let maxHeartRate: String?
    let elevation: String?
    let calories: String?
    let coordinates: [CLLocationCoordinate2D]
}

extension WorkoutCardViewModel {
    
    var includesLocation: Bool { !coordinates.isEmpty }
    
    func value(for metric: Metric) -> String? {
        switch metric {
        case .speed:
            return speed
        case .maxSpeed:
            return maxSpeed
        case .pace:
            return pace
        case .heartRate:
            return heartRate
        case .maxHeartRate:
            return maxHeartRate
        case .elevation:
            return elevation
        case .calories:
            return calories
        default:
            return nil
        }
    }
    
    static func empty() -> WorkoutCardViewModel {
        WorkoutCardViewModel(
            sport: .other,
            indoor: false,
            title: "",
            date: "",
            duration: "",
            distance: "",
            speed: nil,
            maxSpeed: nil,
            pace: nil,
            heartRate: nil,
            maxHeartRate: nil,
            elevation: nil,
            calories: nil,
            coordinates: []
        )
    }
    
}

extension WorkoutCardViewModel {
    
    static func preview() -> WorkoutCardViewModel {
        WorkoutCardViewModel(
            sport: .cycling,
            indoor: false,
            title: "Outdoor Cycle",
            date: "Jan 1, 2021 @ 7:00 AM",
            duration: "2h 30m",
            distance: "30.0 mi",
            speed: nil,
            maxSpeed: nil,
            pace: nil,
            heartRate: nil,
            maxHeartRate: nil,
            elevation: "800 ft",
            calories: nil,
            coordinates: sampleCoordinates()
        )
    }
    
}
