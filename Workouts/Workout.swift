//
//  Workout.swift
//  Workouts
//
//  Created by Axel Rivera on 5/27/21.
//

import CoreData
import HealthKit

private let MarkedForDeletionDateKey = "markedForDeletionDate"
private let SportKey = "sportValue"

extension Workout: Identifiable {}

@objc(Workout)
class Workout: NSManagedObject {
    @NSManaged var remoteIdentifier: UUID?
    @NSManaged fileprivate(set) var sportValue: String
    @NSManaged var indoor: Bool
    @NSManaged var start: Date
    @NSManaged var end: Date
    @NSManaged var duration: Double
    @NSManaged var movingTime: Double
    @NSManaged var distance: Double
    @NSManaged var avgHeartRate: Double
    @NSManaged var maxHeartRate: Double
    @NSManaged var energyBurned: Double
    @NSManaged var avgSpeed: Double
    @NSManaged var maxSpeed: Double
    @NSManaged var avgMovingSpeed: Double
    @NSManaged var avgCyclingCadence: Double
    @NSManaged var maxCyclingCadence: Double
    @NSManaged var avgPaceDistance: Double
    @NSManaged var elevationAscended: Double
    @NSManaged var elevationDescended: Double
    @NSManaged var source: String
    @NSManaged var device: String?
    @NSManaged var appIdentifier: String?
    @NSManaged var showMap: Bool
    @NSManaged var markedForDeletionDate: Date?
    
    // MARK: Relationships
    @NSManaged var samples: Set<Sample>
    
    // MARK: Enums
    var sport: Sport {
        get { Sport(string: sportValue) }
        set { sportValue = newValue.rawValue }
    }
    
}

extension Workout {
    
    enum Time {
        case moving(duration: Double)
        case total(duration: Double)
        
        var title: String {
            switch self {
            case .moving:
                return "Moving Time"
            case .total:
                return "Time"
            }
        }
    }
    
    var totalTime: Time {
        if movingTime > 0 && movingTime < duration {
            return .moving(duration: movingTime)
        } else {
            return .total(duration: duration)
        }
    }
    
    var title: String {
        if Sport.indoorOutdoorList.contains(sport) {
            return [indoor ? "Indoor" : "Outdoor", sport.name].joined(separator: " ")
        } else {
            return sport.name
        }
    }
    
    var detailTitle: String {
        switch sport {
        case .cycling:
            return "Ride"
        case .running:
            return "Run"
        case .walking:
            return "Walk"
        default:
            return "Summary"
        }
    }
    
    var deviceString: String? {
        guard let identifier = appIdentifier else { return nil }
        return identifier.contains(BWAppleHealthIdentifier) ? device : nil
    }
    
}

extension Workout {
    
    static func predicateForSport(_ sport: Sport) -> NSPredicate {
        NSPredicate(format: "%K == %@", SportKey, sport.rawValue)
    }
    
    static func sortedByDateDescriptor() -> NSSortDescriptor {
        NSSortDescriptor(keyPath: \Workout.start, ascending: false)
    }
    
    static var notMarkedForLocalDeletionPredicate: NSPredicate {
        NSPredicate(format: "%K == NULL", MarkedForDeletionDateKey)
    }
    
    static func defaultFetchRequest() -> NSFetchRequest<Workout> {
        NSFetchRequest<Workout>(entityName: "Workout")
    }
    
    static var sortedFetchRequest: NSFetchRequest<Workout> {
        let sortDescriptors = [Self.sortedByDateDescriptor()]
        let request = defaultFetchRequest()
        request.predicate = notMarkedForLocalDeletionPredicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    static func fetchWorkoutsWithRemoteIdentifiers(_ ids: [UUID], in context: NSManagedObjectContext) -> [Workout] {
        let request = defaultFetchRequest()
        request.predicate = NSPredicate(format: "%K in %@", "remoteIdentifier", ids)
        request.returnsObjectsAsFaults = false
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
}

extension Workout {
    
    @discardableResult
    static func insert(into moc: NSManagedObjectContext, remoteWorkout: HKWorkout) -> Workout {
        let processor = WorkoutProcessor(workout: remoteWorkout)
        processor.generateRecords()

        Log.debug("inserting workout: \(remoteWorkout.uuid), records: \(processor.records.count)")

        let workout = Workout(context: moc)
        workout.remoteIdentifier = remoteWorkout.uuid
        workout.sport = remoteWorkout.workoutActivityType.sport()
        workout.indoor = remoteWorkout.isIndoor
        workout.start = remoteWorkout.startDate
        workout.end = remoteWorkout.endDate
        workout.duration = processor.duration
        workout.movingTime = processor.movingTime
        workout.avgMovingSpeed = processor.avgMovingSpeed
        workout.distance = remoteWorkout.totalDistance?.doubleValue(for: .meter()) ?? 0
        workout.avgHeartRate = processor.avgHeartRate
        workout.maxHeartRate = processor.maxHeartRate
        workout.energyBurned = remoteWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        workout.avgSpeed = remoteWorkout.avgSpeed?.doubleValue(for: .metersPerSecond()) ?? 0
        workout.maxSpeed = remoteWorkout.maxSpeed?.doubleValue(for: .metersPerSecond()) ?? 0
        workout.avgCyclingCadence = remoteWorkout.avgCyclingCadence ?? 0
        workout.maxCyclingCadence = remoteWorkout.maxCyclingCadence ?? 0
        workout.elevationAscended = remoteWorkout.elevationAscended?.doubleValue(for: .meter()) ?? 0
        workout.elevationDescended = remoteWorkout.elevationDescended?.doubleValue(for: .meter()) ?? 0
        workout.source = remoteWorkout.sourceRevision.source.name
        workout.device = remoteWorkout.device?.name
        workout.showMap = processor.showMap

        for remoteSample in processor.records {
            Sample.insert(into: moc, remoteSample: remoteSample, workout: workout)
        }

        return workout
    }

    
}

// MARK: - Deletion

extension Workout {
    
    func markForLocalDeletion() {
        guard isFault || markedForDeletionDate == nil else { return }
        markedForDeletionDate = Date()
    }
    
}
