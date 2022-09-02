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
            .none: NSLocalizedString("No Metric", comment: "Label"),
            .speed: LabelStrings.avgSpeed,
            .maxSpeed: LabelStrings.maxSpeed,
            .pace: LabelStrings.pace,
            .heartRate: LabelStrings.avgHeartRate,
            .maxHeartRate: LabelStrings.maxHeartRate,
            .elevation: LabelStrings.elevation,
            .calories: LabelStrings.calories
        ]
        
        private static let displayDictionary: [Metric: String] = [
            .speed: LabelStrings.avgSpeed,
            .maxSpeed: LabelStrings.maxSpeed,
            .pace: LabelStrings.avgPace,
            .heartRate: NSLocalizedString("Avg HR", comment: "Label - HR abbreviation"),
            .maxHeartRate: NSLocalizedString("Max HR", comment: "Label - HR abbreviation"),
            .elevation: LabelStrings.elevation,
            .calories: LabelStrings.calories
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
