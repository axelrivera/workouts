//
//  AppSettings.swift
//  Workouts
//
//  Created by Axel Rivera on 2/8/21.
//

import Foundation
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
    struct Keys {
        static let weightInKilograms = "arn_weight_in_kilograms"
        static let defaultStatsFilter = "arn_default_stats_filter"
        static let defaultWorkoutsFilter = "arn_default_workouts_filter"
        static let mockPurchaseActive = "arn_mock_purchase_active"
        static let maxHeartRate = "arn_max_heart_rate"
        static let heartRateZones = "arn_heart_rate_zones"
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
    
    @Settings(Keys.maxHeartRate, defaultValue: HRZoneManager.Defaults.max)
    static var maxHeartRate: Int
    
    // heart Rate Zones
    static var heartRateZones: [Int] {
        get {
            var zones = objectForKey(Keys.heartRateZones) as? [Int] ?? []
            if zones.count == 4 {
                return zones
            }
            
            guard zones.isEmpty else { fatalError("invalid value count") }
            
            let max = Double(maxHeartRate)
            let percents = HRZoneManager.Defaults.percents
            zones = HRZoneManager.calculateDefaultZones(for: max, percentZones: percents)
            setValue(zones, for: Keys.heartRateZones)
            return zones
        }
        set {
            setValue(newValue, for: Keys.heartRateZones)
        }
    }
        
    @Settings(Keys.weightInKilograms, defaultValue: Constants.defaultWeight)
    static var weight: Double
    
    #if DEVELOPMENT_BUILD
    @Settings(Keys.mockPurchaseActive, defaultValue: false)
    static var mockPurchaseActive: Bool
    #endif
    
    static var defaultStatsFilter: Sport? {
        get {
            guard let string = objectForKey(Keys.defaultStatsFilter) as? String else { return .cycling }
            return Sport(rawValue: string)
        }
        set {
            setValue(newValue?.rawValue, for: Keys.defaultStatsFilter)
        }
    }
    
    static var defaultWorkoutsFilter: Sport? {
        get {
            guard let string = objectForKey(Keys.defaultWorkoutsFilter) as? String else { return nil }
            return Sport(rawValue: string)
        }
        set {
            setValue(newValue?.rawValue, for: Keys.defaultWorkoutsFilter)
        }
    }
    
}
