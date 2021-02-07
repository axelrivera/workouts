//
//  Workout.swift
//  Workouts
//
//  Created by Axel Rivera on 12/28/20.
//

import Foundation
import HealthKit

class Workout: ObservableObject {
    var id = UUID()
    
    var activityType = HKWorkoutActivityType.other
    var indoor = false
    var startDate: Date = Date()
    var endDate: Date = Date()
    var energyBurned: Double = 0
    var distance: Double = 0
    var source: String = ""
    var device: String?
    
    var avgSpeed: Double?
    var maxSpeed: Double?
        
    var avgCyclingCadence: Double?
    var maxCyclingCadence: Double?
    
    init() {
        // initialize empty object
    }
    
    convenience init(object: HKWorkout) {
        self.init()
        id = object.uuid
        activityType = object.workoutActivityType
        indoor = object.metadata?[HKMetadataKeyIndoorWorkout] as? Bool ?? false
        startDate = object.startDate
        endDate = object.endDate
        energyBurned = object.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        distance = object.totalDistance?.doubleValue(for: .meter()) ?? 0
        
        avgSpeed = object.avgSpeed?.doubleValue(for: .metersPerSecond())
        maxSpeed = object.maxSpeed?.doubleValue(for: .metersPerSecond())
        
        avgCyclingCadence = object.avgCyclingCadence
        maxCyclingCadence = object.maxCyclingCadence
        
        source = object.sourceRevision.source.name
        device = object.device?.name
    }
    
    static var sample: Workout {
        let workout = Workout()
        workout.startDate = Date().addingTimeInterval(-(60 * 60))
        workout.endDate = Date()
        workout.distance = 30.0
        workout.energyBurned = 500.0
        workout.source = "Apple Watch"
        return workout
    }
}

extension Workout: Identifiable {}

extension Workout {
    
    var elapsedTime: Double {
        endDate.timeIntervalSince(startDate)
    }
}

// MARK: - Strings

extension Workout {
    
    var descriptionString: String {
        indoor ? "Indoor Cycle" : "Outdoor Cycle"
    }
    
}
