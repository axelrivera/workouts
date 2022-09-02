//
//  HRZone.swift
//  Workouts
//
//  Created by Axel Rivera on 6/24/21.
//

import SwiftUI

extension HRZone: Identifiable {}

typealias HRZoneTuple = (Int, Int, Int, Int, Int)

enum HRZone: String, CaseIterable {
    case zone1, zone2, zone3, zone4, zone5
    
    var id: String { rawValue }
    
    var zoneString: String {
        Self.zoneDictionary[self]!
    }
    
    var name: String {
        Self.nameDictionary[self]!
    }
    
    var percentString: String {
        Self.percentDictionary[self]!
    }
    
    var color: Color {
        Self.colorDictionary[self]!
    }
    
    var explanation: String {
        switch self {
        case .zone1:
            return Localization.HeartRate.zone1Explanation
        case .zone2:
            return Localization.HeartRate.zone2Explanation
        case .zone3:
            return Localization.HeartRate.zone3Explanation
        case .zone4:
            return Localization.HeartRate.zone4Explanation
        case .zone5:
            return Localization.HeartRate.zone5Explanation
        }
    }
    
    private static var zoneDictionary: [HRZone: String] {
        [
            .zone1: Localization.HeartRate.zone1Label,
            .zone2: Localization.HeartRate.zone2Label,
            .zone3: Localization.HeartRate.zone3Label,
            .zone4: Localization.HeartRate.zone4Label,
            .zone5: Localization.HeartRate.zone5Label
        ]
    }
    
    private static var nameDictionary: [HRZone: String] {
        [
            .zone1: Localization.HeartRate.zone1Name,
            .zone2: Localization.HeartRate.zone2Name,
            .zone3: Localization.HeartRate.zone3Name,
            .zone4: Localization.HeartRate.zone4Name,
            .zone5: Localization.HeartRate.zone5Name
        ]
    }
    
    private static var colorDictionary: [HRZone: Color] {
        [.zone1: .cadence, .zone2: .green, .zone3: .orange, .zone4: .red, .zone5: .purple]
    }
    
    private static var percentDictionary: [HRZone: String] {
        [
            .zone1: Localization.HeartRate.zone1PercentLabel,
            .zone2: Localization.HeartRate.zone2PercentLabel,
            .zone3: Localization.HeartRate.zone3PercentLabel,
            .zone4: Localization.HeartRate.zone4PercentLabel,
            .zone5: Localization.HeartRate.zone5PercentLabel
        ]
    }
}
