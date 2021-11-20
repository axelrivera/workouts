//
//  TagViewModel.swift
//  Workouts
//
//  Created by Axel Rivera on 11/3/21.
//

import SwiftUI

protocol TagViewModel: Hashable, Identifiable {
    typealias GearType = Tag.GearType
    
    var id: UUID { get }
    var name: String { get }
    var color: Color { get }
    var gearType: GearType { get }
    
    init(id: UUID, name: String, color: Color, gearType: GearType)
}

extension TagViewModel {
    
    static func sample<T: TagViewModel>(name: String? = nil) -> T {
        let tagName = name ?? "Sample Tag Name"
        let color = Color.tagColors.randomElement() ?? .accentColor
        let gearType = GearType.allCases.randomElement() ?? .none
        
        return T(id: UUID(), name: tagName, color: color, gearType: gearType)
    }
    
}

// MARK: - Summary

struct TagSummaryViewModel: TagViewModel {
    let id: UUID
    let name: String
    let color: Color
    let gearType: GearType
    
    private(set) var total: Int = 0
    private(set) var distance: Double = 0
    private(set) var avgDistance: Double = 0
    private(set) var duration: Double = 0
    private(set) var avgDuration: Double = 0
    private(set) var calories: Double = 0
    private(set) var avgCalories: Double = 0
    private(set) var elevation: Double = 0
    private(set) var avgElevation: Double = 0
    
    init(id: UUID, name: String, color: Color, gearType: GearType) {
        self.id = id
        self.name = name
        self.color = color
        self.gearType = gearType
    }
    
    mutating func updateValues(_ dictionary: [String: Any]) {
        total = dictionary[StatsProperties.count.key] as? Int ?? 0
        distance = dictionary[StatsProperties.distance.key] as? Double ?? 0
        avgDistance = dictionary[StatsProperties.avgDistance.key] as? Double ?? 0
        duration = dictionary[StatsProperties.duration.key] as? Double ?? 0
        avgDuration = dictionary[StatsProperties.avgDuration.key] as? Double ?? 0
        calories = dictionary[StatsProperties.energyBurned.key] as? Double ?? 0
        avgCalories = dictionary[StatsProperties.avgEnergyBurned.key] as? Double ?? 0
        elevation = dictionary[StatsProperties.elevation.key] as? Double ?? 0
        avgElevation = dictionary[StatsProperties.avgElevation.key] as? Double ?? 0
    }
    
    // unit: meters/second
    var avgSpeed: Double {
        guard avgDuration > 0 else { return 0 }
        return avgDistance / avgDuration
    }
    
    var avgPace: Double {
        calculateRunningWalkingPace(distanceInMeters: avgDistance, duration: avgDuration) ?? 0
    }
}

extension TagSummaryViewModel {
    
    var distanceString: String {
        formattedDistanceString(for: distance, zeroPadding: true)
    }
    
    var avgDistanceString: String {
        formattedDistanceString(for: avgDistance, zeroPadding: true)
    }
    
    var durationString: String {
        formattedHoursMinutesPrettyString(for: duration)
    }
    
    var avgDurationString: String {
        formattedHoursMinutesPrettyString(for: avgDuration)
    }
    
    var caloriesString: String {
        formattedCaloriesString(for: calories, zeroPadding: true)
    }
    
    var avgCaloriesString: String {
        formattedCaloriesString(for: avgCalories, zeroPadding: true)
    }
    
    var elevationString: String {
        formattedElevationString(for: elevation, zeroPadding: true)
    }
    
    var avgElevationString: String {
        formattedElevationString(for: avgElevation, zeroPadding: true)
    }
    
    var totalString: String {
        String(format: "%@", total.formatted())
    }
    
    var avgSpeedString: String {
        formattedSpeedString(for: avgSpeed)
    }
    
    var avgPaceString: String {
        formattedRunningWalkingPaceString(for: avgPace)
    }
    
}

// MARK: - Label

struct TagLabelViewModel: TagViewModel {
    let id: UUID
    let name: String
    let color: Color
    let gearType: GearType
    
    init(id: UUID, name: String, color: Color, gearType: GearType) {
        self.id = id
        self.name = name
        self.color = color
        self.gearType = gearType
    }
}

extension Tag {
    func viewModel<VM: TagViewModel>() -> VM {
        VM(id: uuid, name: name, color: colorValue, gearType: gearType)
    }
}
