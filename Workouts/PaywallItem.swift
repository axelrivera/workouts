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
        [tags, workoutLog, laps, heartRate, progress, files, more]
    }
    
    static var tags: PaywallItem {
        PaywallItem(
            imageName: "tag",
            imageColor: .green,
            title: "Tag Management",
            description: "Add tags to let you keep track of detailed metrics for bikes, shoes, workout types and more."
        )
    }
    
    static var workoutLog: PaywallItem {
        PaywallItem(
            imageName: "calendar",
            imageColor: .accentColor,
            title: "Activity Log",
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
    
    static var progress: PaywallItem {
        PaywallItem(
            imageName: "chart.bar.fill",
            imageColor: .green,
            title: "Progress Charts",
            description: "Keep track of your progress using weekly and monthly charts."
        )
    }
    
    static var files: PaywallItem {
        PaywallItem(
            imageName: "square.and.arrow.down",
            imageColor: .purple,
            title: "File Imports",
            description: "Manually import FIT files recorded from your cycling computer or smartwatch."
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
