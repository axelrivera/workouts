//
//  HKWorkout+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 6/24/22.
//

import Foundation
import HealthKit
import CoreLocation

extension HKWorkout {
    
    var totalElapsedTime: Double {
        endDate.timeIntervalSince(startDate)
    }
    
    var movingTime: Double {
        duration
    }
    
    var isIndoor: Bool {
        metadata?[HKMetadataKeyIndoorWorkout] as? Bool ?? false
    }
    
    var isOutdoor: Bool {
        !isIndoor
    }
    
    var totalDistanceValue: Double {
        totalDistance?.doubleValue(for: .meter()) ?? 0
    }
    
    var avgSpeedValue: Double {
        guard totalElapsedTime > 0 else { return 0 }
        return totalDistanceValue / totalElapsedTime
    }
    
    var avgMovingSpeedValue: Double {
        totalDistanceValue / movingTime
    }
    
    var maxSpeedValue: Double {
        maxSpeed?.doubleValue(for: .metersPerSecond()) ?? 0
    }
    
    var avgPaceValue: Double {
        let sport = workoutActivityType.sport()
        guard sport.isWalkingOrRunning else { return 0 }
        
        let duration = totalElapsedTime
        let distance = totalDistanceValue
        return calculateRunningWalkingPace(distanceInMeters: distance, duration: duration) ?? 0
    }
    
    var avgMovingPaceValue: Double {
        calculateRunningWalkingPace(distanceInMeters: totalDistanceValue, duration: movingTime) ?? avgPaceValue
    }
    
    var maxSpeed: HKQuantity? {
        metadata?[HKMetadataKeyMaximumSpeed] as? HKQuantity
    }
    
    var avgCyclingCadenceValue: Double {
        metadata?[MetadataKeyAvgCyclingCadence] as? Double ?? 0
    }
    
    var maxCyclingCadenceValue: Double {
        metadata?[MetadataKeyMaxCyclingCadence] as? Double ?? 0
    }
    
    var totalEnergyBurnedValue: Double {
        totalEnergyBurned?.doubleValue(for: .largeCalorie()) ?? 0
    }
    
    var elevationAscendedValue: Double {
        elevationAscended?.doubleValue(for: .meter()) ?? 0
    }
    
    var elevationAscended: HKQuantity? {
        metadata?[HKMetadataKeyElevationAscended] as? HKQuantity
    }
    
    var elevationDescendedValue: Double {
        elevationDescended?.doubleValue(for: .meter()) ?? 0
    }
    
    var elevationDescended: HKQuantity? {
        metadata?[HKMetadataKeyElevationDescended] as? HKQuantity
    }
    
    var avgHeartRateValue: Double? {
        metadata?[MetadataKeyAvgHeartRate] as? Double
    }
    
    var minHeartRateValue: Double? {
        metadata?[MetadataKeyMinHeartRate] as? Double
    }
    
    var maxHeartRateValue: Double? {
        metadata?[MetadataKeyMaxHeartRate] as? Double
    }
    
    var startCoordinate: CLLocationCoordinate2D? {
        guard let lat = metadata?[MetadataKeyStartLatitude] as? Double, let long = metadata?[MetadataKeyStartLongitude] as? Double else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    var maxAltitudeValue: Double? {
        metadata?[MetadataKeyMaxAltitude] as? Double
    }
    
    var minAltitudeValue: Double? {
        metadata?[MetadataKeyMaxAltitude] as? Double
    }
    
    var totalCaloriesValue: Double? {
        metadata?[MetadataKeyEnergyBurned] as? Double
    }
    
}

extension HKWorkout {
    
    static let validStoppedEvents: [HKWorkoutEventType] = {
        [.pause, .resume]
    }()
    
    func stoppedIntervals() -> [DateInterval] {
        let events = workoutEvents ?? [HKWorkoutEvent]()
        let sortedEvents = events.sorted(by: { $0.dateInterval.start < $1.dateInterval.start })
        
        var pauseEvent: HKWorkoutEvent?
        
        var intervals = [DateInterval]()
        for event in sortedEvents {
            guard Self.validStoppedEvents.contains(event.type) else { continue }
            
            if event.type == .pause && pauseEvent == nil {
                pauseEvent = event
                continue
            }
            
            if event.type == .pause && pauseEvent != nil { continue }
            
            if let pause = pauseEvent, event.type == .resume {
                let interval = DateInterval(start: pause.dateInterval.start, end: event.dateInterval.start)
                intervals.append(interval)
                pauseEvent = nil
            }
        }
        return intervals
    }
    
}
