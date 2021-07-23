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
        var summaries = [HRZoneSummary]()
        
        HRZone.allCases.forEach { zone in
            var text: String
            var duration: Double
            let total: Double = 7200
            
            switch zone {
            case .zone1:
                text = "0 - 138 bpm"
                duration = total * 0.05
            case .zone2:
                text = "139 - 160 bpm"
                duration = total * 0.7
            case .zone3:
                text = "161 - 178 bpm"
                duration = total * 0.2
            case .zone4:
                text = "179 - 189 bpm"
                duration = total * 0.05
            case .zone5:
                text = "190 - ∞ bpm"
                duration = 0
            }
            
            summaries.append(HRZoneSummary(name: zone.name, color: zone.color, text: text, duration: duration, totalDuration: total))
        }
        return summaries
    }
    
}
