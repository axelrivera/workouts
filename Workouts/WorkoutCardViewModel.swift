//
//  WorkoutCardViewModel.swift
//  WorkoutCardViewModel
//
//  Created by Axel Rivera on 8/25/21.
//

import SwiftUI
import CoreLocation

struct WorkoutCardViewModel {
    let sport: Sport
    let indoor: Bool
    let title: String
    let date: String?
    let distance: String?
    let duration: String
    let elevation: String?
    let pace: String?
    let coordinates: [CLLocationCoordinate2D]
}

extension WorkoutCardViewModel {
    
    var includesLocation: Bool { !coordinates.isEmpty }
    
    static func empty() -> WorkoutCardViewModel {
        WorkoutCardViewModel(
            sport: .other,
            indoor: false,
            title: "",
            date: "",
            distance: "",
            duration: "",
            elevation: "",
            pace: nil,
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
            distance: "30.0 mi",
            duration: "2h 30m",
            elevation: "800 ft",
            pace: nil,
            coordinates: sampleCoordinates()
        )
    }
    
}
