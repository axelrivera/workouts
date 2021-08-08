//
//  WorkoutDetail.swift
//  Workouts
//
//  Created by Axel Rivera on 8/2/21.
//

import Foundation

struct WorkoutDetail {
    let sport: Sport
    let indoor: Bool
    let title: String
    let showMap: Bool
    
    let start: Date
    let end: Date

    let movingTime: Double
    let duration: Double
    
    let distance: Double
    
    let avgMovingSpeed: Double
    let avgSpeed: Double
    let maxSpeed: Double
    
    let avgCyclingCadence: Double
    let maxCyclingCadence: Double
    
    let avgPace: Double
    
    var elevationAscended: Double
    var elevationDescended: Double
    
    let energyBurned: Double
    let avgHeartRate: Double
    let maxHeartRate: Double
        
    let source: String
    let device: String?
    let appIdentifier: String?
        
    init() {
        sport = .other
        indoor = false
        title = ""
        showMap = true
        start = Date()
        end = Date()
        movingTime = 0
        duration = 0
        distance = 0
        avgMovingSpeed = 0
        avgSpeed = 0
        maxSpeed = 0
        avgCyclingCadence = 0
        maxCyclingCadence = 0
        avgPace = 0
        elevationAscended = 0
        elevationDescended = 0
        energyBurned = 0
        avgHeartRate = 0
        maxHeartRate = 0
        source = ""
        device = nil
        appIdentifier = nil
    }
    
    init(workout: Workout) {
        sport = workout.sport
        indoor = workout.indoor
        title = workout.title
        showMap = workout.showMap
        start = workout.start
        end = workout.end
        movingTime = workout.movingTime
        duration = workout.duration
        distance = workout.distance
        avgMovingSpeed = workout.avgMovingSpeed
        avgSpeed = workout.avgSpeed
        maxSpeed = workout.maxSpeed
        avgCyclingCadence = workout.avgCyclingCadence
        maxCyclingCadence = workout.maxCyclingCadence
        avgPace = workout.avgPace
        elevationAscended = workout.elevationAscended
        elevationDescended = workout.elevationDescended
        energyBurned = workout.energyBurned
        avgHeartRate = workout.avgHeartRate
        maxHeartRate = workout.maxHeartRate
        source = workout.source
        device = workout.deviceString
        appIdentifier = workout.appIdentifier
    }
    
}

extension WorkoutDetail {
    
    var shouldUseMovingTime: Bool {
        movingTime < duration
    }
    
    var totalTimeLabel: String {
        shouldUseMovingTime ? "Moving Time" : "Time"
    }
    
    var totalTime: Double {
        shouldUseMovingTime ? movingTime : duration
    }
    
    var pausedTime: Double {
        duration - movingTime
    }
    
    var displayAvgSpeed: Double {
        shouldUseMovingTime ? avgMovingSpeed : avgSpeed
    }
    
    var detailTitle: String {
        switch sport {
        case .cycling:
            return "Ride"
        case .running:
            return "Run"
        case .walking:
            return "Walk"
        default:
            return ""
        }
    }
    
    var analysisTitle: String {
        let distanceStr = formattedDistanceString(for: distance)
        return String(format: "%@ %@", distanceStr, title)
    }
    
}
