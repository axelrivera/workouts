//
//  HRZoneSummary.swift
//  Workouts
//
//  Created by Axel Rivera on 6/28/21.
//

import SwiftUI

extension HRZoneSummary: Identifiable {}

struct HRZoneSummary {
    let id = UUID().uuidString
    
    var name: String
    var color: Color
    var text: String
    var duration: Double
    var totalDuration: Double
}

extension HRZoneSummary {
    
    var percent: Double {
        guard totalDuration > 0 else { return 0 }
        return duration / totalDuration
    }
    
}

extension HRZoneSummary {
    
    static func samples() -> [HRZoneSummary] {
        let summaries: [HRZoneSummary] = HRZone.allCases.map { zone in
            let text = "0 - 100 bpm"
            return HRZoneSummary(name: zone.name, color: zone.color, text: text, duration: 500, totalDuration: 3600)
        }
        return summaries
    }
    
}
