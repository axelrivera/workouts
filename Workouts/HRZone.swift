//
//  HRZone.swift
//  Workouts
//
//  Created by Axel Rivera on 6/24/21.
//

import SwiftUI

extension HRZone: Identifiable {}

enum HRZone: String, CaseIterable {
    case zone1, zone2, zone3, zone4, zone5
    
    var id: String { rawValue }
    
    var zoneString: String {
        Self.zoneDictionary[self]!
    }
    
    var name: String {
        Self.nameDictionary[self]!
    }
    
    var color: Color {
        Self.colorDictionary[self]!
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
}
