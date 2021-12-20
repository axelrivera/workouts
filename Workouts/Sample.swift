//
//  Sample.swift
//  Workouts
//
//  Created by Axel Rivera on 5/27/21.
//

import CoreData
import CoreLocation

extension Sample: Identifiable {}

private let WorkoutKey = "workout"
private let ActiveKey = "isActive"
private let HeartRateKey = "heartRate"
private let TimestampKey = "timestamp"

@objc(Sample)
class Sample: NSManagedObject {
    @NSManaged var isActive: Bool
    @NSManaged var isLocation: Bool
    @NSManaged var timestamp: Date
    @NSManaged var speed: Double
    @NSManaged var altitude: Double
    @NSManaged var heartRate: Double
    @NSManaged var cyclingCadence: Double
    @NSManaged var paceDistance: Double
    @NSManaged var paceDuration: Double
    @NSManaged var temperature: Double
    
    // MARK: - Relationships
    
    @NSManaged var workout: Workout?
    
    @NSManaged fileprivate var latitude: NSNumber?
    @NSManaged fileprivate var longitude: NSNumber?
}

extension Sample {
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude?.doubleValue, let long = longitude?.doubleValue else { return nil }
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
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
    
    static func predicateForWorkout(_ workout: Workout) -> NSPredicate {
        NSPredicate(format: "%K = %@", WorkoutKey, workout)
    }
    
    static func activePredicate() -> NSPredicate {
        NSPredicate(format: "%K = %@", ActiveKey, NSNumber(booleanLiteral: true))
    }
    
    static func predicateForStart(_ start: Date, end: Date) -> NSPredicate {
        NSPredicate(
            format: "%K >= %@ AND %K <= %@",
            TimestampKey, start as NSDate,
            TimestampKey, end as NSDate
        )
    }
    
    static func predicateForDateInterval(_ interval: DateInterval) -> NSPredicate {
        predicateForStart(interval.start, end: interval.end)
    }
    
    static func predicate(for workout: Workout, interval: DateInterval) -> NSPredicate {
        let predicates = [predicateForWorkout(workout), predicateForDateInterval(interval)]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    static func heartRatePredicateForWorkout(_ workout: Workout, range: HRZoneManager.ZoneRange?) -> NSPredicate {
        var predicate: NSPredicate
        
        if let range = range {
            if range.low == 0 && range.high > 0 {
                predicate = NSPredicate(format: "%K > %@ AND %K <= %@", HeartRateKey, 0 as NSNumber, HeartRateKey, range.high as NSNumber)
            } else if range.low > 0 && range.high == 0 {
                predicate = NSPredicate(format: "%K >= %@", HeartRateKey, range.low as NSNumber)
            } else {
                predicate = NSPredicate(format: "%K >= %@ AND %K <= %@", HeartRateKey, range.low as NSNumber, HeartRateKey, range.high as NSNumber)
            }
        } else {
            predicate = NSPredicate(format: "%K > %@", HeartRateKey, 0 as NSNumber)
        }
        
        let predicates = [predicateForWorkout(workout), activePredicate(), predicate]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    static func sortedByTimestampDescriptor() -> NSSortDescriptor {
        NSSortDescriptor(keyPath: \Sample.timestamp, ascending: true)
    }
    
}



extension Sample {
    
    @discardableResult
    static func insert(into moc: NSManagedObjectContext, remoteSample: SampleProcessor.Record, workout: Workout) -> Sample {
        let sample = Sample(context: moc)
//        sample.isActive = remoteSample.isActive
//        sample.isLocation = remoteSample.isLocation
//        sample.timestamp = remoteSample.timestamp
//        sample.latitude = remoteSample.latitude as NSNumber
//        sample.longitude = remoteSample.longitude as NSNumber
//        sample.speed = remoteSample.speed
//        sample.altitude = remoteSample.altitude
//        sample.heartRate = remoteSample.heartRate
//        sample.cyclingCadence = remoteSample.cyclingCadence
//        sample.temperature = remoteSample.temperature
//        sample.workout = workout
        
        return sample
    }
    
    static func batchDeleteOrphanedObjects(in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = nil", "workout")
        
        let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchRequest.resultType = .resultTypeStatusOnly
                
        do {
            try context.execute(batchRequest)
        } catch {
            Log.debug("sample batch delete failed: \(error.localizedDescription)")
        }
    }
    
}
