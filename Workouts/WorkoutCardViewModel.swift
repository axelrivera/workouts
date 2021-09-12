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
        case none, speed, pace, heartRate, elevation
        var id: String { rawValue }
        
        var title: String { Self.titleDictionary[self]! }
        var displayTitle: String? { Self.displayDictionary[self] }
        
        static let cyclingMetrics: [Metric] = [.none, .speed, .heartRate, .elevation]
        static let runningMetrics: [Metric] = [.none, .pace, .heartRate]
        static let indoorMetrics: [Metric] = [.none, .heartRate]
        
        private static let titleDictionary: [Metric: String] = [
            .none: "No Metric",
            .speed: "Speed",
            .pace: "Pace",
            .heartRate: "Heart Rate",
            .elevation: "Elevation"
        ]
        
        private static let displayDictionary: [Metric: String] = [
            .speed: "Avg Speed",
            .pace: "Avg Pace",
            .heartRate: "Avg HR",
            .elevation: "Elevation"
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
    let pace: String?
    let heartRate: String?
    let elevation: String?
    let coordinates: [CLLocationCoordinate2D]
}

extension WorkoutCardViewModel {
    
    var includesLocation: Bool { !coordinates.isEmpty }
    
    func value(for metric: Metric) -> String? {
        switch metric {
        case .speed:
            return speed
        case .pace:
            return pace
        case .heartRate:
            return heartRate
        case .elevation:
            return elevation
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
            pace: nil,
            heartRate: nil,
            elevation: nil,
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
            pace: nil,
            heartRate: nil,
            elevation: "800 ft",
            coordinates: sampleCoordinates()
        )
    }
    
}
