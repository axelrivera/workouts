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
    let removeBranding: Bool
    let mapColorValue: String
    let showTitle: Bool
    let showDate: Bool
    let backgroundColorDictionary: [String: Double]
    let showLocation: Bool
    let showRoute: Bool
    
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
    
    var mapColor: ShareManager.MapColor {
        ShareManager.MapColor(rawValue: mapColorValue) ?? .system
    }
    
    var backgroundColor: Color {
        .init(dictionary: backgroundColorDictionary) ?? .accentColor
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
            removeBranding: false,
            mapColorValue: ShareManager.MapColor.system.rawValue,
            showTitle: true,
            showDate: true,
            backgroundColorDictionary: Color.accentColor.colorDictionary,
            showLocation: true,
            showRoute: true
        )
    }
    
}

extension Color {
    
    init?(dictionary: [String: Double]) {
        guard let red = dictionary["red"],
              let green = dictionary["green"],
              let blue = dictionary["blue"],
              let alpha = dictionary["alpha"] else { return nil }
              
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
    
    var colorDictionary: [String: Double] {
        let color = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return [
            "red": red,
            "green": green,
            "blue": blue,
            "alpha": alpha
        ]
    }
    
}
