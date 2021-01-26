//
//  Workout.swift
//  Workouts
//
//  Created by Axel Rivera on 12/28/20.
//

import Foundation
import HealthKit

class Workout: ObservableObject {
    var id = UUID()
    var indoor = false
    var startDate: Date = Date()
    var endDate: Date = Date()
    var energyBurned: Double = 0.0
    var distance: Double = 0.0
    var source = ""
    
    var avgSpeed: Double = 0.0
    var maxSpeed: Double = 0.0
    
    init() {
        
    }
    
    convenience init(object: HKWorkout) {
        self.init()
        id = object.uuid
        indoor = object.metadata?[HKMetadataKeyIndoorWorkout] as? Bool ?? false
        startDate = object.startDate
        endDate = object.endDate
        energyBurned = object.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        distance = object.totalDistance?.doubleValue(for: .mile()) ?? 0
        source = object.sourceRevision.source.name
    }
    
    static var sample: Workout {
        let workout = Workout()
        workout.startDate = Date().addingTimeInterval(-(60 * 60))
        workout.endDate = Date()
        workout.distance = 30.0
        workout.energyBurned = 500.0
        workout.source = "Apple Watch"
        return workout
    }
}

extension Workout: Identifiable {}

extension Workout {
    
    var elapsedTime: Double {
        endDate.timeIntervalSince(startDate)
    }
}

// MARK: - Strings

extension Workout {
    
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    private var numberFormatter: NumberFormatter {
        type(of: self).numberFormatter
    }
    
    private func stringForValue(_ value: Any) -> String {
        numberFormatter.string(from: value as? NSNumber ?? 0) ?? "n/a"
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var dateFormatter: DateFormatter {
        type(of: self).dateFormatter
    }
    
    var distanceString: String {
        String(format: "%@ MI", stringForValue(distance))
    }
    
    var dateString: String {
        dateFormatter.string(from: startDate)
    }
    
    var descriptionString: String {
        indoor ? "Indoor Cycle" : "Outdoor Cycle"
    }
    
}
