//
//  Workout.swift
//  Workouts
//
//  Created by Axel Rivera on 12/28/20.
//

import Foundation
import HealthKit

extension Workout: Identifiable {}

class Workout: ObservableObject {
    var id = UUID()
    
    var activityType = HKWorkoutActivityType.other
    var indoor = false
    var startDate: Date = Date()
    var endDate: Date = Date()
    var source: String = ""
    var device: String?
    
    var distance: Double?
    var energyBurned: Double?
    
    var avgSpeed: Double?
    var maxSpeed: Double?
        
    var avgCyclingCadence: Double?
    var maxCyclingCadence: Double?
    
    var elevationAscended: Double?
    var elevationDescended: Double?
    
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
        
        energyBurned = object.totalEnergyBurned?.doubleValue(for: .kilocalorie())
        distance = object.totalDistance?.doubleValue(for: .meter())
        
        avgSpeed = object.avgSpeed?.doubleValue(for: .metersPerSecond())
        maxSpeed = object.maxSpeed?.doubleValue(for: .metersPerSecond())
        
        elevationAscended = object.elevationAscended?.doubleValue(for: .meter())
        elevationDescended = object.elevationDescended?.doubleValue(for: .meter())
        
        avgCyclingCadence = object.avgCyclingCadence
        maxCyclingCadence = object.maxCyclingCadence
        
        source = object.sourceRevision.source.name
        device = object.device?.name
    }
    
    static var sample: Workout {
        let workout = Workout()
        workout.activityType = .cycling
        workout.startDate = Date().addingTimeInterval(-(60 * 60))
        workout.endDate = Date()
        workout.distance = 20000.0
        workout.energyBurned = 500.0
        workout.source = "Apple Watch"
        return workout
    }
}

extension Workout {
    
    var title: String {
        if HKWorkoutActivityType.indoorOutdoorList.contains(activityType) {
            return [indoor ? "Indoor" : "Outdoor", activityType.name].joined(separator: " ")
        } else {
            return activityType.name
        }
    }
    
    var elapsedTime: Double {
        endDate.timeIntervalSince(startDate)
    }
    
}

// MARK: Optional Checks

extension Workout {
    

    var isAvgSpeedPresent: Bool {
        avgSpeed != nil
    }
    
    var isDistancePresent: Bool {
        distance != nil
    }
    
    var isElevationAscendedPresent: Bool {
        elevationAscended != nil
    }
    
}
