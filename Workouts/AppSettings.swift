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
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

struct AppSettings {
    struct Keys {
        static let propertyName = "arn_property_name"
    }

    static func synchronize() {
        UserDefaults.standard.synchronize()
    }
    
    //    @Settings(Keys.nameOfKey, defaultValue: 0)
    //    static var propertyName: Double
    
}
