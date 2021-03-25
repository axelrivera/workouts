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
        
    @Settings(Keys.weightInKilograms, defaultValue: Constants.defaultWeight)
    static var weight: Double
    
    static var defaultStatsFilter: Sport {
        get {
            let string = objectForKey(Keys.defaultStatsFilter) as? String ?? ""
            return Sport(rawValue: string) ?? .cycling
        }
        set {
            setValue(newValue.rawValue, for: Keys.defaultStatsFilter)
        }
    }
}
