//
//  WorkoutImport+Interval.swift
//  Workouts
//
//  Created by Axel Rivera on 1/29/21.
//

import Foundation
import CoreLocation

extension WorkoutImport {
    
    struct Interval {
        let startRecord: Record
        let endRecord: Record
        
        init(start: Record, end: Record) {
            startRecord = start
            endRecord = end
        }
        
        var startDate: Date? {
            startRecord.timestamp.dateValue
        }
        
        var endDate: Date? {
            endRecord.timestamp.dateValue
        }
        
        var distance: Double? {
            guard let start = startRecord.position.coordinateValue, let end = endRecord.position.coordinateValue else { return nil }
            let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
            let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
            return startLocation.distance(from: endLocation)
        }
        
        var heartRate: Double? {
            guard let start = startRecord.heartRate.heartRateValue, let end = endRecord.heartRate.heartRateValue else { return nil }
            return (start + end) / 2.0
        }
        
        var duration: Double? {
            guard let start = startRecord.timestamp.dateValue, let end = endRecord.timestamp.dateValue else { return nil }
            return end.timeIntervalSince1970 - start.timeIntervalSince1970
        }
        
        var energyBurned: Double? {
            guard let duration = duration else { return 0 }
            
            let caloriesPerHour: Double = 450.0
            let hours: Double = duration / 3600.0
            return caloriesPerHour * hours
        }
    }
    
}
