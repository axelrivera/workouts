//
//  Sample.swift
//  Workouts
//
//  Created by Axel Rivera on 5/27/21.
//

import CoreData

extension Sample: Identifiable {}

@objc(Sample)
class Sample: NSManagedObject {
    @NSManaged var isActive: Bool
    @NSManaged var isLocation: Bool
    @NSManaged var timestamp: Date
    @NSManaged var speed: Double
    @NSManaged var altitude: Double
    @NSManaged var heartRate: Double
    @NSManaged var cyclingCadence: Double
    @NSManaged var pace: Double
    @NSManaged var temperature: Double
    
    // MARK: - Relationships
    
    @NSManaged var workout: Workout?
    
    @NSManaged fileprivate var latitude: NSNumber?
    @NSManaged fileprivate var longitude: NSNumber?
}

extension Sample {
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude?.doubleValue, let long = longitude?.doubleValue else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    var location: CLLocation? {
        guard let coordinate = coordinate else { return nil }
        return CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: -1,
            verticalAccuracy: -1,
            course: -1,
            speed: speed,
            timestamp: timestamp
        )
    }
    
}

extension Sample {
    
    @discardableResult
    static func insert(into moc: NSManagedObjectContext, remoteSample: SampleProcessor.Record, workout: Workout) -> Sample {
        let sample = Sample(context: moc)
        sample.isActive = remoteSample.isActive
        sample.isLocation = remoteSample.isLocation
        sample.timestamp = remoteSample.timestamp
        sample.latitude = remoteSample.latitude as NSNumber
        sample.longitude = remoteSample.longitude as NSNumber
        sample.speed = remoteSample.speed
        sample.altitude = remoteSample.altitude
        sample.heartRate = remoteSample.heartRate
        sample.cyclingCadence = remoteSample.cyclingCadence
        sample.pace = remoteSample.pace
        sample.temperature = remoteSample.temperature
        sample.workout = workout
        
        return sample
    }
    
}
