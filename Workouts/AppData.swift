//
//  AppData.swift
//  Workouts
//
//  Created by Axel Rivera on 1/15/21.
//

import SwiftUI
import HealthKit

let BWAppleHealthIdentifier = "com.apple.health"

let MetadataKeyAvgCyclingCadence = "BWAvgCyclingCadence"
let MetadataKeyMaxCyclingCadence = "BWMaxCyclingCadence"
let MetadataKeyAvgMET = "BWAvgMETValue"

// Added 8/15/2021
let MetadataKeyMaxTemperature = "BWMaxTemperature"
let MetadataKeyMovingTime = "BWMovingTime"
let MetadataKeyMinAltitude = "BWMinAltitude"
let MetadataKeyMaxAltitude = "BWMaxAltitude"
let MetadataKeyAvgHeartRate = "BWAvgHeartRate"
let MetadataKeyMinHeartRate = "BWMinHeartRate"
let MetadataKeyMaxHeartRate = "BWMaxHeartRate"
let MetadataKeyStartLatitude = "BWStartLatitude"
let MetadataKeyStartLongitude = "BWStartLongitude"

// MARK: - Sample Metadata

let MetadataKeySampleCadence = "BWCadence"
let MetadataKeySampleTemperature = "BWTemperature"

struct Constants {
    static let defaultChartSampleInSeconds = 10
    static let defaultWeight: Double = 81.6466 // Use default weight of 180 lbs (81.6466 Kg)
    static let cornerRadius: CGFloat = 12.0
}

struct WorkoutConstants {
    static let availableActivityTypes: [HKWorkoutActivityType] = [.cycling, .running, .walking]
}

struct URLStrings {
    static let faq = "https://mobile.betterworkouts.app"
    static let tutorial = "https://mobile.betterworkouts.app/tutorial/"
    static let privacy = "https://mobile.betterworkouts.app/privacy/"
    static let iTunesReview = "http://itunes.apple.com/app/id1553807643?action=write-review"
    static let heartRateInfo = "https://www.heart.org/en/healthy-living/fitness/fitness-basics/target-heart-rates"
}

struct Emails {
    static let support = "feedback@betterworkouts.app"
}

extension Notification.Name {
    static let didRefreshWorkouts = Notification.Name("arn_did_refresh_workouts")
}
