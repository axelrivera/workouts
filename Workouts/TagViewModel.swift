//
//  TagViewModel.swift
//  Workouts
//
//  Created by Axel Rivera on 11/3/21.
//

import SwiftUI

protocol WorkoutSummary {
    typealias GearType = Tag.GearType
    
    var identifier: String { get }
    var title: String? { get }
    var titleColor: Color? { get }
    var sportValue: Sport? { get }
    var gearValue: GearType? { get }
    
    var total: Int { get }
    var distance: Double { get }
    var avgDistance: Double { get }
    var duration: Double { get }
    var avgDuration: Double { get }
    var calories: Double { get }
    var avgCalories: Double { get }
    var elevation: Double { get }
    var avgElevation: Double { get }
    var showSpeed: Bool { get }
    var avgSpeed: Double { get }
    var showPace: Bool { get }
    var avgPace: Double { get }
}

extension WorkoutSummary {
    
    var title: String? { nil }
    
    var titleColor: Color? { nil }
    
    // unit: meters/second
    var avgSpeed: Double {
        guard avgDuration > 0 else { return 0 }
        return avgDistance / avgDuration
    }
    
    var avgPace: Double {
        calculateRunningWalkingPace(distanceInMeters: avgDistance, duration: avgDuration) ?? 0
    }
    
    var distanceString: String {
        formattedDistanceStringInTags(for: distance)
    }
    
    var avgDistanceString: String {
        formattedDistanceStringInTags(for: avgDistance)
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

protocol TagViewModel: Hashable, Identifiable {
    typealias GearType = Tag.GearType
    
    var id: UUID { get }
    var name: String { get }
    var color: Color { get }
    var gearType: GearType { get }
    var archived: Bool { get }
    
    init(id: UUID, name: String, color: Color, gearType: GearType, archived: Bool)
}

extension TagViewModel {
    
    static func sample<T: TagViewModel>(name: String? = nil, color: Color? = nil, gearType: GearType? = nil) -> T {
        let tagName = name ?? "Sample Tag Name"
        let color = color ?? .accentColor
        let gearType = gearType ?? .none
        
        return T(id: UUID(), name: tagName, color: color, gearType: gearType, archived: false)
    }
    
}

// MARK: - Summary

struct TagSummaryViewModel: TagViewModel, WorkoutSummary {
    let id: UUID
    let name: String
    let color: Color
    let gearType: GearType
    let archived: Bool
    
    private(set) var total: Int = 0
    private(set) var distance: Double = 0
    private(set) var avgDistance: Double = 0
    private(set) var duration: Double = 0
    private(set) var avgDuration: Double = 0
    private(set) var calories: Double = 0
    private(set) var avgCalories: Double = 0
    private(set) var elevation: Double = 0
    private(set) var avgElevation: Double = 0
    
    init(id: UUID, name: String, color: Color, gearType: GearType, archived: Bool) {
        self.id = id
        self.name = name
        self.color = color
        self.gearType = gearType
        self.archived = archived
    }
    
    var identifier: String { id.uuidString }
    var title: String? { name }
    var titleColor: Color? { color }
    var sportValue: Sport? { nil }
    var gearValue: GearType? { gearType }
    
    var showSpeed: Bool {
        gearType == .bike
    }
    
    var showPace: Bool {
        gearType == .shoes
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
}

// MARK: - Label

struct TagLabelViewModel: TagViewModel {
    let id: UUID
    let name: String
    let color: Color
    let gearType: GearType
    let archived: Bool
    
    init(id: UUID, name: String, color: Color, gearType: GearType, archived: Bool) {
        self.id = id
        self.name = name
        self.color = color
        self.gearType = gearType
        self.archived = archived
    }
}

extension Tag {
    func viewModel<VM: TagViewModel>() -> VM {
        VM(id: uuid, name: name, color: colorValue, gearType: gearType, archived: archivedDate == nil)
    }
}
