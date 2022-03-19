//
//  PaywallItem.swift
//  PaywallItem
//
//  Created by Axel Rivera on 9/13/21.
//

import SwiftUI

struct PaywallItem: Identifiable, Hashable {
    let id = UUID().uuidString
    let imageName: String
    let imageColor: Color
    let title: String
    let description: String
}

extension PaywallItem {
    
    static func items() -> [PaywallItem] {
        [workoutLog, progress, metrics, laps, heartRate, more]
    }
    
    static var workoutLog: PaywallItem {
        PaywallItem(
            imageName: "calendar",
            imageColor: .accentColor,
            title: "Training Calendar",
            description: "Compare your weekly workouts relative to each other by distance or time."
        )
    }
    
    static var laps: PaywallItem {
        PaywallItem(
            imageName: "timer",
            imageColor: .orange,
            title: "Interactive Splits",
            description: "Analyze your splits using multiple distance intervals."
        )
    }
    
    static var heartRate: PaywallItem {
        PaywallItem(
            imageName: "heart.fill",
            imageColor: .red,
            title: "Heart Rate Zones",
            description: "Train smarter not harder! Use heart rate zones to monitor your effort on individual workouts."
        )
    }
    
    static var metrics: PaywallItem {
        PaywallItem(
            imageName: "sum",
            imageColor: .purple,
            title: "Additional Metrics",
            description: "Analyze your metrics using multiple time frames in Tags and Progress sections."
        )
    }
    
    static var progress: PaywallItem {
        PaywallItem(
            imageName: "chart.line.uptrend.xyaxis",
            imageColor: .green,
            title: "Progress Charts",
            description: "Keep track of your progress using weekly and monthly charts."
        )
    }
    
    static var more: PaywallItem {
        PaywallItem(
            imageName: "star.fill",
            imageColor: .orange,
            title: "Support Indie Work",
            description: "Purchasing supports current and future development of Better Workouts."
        )
    }
    
}
