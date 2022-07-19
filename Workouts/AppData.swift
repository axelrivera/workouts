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

// Added 7/12/22
let MetadataKeyEnergyBurned = "BWEnergyBurned"

// MARK: - Sample Metadata

let MetadataKeySampleCadence = "BWCadence"
let MetadataKeySampleTemperature = "BWTemperature"

struct Constants {
    static let defaultChartSampleInSeconds = 10
    static let defaultWeight: Double = 81.6466 // Use default weight of 180 lbs (81.6466 Kg)
    static let cornerRadius: CGFloat = 12.0
    static let cachedWorkoutImageWidth: CGFloat = 390.0
    static let cachedWorkoutImageHeight: CGFloat = 200.0
    static let cachedWorkoutImageScaleFactor = cachedWorkoutImageHeight / cachedWorkoutImageWidth
    static let cachedWorkoutImageSize = CGSize(width: cachedWorkoutImageWidth, height: cachedWorkoutImageHeight)
}

struct URLStrings {
    static let faq = "https://betterworkouts.app/faq/"
    static let about = "https://betterworkouts.app/about/"
    static let privacy = "https://betterworkouts.app/privacy/"
    static let iTunesReview = "http://itunes.apple.com/app/id1553807643?action=write-review"
    static let iTunesURL = "http://itunes.apple.com/app/id1553807643"
    static let heartRateInfo = "https://www.heart.org/en/healthy-living/fitness/fitness-basics/target-heart-rates"
}

struct Emails {
    static let support = "feedback@betterworkouts.app"
}

enum GlobalError: Error {
    case data
    case database
}
