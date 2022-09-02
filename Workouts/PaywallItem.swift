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
        [workoutLog, progress, metrics, laps, more]
    }
    
    static var workoutLog: PaywallItem {
        PaywallItem(
            imageName: "calendar",
            imageColor: .accentColor,
            title: NSLocalizedString("Training Calendar", comment: "Paywall item label"),
            description: NSLocalizedString("Compare your weekly workouts relative to each other by distance or time.", comment: "Paywall item label")
        )
    }
    
    static var laps: PaywallItem {
        PaywallItem(
            imageName: "timer",
            imageColor: .orange,
            title: NSLocalizedString("Interactive Splits", comment: "Paywall item label"),
            description: NSLocalizedString("Analyze your splits using multiple distance intervals.", comment: "Paywall item label")
        )
    }
    
    static var metrics: PaywallItem {
        PaywallItem(
            imageName: "sum",
            imageColor: .purple,
            title: NSLocalizedString("Additional Metrics", comment: "Paywall item label"),
            description: NSLocalizedString("Analyze your metrics using multiple time frames in Tags and Progress sections.", comment: "Paywall item label")
        )
    }
    
    static var progress: PaywallItem {
        PaywallItem(
            imageName: "chart.line.uptrend.xyaxis",
            imageColor: .green,
            title: NSLocalizedString("Progress Charts", comment: "Paywall item label"),
            description: NSLocalizedString("Keep track of your progress using weekly and monthly charts.", comment: "Paywall item label")
        )
    }
    
    static var more: PaywallItem {
        PaywallItem(
            imageName: "star.fill",
            imageColor: .orange,
            title: NSLocalizedString("Support Indie Work", comment: "Paywall item label"),
            description: NSLocalizedString("Purchasing supports current and future development of Better Workouts.", comment: "Paywall item label")
        )
    }
    
}
