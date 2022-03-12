//
//  ShareSettings.swift
//  Workouts
//
//  Created by Axel Rivera on 9/7/21.
//

import SwiftUI

struct ShareSettings: Codable {
    let styleValue: String
    let mapColorValue: String
    let cyclingMetricValue: String?
    let runningMetricValue: String?
    let otherMetricValue: String?
    let showTitle: Bool
    let showDate: Bool
    
    var style: ShareManager.ShareStyle {
        ShareManager.ShareStyle(rawValue: styleValue) ?? .map
    }
    
    var mapColor: ShareManager.MapColor {
        ShareManager.MapColor(rawValue: mapColorValue) ?? .dark
    }
    
    var cyclingMetric: WorkoutCardViewModel.Metric? {
        guard let value = cyclingMetricValue else { return nil }
        return WorkoutCardViewModel.Metric(rawValue: value)
    }
    
    var runningMetric: WorkoutCardViewModel.Metric? {
        guard let value = runningMetricValue else { return nil }
        return WorkoutCardViewModel.Metric(rawValue: value)
    }
    
    var otherMetric: WorkoutCardViewModel.Metric? {
        guard let value = otherMetricValue else { return nil }
        return WorkoutCardViewModel.Metric(rawValue: value)
    }
    
    func metric(for sport: Sport) -> WorkoutCardViewModel.Metric? {
        if sport.isCycling {
            return cyclingMetric
        } else if sport.isWalkingOrRunning {
            return runningMetric
        } else {
            return otherMetric
        }
    }
}

extension ShareSettings {
    
    static func defaultValue() -> ShareSettings {
        ShareSettings(
            styleValue: ShareManager.ShareStyle.map.rawValue,
            mapColorValue: ShareManager.MapColor.dark.rawValue,
            cyclingMetricValue: nil,
            runningMetricValue: nil,
            otherMetricValue: nil,
            showTitle: true,
            showDate: true
        )
    }
    
}
