//
//  AppSettings.swift
//  Workouts
//
//  Created by Axel Rivera on 2/8/21.
//

import SwiftUI
import HealthKit

@propertyWrapper
struct Settings<T> {
    let key: String
    let defaultValue: T

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key); UserDefaults.standard.synchronize() }
    }
}

struct AppSettings {
    static let DEFAULT_MAX_HEART_RATE: Int = 200
    static let DEFAULT_RESTING_HEART_RATE: Int = 60
    
    static var CURRENT_VERSION: Int = {
        let (_, build) = systemVersionAndBuild()
        return Int(build) ?? 0
    }()
    
    struct Keys {
        static let version = "arn_app_version"
        static let defaultStatsFilter = "arn_default_stats_filter"
        static let shareSettings = "arn_share_settings"
        static let useFormulaMaxHeartRate = "arn_use_formula_max_heart_rate"
        static let maxHeartRate = "arn_max_heart_rate"
        static let useHealthRestingHeartRate = "arn_use_health_resting_heart_rate"
        static let restingHeartRate = "arn_resting_heart_rate"
        static let heartRateZones = "arn_heart_rate_zones"
        static let heartRateZonePercents = "arn_heart_rate_zone_percents"
        static let workoutsQueryAnchor = "arn_workouts_query_anchor"
        static let yearToDateTimeframe = "arn_year_to_date_timeframe"
        static let allTimeTimeframe = "arn_all_time_timeframe"
        static let tagsTimeframe = "arn_tag_timeframe"
        static let dashboardStartDate = "arn_dashboard_start_date"
        static let dashboardInterval = "arn_dashboard_interval"
    }
    
    struct RemoteKeys {
        static let initialTagsReady = "arn_app_initial_tags_ready"
    }

    static func synchronize() {
        UserDefaults.standard.synchronize()
    }
    
    private static func objectForKey(_ key: String) -> Any? {
        UserDefaults.standard.object(forKey: key)
    }
    
    private static func setValue(_ value: Any?, for key: String) {
        UserDefaults.standard.setValue(value, forKey: key)
    }
        
    @Settings(Keys.version, defaultValue: 0)
    static var version: Int
    
    @Settings(Keys.useFormulaMaxHeartRate, defaultValue: true)
    static var useFormulaMaxHeartRate: Bool
    
    @Settings(Keys.useHealthRestingHeartRate, defaultValue: true)
    static var useHealthRestingHeartRate: Bool
    
    // Max Heart Rate
    // In most cases this getter thouls not be used directly by the app (unless for specific reasons)
    // The getter should be accessed from the HealthProvider instead to properly set the default values when needed
    
    @Settings(Keys.maxHeartRate, defaultValue: DEFAULT_MAX_HEART_RATE)
    static var maxHeartRate: Int
    
    @Settings(Keys.restingHeartRate, defaultValue: DEFAULT_RESTING_HEART_RATE)
    static var restingHeartRate: Int
    
    // Heart Rate Zones
    // In most cases this getter thouls not be used directly by the app (unless for specific reasons)
    // The getter should be accessed from the HealthProvider instead to properly set the default values when needed

    //@available(*, deprecated, message: "use heartRatezonePercents instead")
    static var heartRateZones: [Int] {
        get {
            objectForKey(Keys.heartRateZones) as? [Int] ?? []
        }
        set {
            setValue(newValue, for: Keys.heartRateZones)
        }
    }
    
    static var heartRateZonePercents: [Int] {
        get {
            objectForKey(Keys.heartRateZonePercents) as? [Int] ?? []
        }
        set {
            setValue(newValue, for: Keys.heartRateZonePercents)
        }
    }
    
    static var dashboardStartDate: Date? {
        get {
            if let string = objectForKey(Keys.dashboardStartDate) as? String {
                return ISO8601DateFormatter().date(from: string)
            } else {
                return nil
            }
        }
        set {
            if let date = newValue {
                let string = ISO8601DateFormatter().string(from: date)
                setValue(string, for: Keys.dashboardStartDate)
            } else {
                setValue(nil, for: Keys.dashboardStartDate)
            }
        }
    }
    
    @Settings(Keys.dashboardInterval, defaultValue: DashboardViewManager.IntervalType.month.rawValue)
    static var dashboardInterval: String
    
    static var shareSettings: ShareSettings {
        get {
            do {
                guard let data = objectForKey(Keys.shareSettings) as? Data else { throw WorkoutError("data not found") }
                return try JSONDecoder().decode(ShareSettings.self, from: data)
            } catch {
                return ShareSettings.defaultValue()
            }
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            setValue(data, for: Keys.shareSettings)
        }
    }
    
    static var workoutsQueryAnchor: HKQueryAnchor? {
        get {
            do {
                guard let data = objectForKey(Keys.workoutsQueryAnchor) as? Data else { throw WorkoutError("data not found") }
                let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
                return anchor
            } catch {
                return nil
            }
        }
        set {
            if let value = newValue {
                let data = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
                setValue(data, for: Keys.workoutsQueryAnchor)
            } else {
                setValue(nil, for: Keys.workoutsQueryAnchor)
            }
        }
    }
    
}
