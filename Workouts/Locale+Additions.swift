//
//  Locale+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 2/8/21.
//

import Foundation

extension Locale {
    
    static func isMetric() -> Bool {
        Locale.current.usesMetricSystem
    }
    
}
