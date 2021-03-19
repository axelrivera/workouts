//
//  AppData.swift
//  Workouts
//
//  Created by Axel Rivera on 1/15/21.
//

import Foundation

let BWAppleHealthIdentifier = "com.apple.health"

let MetadataKeyAvgCyclingCadence = "BWAvgCyclingCadence"
let MetadataKeyMaxCyclingCadence = "BWMaxCyclingCadence"
let MetadataKeyAvgMET = "BWAvgMETValue"

// MARK: - Sample Metadata

let MetadataKeySampleCadence = "BWCadence"
let MetadataKeySampleTemperature = "BWTemperature"

struct Constants {
    static let defaultWeight: Double = 72.5748 // Use default weight of 160 lbs (72.5748 Kg)
}

extension Notification.Name {
    static let didRefreshWorkouts = Notification.Name("arn_did_refresh_workouts")
}
