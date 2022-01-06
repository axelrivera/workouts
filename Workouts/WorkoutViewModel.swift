//
//  WorkoutViewModel.swift
//  Workouts
//
//  Created by Axel Rivera on 12/7/21.
//

import Foundation
import CoreLocation
import SwiftUI

extension CLLocationCoordinate2D: Hashable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.latitude) //wasn't entirely sure what to put for the combine parameter but I saw similar things online
    }
    
}

final class WorkoutViewModel: Hashable, Identifiable {
    static func == (lhs: WorkoutViewModel, rhs: WorkoutViewModel) -> Bool {
        lhs.id == rhs.id && lhs.isFavorite == rhs.isFavorite && lhs.tags == rhs.tags
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isFavorite)
        hasher.combine(tags)
    }
    
    let id: UUID
    let sport: Sport
    let indoor: Bool
    let title: String
    let date: Date
    let distance: Double
    let duration: Double
    let avgSpeed: Double
    let avgPace: Double
    let calories: Double
    let avgHeartRate: Double
    let elevation: Double
    
    // mutable properties
    var coordinates = [CLLocationCoordinate2D]() {
        didSet {
            isPendingLocation = false
        }
    }
    
    private(set) var isPendingLocation = true
    
    // metadata
    var isFavorite = false
    var tags = [TagLabelViewModel]()
    
    init(workout: Workout) {
        id = workout.workoutIdentifier
        sport = workout.sport
        indoor = workout.indoor
        title = workout.title
        date = workout.start
        distance = workout.distance
        duration = workout.movingTime
        avgSpeed = workout.avgMovingSpeed
        avgPace = workout.avgPace
        calories = workout.energyBurned
        avgHeartRate = workout.avgHeartRate
        elevation = workout.elevationAscended
        coordinates = workout.coordinates
        isPendingLocation = workout.isLocationPending
    }
}

extension WorkoutViewModel {
    
    enum DisplayType {
        case cyclingDistance, runningWalkingDistance, other
    }
    
    func displayType() -> DisplayType {
        if sport.isCycling && distance > 0 { return .cyclingDistance }
        if sport.isWalkingOrRunning && distance > 0 { return .runningWalkingDistance }
        return .other
    }
    
    func dateString(shortDay: Bool = false) -> String {
        formattedRelativeDateString(for: date, shortDay: shortDay, showTime: true)
    }
    
    var distanceString: String {
        formattedDistanceString(for: distance, zeroPadding: true)
    }
    
    var durationString: String {
        formattedHoursMinutesPrettyString(for: duration)
    }
    
    var speedString: String {
        formattedSpeedString(for: avgSpeed)
    }
    
    var paceString: String {
        formattedRunningWalkingPaceString(for: avgPace)
    }
    
    var speedOrPaceString: String {
        if sport == .cycling {
            return speedString
        } else {
            return paceString
        }
    }
    
    var speedOrPaceColor: Color {
        if sport == .cycling {
            return .speed
        } else {
            return .cadence
        }
    }
    
    var calorieString: String {
        formattedCaloriesString(for: calories, zeroPadding: true)
    }
    
    var elevationString: String {
        formattedElevationString(for: elevation, zeroPadding: true)
    }
    
    var avgHeartRateString: String {
        formattedHeartRateString(for: avgHeartRate)
    }
    
}
