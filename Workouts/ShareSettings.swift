//
//  ShareSettings.swift
//  Workouts
//
//  Created by Axel Rivera on 9/7/21.
//

import SwiftUI

struct ShareSettings: Codable {
    let styleValue: String
    let cyclingMetricValue: String?
    let runningMetricValue: String?
    let showTitle: Bool
    let showDate: Bool
    
    var style: ShareManager.ShareStyle {
        ShareManager.ShareStyle(rawValue: styleValue) ?? .map
    }
    
    var cyclingMetric: WorkoutCardViewModel.Metric? {
        guard let value = cyclingMetricValue else { return nil }
        return WorkoutCardViewModel.Metric(rawValue: value)
    }
    
    var runningMetric: WorkoutCardViewModel.Metric? {
        guard let value = runningMetricValue else { return nil }
        return WorkoutCardViewModel.Metric(rawValue: value)
    }
    
    func metric(for sport: Sport) -> WorkoutCardViewModel.Metric? {
        if sport.isCycling {
            return cyclingMetric
        } else if sport.isWalkingOrRunning {
            return runningMetric
        } else {
            return nil
        }
    }
}

extension ShareSettings {
    
    static func defaultValue() -> ShareSettings {
        ShareSettings(
            styleValue: ShareManager.ShareStyle.map.rawValue,
            cyclingMetricValue: nil,
            runningMetricValue: nil,
            showTitle: true,
            showDate: true
        )
    }
    
}
