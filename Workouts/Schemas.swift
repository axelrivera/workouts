//
//  Schemas.swift
//  Workouts
//
//  Created by Axel Rivera on 7/16/22.
//

import Foundation

struct WorkoutSchema: Hashable, RawRepresentable {
    init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
    init(_ string: String) {
        self.rawValue = string
    }
    
    var rawValue: String
    
    typealias RawValue = String
    
    var key: String {
        rawValue
    }
    
    static let isReady = WorkoutSchema("isReady")
    static let remoteIdentifier = WorkoutSchema("remoteIdentifier")
    static let sport = WorkoutSchema("sportValue")
    static let indoor = WorkoutSchema("indoor")
    static let start = WorkoutSchema("start")
    static let end = WorkoutSchema("end")
    static let duration = WorkoutSchema("duration")
    static let movingTime = WorkoutSchema("movingTime")
    static let distance = WorkoutSchema("distance")
    static let avgHeartRate = WorkoutSchema("avgHeartRate")
    static let maxHeartRate = WorkoutSchema("maxHeartRate")
    static let energyBurned = WorkoutSchema("energyBurned")
    static let avgSpeed = WorkoutSchema("avgSpeed")
    static let maxSpeed = WorkoutSchema("maxSpeed")
    static let avgMovingSpeed = WorkoutSchema("avgMovingSpeed")
    static let avgCyclingCadence = WorkoutSchema("avgCyclingCadence")
    static let maxCyclingCadence = WorkoutSchema("maxCyclingCadence")
    static let avgPace = WorkoutSchema("avgPace")
    static let avgMovingPace = WorkoutSchema("avgMovingPace")
    static let elevationAscended = WorkoutSchema("elevationAscended")
    static let elevationDescended = WorkoutSchema("elevationDescended")
    static let maxElevation = WorkoutSchema("maxElevation")
    static let minElevation = WorkoutSchema("minElevation")
    static let source = WorkoutSchema("source")
    static let device = WorkoutSchema("device")
    static let appIdentifier = WorkoutSchema("appIdentifier")
    static let showMap = WorkoutSchema("showMap")
    static let locationCity = WorkoutSchema("locationCity")
    static let locationState = WorkoutSchema("locationState")
    static let markedForDeletionDate = WorkoutSchema("markedForDeletionDate")
    static let totalRetries = WorkoutSchema("totalRetries")
    static let coordinatesValue = WorkoutSchema("coordinatesValue")
    static let isLocationPending = WorkoutSchema("isLocationPending")
    static let dayOfWeek = WorkoutSchema("dayOfWeek")
    static let zoneMaxHeartRate = WorkoutSchema("zoneMaxHeartRate")
    static let zoneValue1 = WorkoutSchema("zoneValue1")
    static let zoneValue2 = WorkoutSchema("zoneValue2")
    static let zoneValue3 = WorkoutSchema("zoneValue3")
    static let zoneValue4 = WorkoutSchema("zoneValue4")
    static let zoneValue5 = WorkoutSchema("zoneValue5")
    static let createdAt = WorkoutSchema("createdAt")
    static let updatedAt = WorkoutSchema("udpatedAt")
    
    // V5 Additions
    static let trimp = WorkoutSchema("trimp")
    static let avgHeartRateReserve = WorkoutSchema("avgHeartRateReserve")
    static let valuesUpdated = WorkoutSchema("valuesUpdated")
}
