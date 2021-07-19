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
            return "Used to get your body moving with minimal stress and exertion. This zone might be used for an easy training day, warming up or cooling down."
        case .zone2:
            return "Used for longer training sessions, you can sustain this basic-effort zone for many miles, yet still chitchat a little bit with your workout partner."
        case .zone3:
            return "This is a zone where you push the pace to build up speed and strength; conversation is reduced to single words."
        case .zone4:
            return "In this zone your body is processing its maximum amount of lactic acid as a fuel source; above this level, lactic acid builds up too quickly to be processed and fatigues muscles; training in this zone helps your body develop efficiency when you’re operating at your maximum sustainable pace."
        case .zone5:
            return "This maximum speed zone (think closing kick in a race) trains the neuromuscular system—your body learns how to recruit additional muscle fibers and how to fire muscles more effectively."
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
