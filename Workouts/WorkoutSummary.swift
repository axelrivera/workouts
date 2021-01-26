//
//  WorkoutSummary.swift
//  Workouts
//
//  Created by Axel Rivera on 1/11/21.
//

import Foundation

struct WorkoutSummary {
    var total: Int = 0
    var distance: Double = 0
    var energyBurned: Double = 0
    var elapsedTime: Double = 0
}

extension WorkoutSummary {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    private var numberFormatter: NumberFormatter {
        type(of: self).numberFormatter
    }
    
    private func stringForValue(_ value: Any) -> String {
        numberFormatter.string(from: value as? NSNumber ?? 0) ?? "n/a"
    }
    
    var totalString: String {
        stringForValue(total)
    }
    
    var distanceString: String {
        stringForValue(distance)
    }
    
    var energyBurnedString: String {
        stringForValue(energyBurned)
    }
    
    var elapsedTimeString: String {
        formattedTimer(for: Int(elapsedTime))
    }
    
}
