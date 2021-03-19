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
    var appIdentifier: String?
    var device: String?
    
    var distance: Double?
    var energyBurned: Double?
    
    var avgSpeed: Double?
    var maxSpeed: Double?
        
    var avgCyclingCadence: Double?
    var maxCyclingCadence: Double?
    
    var elevationAscended: Double?
    var elevationDescended: Double?
    
    static let paceActivities: [HKWorkoutActivityType] = [.walking, .running]
    
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
        appIdentifier = object.sourceRevision.source.bundleIdentifier
        device = object.device?.name
    }
    
    static var sample: Workout {
        let workout = Workout()
        workout.activityType = .cycling
        workout.startDate = Date().addingTimeInterval(-(60 * 60))
        workout.endDate = Date()
        workout.distance = 20000.0
        workout.energyBurned = 500.0
        
        workout.avgSpeed = 6.7056
        workout.maxSpeed = 10.2919
        
        workout.avgCyclingCadence = 82.0
        workout.maxCyclingCadence = 105.0
        
        workout.elevationAscended = 500.0
        workout.elevationDescended = 200.0
        
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
    
    var detailTitle: String {
        switch activityType {
        case .cycling:
            return "Ride"
        case .running:
            return "Run"
        case .walking:
            return "Walk"
        default:
            return "Summary"
        }
    }
    
    var elapsedTime: Double {
        endDate.timeIntervalSince(startDate)
    }
    
    var avgCadence: Double? {
        guard let avgCadence = avgCyclingCadence else { return nil }
        return avgCadence
    }
    
    var avgPace: Double? {
        guard let distance = distance else { return nil }
        return calculateRunningWalkingPace(distanceInMeters: distance, duration: elapsedTime)
    }
    
    var sourceAndDeviceString: String {
        var name = self.source
        if let device = self.deviceString {
            name.append(String(format: " (%@)", device))
        }
        return name
    }
    
    var deviceString: String? {
        guard let identifier = appIdentifier else { return nil }
        return identifier.contains(BWAppleHealthIdentifier) ? device : nil
    }
    
}

// MARK: Optional Checks

extension Workout {
    
    var isCadencePresent: Bool {
        guard activityType == .cycling else { return false }
        return avgCyclingCadence != nil || maxCyclingCadence != nil
    }
    
    var isPacePresent: Bool {
        Self.paceActivities.contains(activityType)
    }
    
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
