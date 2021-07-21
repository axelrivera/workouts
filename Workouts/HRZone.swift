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
            return "Zone 1 is used to get your body moving at a relaxed, easy pace. This zone can be used during a brisk walk, easy training day, warming up or cooling down."
        case .zone2:
            return "Training in Zone 2 is used for longer training sessions. You can sustain a comfortable pace for many miles, yet still hold a conversation with your workout partner. Light or slow jogging falls info Zone 2."
        case .zone3:
            return "Zone 3 training is where you push the pace to build up speed and strength and it’s more difficult to hold a conversation. Easy running falls into Zone 3."
        case .zone4:
            return "In Zone 4 you’re breathing hard and moving fast at an uncomfortable pace. Your body is processing lactic acid as a fuel source; beyond this level, lactic acid builds too fast and fatigues muscles. Fast running falls info Zone 4."
        case .zone5:
            return "In Zone 5 you’re at maximum effort. Your heart and lungs will be working at their maximum capacity. Lactic acid will build up in your blood and it will be difficult to sustain your pace for long. Sprints fall into Zone 5."
        }
    }
    
    private static var zoneDictionary: [HRZone: String] {
        [.zone1: "Zone 1", .zone2: "Zone 2", .zone3: "Zone 3", .zone4: "Zone 4", .zone5: "Zone 5"]
    }
    
    private static var nameDictionary: [HRZone: String] {
        [.zone1: "Recovery", .zone2: "Aerobic", .zone3: "Tempo", .zone4: "Threshold", .zone5: "Anaerobic"]
    }
    
    private static var colorDictionary: [HRZone: Color] {
        [.zone1: .blue, .zone2: .green, .zone3: .orange, .zone4: .red, .zone5: .purple]
    }
    
    private static var percentDictionary: [HRZone: String] {
        [
            .zone1: "50 - 60% of HR max",
            .zone2: "60 - 70% of HR max",
            .zone3: "70 - 80% of HR Max",
            .zone4: "80 - 90% of HR Max",
            .zone5: "90 - 100% of HR Max"
        ]
    }
}
