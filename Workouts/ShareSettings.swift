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
    
    let cyclingMetricValue2: String?
    let runningMetricValue2: String?
    let otherMetricValue2: String?
    
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
    
    var cyclingMetric2: WorkoutCardViewModel.Metric? {
        guard let value = cyclingMetricValue2 else { return nil }
        return WorkoutCardViewModel.Metric(rawValue: value)
    }
    
    var runningMetric2: WorkoutCardViewModel.Metric? {
        guard let value = runningMetricValue2 else { return nil }
        return WorkoutCardViewModel.Metric(rawValue: value)
    }
    
    var otherMetric2: WorkoutCardViewModel.Metric? {
        guard let value = otherMetricValue2 else { return nil }
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
    
    func metric2(for sport: Sport) -> WorkoutCardViewModel.Metric? {
        if sport.isCycling {
            return cyclingMetric2
        } else if sport.isWalkingOrRunning {
            return runningMetric2
        } else {
            return otherMetric2
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
            cyclingMetricValue2: nil,
            runningMetricValue2: nil,
            otherMetricValue2: nil,
            showTitle: true,
            showDate: true
        )
    }
    
}
