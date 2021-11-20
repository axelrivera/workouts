//
//  Workout.swift
//  Workouts
//
//  Created by Axel Rivera on 5/27/21.
//

import CoreData
import HealthKit
import Polyline
import CoreLocation

private let MarkedForDeletionDateKey = "markedForDeletionDate"
private let SportKey = "sportValue"
private let RemoteIdentifierKey = "remoteIdentifier"
private let DistanceKey = "distance"
private let CreatedAtKey = "createdAt"
private let UpdatedAtKey = "updatedAt"
private let StartDateKey = "start"
private let EndDateKey = "end"

private let ZoneMaxHeartRateKey = "zoneMaxHeartRate"
private let ZoneValue1Key = "zoneValue1"
private let ZoneValue2Key = "zoneValue2"
private let ZoneValue3Key = "zoneValue3"
private let ZoneValue4Key = "zoneValue4"
private let ZoneValue5Key = "zoneValue5"

extension Workout: Identifiable {}

@objc(Workout)
class Workout: NSManagedObject {
    static var MAX_RETRIES: Int = 5
    
    @NSManaged var remoteIdentifier: UUID?
    @NSManaged fileprivate(set) var sportValue: String?
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
    @NSManaged var avgPace: Double
    @NSManaged var avgMovingPace: Double
    @NSManaged var elevationAscended: Double
    @NSManaged var elevationDescended: Double
    @NSManaged var maxElevation: Double
    @NSManaged var minElevation: Double
    @NSManaged var source: String
    @NSManaged var device: String?
    @NSManaged var appIdentifier: String?
    @NSManaged var showMap: Bool // deprecated
    @NSManaged var locationCity: String? // deprecated
    @NSManaged var locationState: String? // deprecated
    @NSManaged var markedForDeletionDate: Date?
    @NSManaged fileprivate(set) var totalRetries: Int
    @NSManaged var coordinatesValue: String
    
    // Heart Rate Zones
    @NSManaged private(set) var zoneMaxHeartRate: Int
    @NSManaged private(set) var zoneValue1: Int
    @NSManaged private(set) var zoneValue2: Int
    @NSManaged private(set) var zoneValue3: Int
    @NSManaged private(set) var zoneValue4: Int
    @NSManaged private(set) var zoneValue5: Int
    
    @NSManaged private(set) var createdAt: Date
    @NSManaged private(set) var updatedAt: Date
    
    // MARK: Relationships
    @NSManaged var samples: Set<Sample>
        
    // MARK: Enums
    @nonobjc
    var sport: Sport {
        get { Sport(string: sportValue ?? "") }
        set { sportValue = newValue.rawValue }
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date(), forKey: CreatedAtKey)
        setPrimitiveValue(Date(), forKey: UpdatedAtKey)
    }
    
    override func willSave() {
        super.willSave()
        setPrimitiveValue(Date(), forKey: UpdatedAtKey)
    }
        
}

extension Workout {
    var workoutIdentifier: UUID {
        remoteIdentifier!
    }
    
    var outdoor: Bool { !indoor }
    
    var coordinates: [CLLocationCoordinate2D] {
        let polyline = Polyline(encodedPolyline: coordinatesValue)
        return polyline.coordinates ?? []
    }
    
    var shouldUseMovingTime: Bool {
        movingTime < duration
    }
    
    var totalTimeLabel: String {
        shouldUseMovingTime ? "Moving Time" : "Time"
    }
    
    var totalTime: Double {
        shouldUseMovingTime ? movingTime : duration
    }
    
    var pausedTime: Double {
        duration - movingTime
    }
    
    var displayAvgSpeed: Double {
        shouldUseMovingTime ? avgMovingSpeed : avgSpeed
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
    
    var locationName: String? {
        let strings: [String] = [locationCity, locationState].compactMap{ $0 }
        if strings.isEmpty { return nil }
        return strings.joined(separator: ", ")
    }
    
    var deviceString: String? {
        guard let identifier = appIdentifier else { return nil }
        return identifier.contains(BWAppleHealthIdentifier) ? device : nil
    }
    
    var shouldRegenerateSamples: Bool {
        if indoor { return false }
        if showMap { return false }
        return totalRetries < Self.MAX_RETRIES
    }
    
    func updateRetries() {
        totalRetries += 1
    }
    
    var zoneValues: [Int] {
        [zoneValue1, zoneValue2, zoneValue3, zoneValue4, zoneValue5]
    }
    
}

// MARK: - Metadata References

extension Workout {
    
    var metadata: WorkoutMetadata? {
        guard let metadata = value(forKey: "metadata") as? [WorkoutMetadata] else { return nil }
        return metadata.first
    }
    
}

// MARK: - Helpers

extension Workout {
    
    // MARK: Predicates
    
    static func activePredicate(sport: Sport?, interval: DateInterval?) -> NSPredicate {
        var predicates = [NSPredicate]()

        if let sport = sport {
            predicates.append(Workout.predicateForSport(sport))
        }

        predicates.append(notMarkedForLocalDeletionPredicate)
        
        if let interval = interval {
            predicates.append(predicateForInterval(interval))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    static func activePredicate(sports: [Sport], interval: DateInterval?) -> NSPredicate {
        var predicates = [NSPredicate]()

        if sports.isPresent {
            predicates.append(Workout.predicateForSports(sports))
        }

        predicates.append(notMarkedForLocalDeletionPredicate)
        
        if let interval = interval {
            predicates.append(predicateForInterval(interval))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    static func datePredicateFor(start: Date, end: Date) -> NSPredicate {
        NSPredicate(
            format: "%K >= %@ AND %K <= %@",
            EndDateKey, start as NSDate,
            StartDateKey, end as NSDate
        )
    }
    
    static func predicateForInterval(_ interval: DateInterval) -> NSPredicate {
        datePredicateFor(start: interval.start, end: interval.end)
    }
    
    static func predicateForSport(_ sport: Sport) -> NSPredicate {
        NSPredicate(format: "%K == %@", SportKey, sport.rawValue)
    }
    
    static func predicateForSports(_ sports: [Sport]) -> NSPredicate {
        NSPredicate(format: "%K IN %@", SportKey, sports.map({ $0.rawValue }))
    }
    
    static func sortedByDateDescriptor(ascending: Bool = false) -> NSSortDescriptor {
        NSSortDescriptor(keyPath: \Workout.start, ascending: ascending)
    }
    
    static var notMarkedForLocalDeletionPredicate: NSPredicate {
        NSPredicate(format: "%K == NULL", MarkedForDeletionDateKey)
    }
    
    static func predicateForIdentifiers(_ identifiers: [UUID]) -> NSPredicate {
        NSPredicate(format: "%K IN %@", RemoteIdentifierKey, identifiers)
    }
    
    static func predicateForMinDistance(_ distance: Double) -> NSPredicate {
        NSPredicate(format: "%K >= %@", DistanceKey, distance as NSNumber)
    }
    
    static func predicateForMaxDistance(_ distance: Double) -> NSPredicate {
        NSPredicate(format: "%K <= %@", DistanceKey, distance as NSNumber)
    }
    
    static func distantFuturePredicate() -> NSPredicate {
        NSPredicate(format: "%K > %@", Date.distantFuture as NSDate)
    }
    
    // MARK: Reqeusts
    
    static func defaultFetchRequest() -> NSFetchRequest<Workout> {
        NSFetchRequest<Workout>(entityName: entityName)
    }
    
    static var sortedFetchRequest: NSFetchRequest<Workout> {
        let sortDescriptors = [Self.sortedByDateDescriptor()]
        let request = defaultFetchRequest()
        request.predicate = notMarkedForLocalDeletionPredicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    static func fetchWorkoutsWithRemoteIdentifiers(_ ids: [UUID], in context: NSManagedObjectContext, sorted: Bool = false) -> [Workout] {
        let request = defaultFetchRequest()
        request.predicate = predicateForIdentifiers(ids)
        request.returnsObjectsAsFaults = false
        
        if sorted {
            request.sortDescriptors = [sortedByDateDescriptor()]
        }
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    static func find(using identifier: UUID, in context: NSManagedObjectContext) -> Workout? {
        context.performAndWait {
            let request = defaultFetchRequest()
            request.predicate = NSPredicate(format: "%K == %@", RemoteIdentifierKey, identifier as NSUUID)
            return try? context.fetch(request).first
        }
    }
    
}

extension Workout {
    typealias WorkoutObject = WorkoutProcessor.Object
    
    @discardableResult
    static func insert(into context: NSManagedObjectContext, object: WorkoutObject, regenerate: Bool) -> Workout {
        context.performAndWait {
            let workout = Workout(context: context)
            updateValues(for: workout, object: object, in: context)
            return workout
        }
    }
    
    static func updateValues(for workout: Workout, object: WorkoutObject, in context: NSManagedObjectContext) {
        context.performAndWait {
            workout.remoteIdentifier = object.identifier
            workout.sport = object.sport
            workout.indoor = object.indoor
            workout.start = object.start
            workout.end = object.end
            workout.duration = object.duration
            workout.movingTime = object.movingTime
            workout.avgMovingSpeed = object.avgMovingSpeed
            workout.distance = object.distance
            workout.avgHeartRate = object.avgHeartRate
            workout.maxHeartRate = object.maxHeartRate
            workout.avgPace = object.avgPace
            workout.avgMovingPace = object.avgMovingPace
            workout.energyBurned = object.energyBurned
            workout.avgSpeed = object.avgSpeed
            workout.maxSpeed = object.maxSpeed
            workout.avgCyclingCadence = object.avgCyclingCadence
            workout.maxCyclingCadence = object.maxCyclingCadence
            workout.elevationAscended = object.elevationAscended
            workout.elevationDescended = object.elevationDescended
            workout.minElevation = object.minElevation
            workout.maxElevation = object.maxElevation
            workout.source = object.source
            workout.device = object.device
            workout.coordinatesValue = object.coordinatesValue
            
            // Heart Rate Zones
            let zoneHeartRate = AppSettings.maxHeartRate
            let zoneValues = AppSettings.heartRateZones
            workout.updateHeartRateZones(with: zoneHeartRate, values: zoneValues)
        }
    }
    
    func updateHeartRateZones(with maxHeartRate: Int, values: [Int]) {
        guard let (value1, value2, value3, value4, value5) = values.tuple as? HRZoneTuple else {
            assertionFailure("missing values")
            return
        }
                
        zoneMaxHeartRate = maxHeartRate
        zoneValue1 = value1
        zoneValue2 = value2
        zoneValue3 = value3
        zoneValue4 = value4
        zoneValue5 = value5
    }
    
    func resetSamples() {
        let samples = self.samples
        samples.forEach({ $0.workout = nil })
    }
    
}

// MARK: Batch Updates

extension Workout {
    
    static func batchUpdateHeartRateZones(with maxHeartRate: Int, values: [Int], in context: NSManagedObjectContext) {
        guard let (value1, value2, value3, value4, value5) = values.tuple as? HRZoneTuple else {
            assertionFailure("missing values")
            return
        }
                
        let update = NSBatchUpdateRequest(entityName: entityName)
        update.predicate = activePredicate(sport: nil, interval: nil)
        update.propertiesToUpdate = [
            ZoneMaxHeartRateKey: maxHeartRate,
            ZoneValue1Key: value1,
            ZoneValue2Key: value2,
            ZoneValue3Key: value3,
            ZoneValue4Key: value4,
            ZoneValue5Key: value5
        ]
        update.resultType = .updatedObjectIDsResultType
                
        do {
            let result = try context.execute(update) as? NSBatchUpdateResult
            let objects = result?.result as? [NSManagedObjectID] ?? []
            let changes = [NSUpdatedObjectsKey: objects]
                        
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    private static let DeletionAgeBeforePermanentlyDeletingObjects = TimeInterval(2 * 60)
    
    static func batchDeleteObjectsMarkedForDeletion(in context: NSManagedObjectContext) {
        let cutoff = Date(timeIntervalSinceNow: -DeletionAgeBeforePermanentlyDeletingObjects)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K < %@", MarkedForDeletionDateKey, cutoff as NSDate)
        
        let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchRequest.resultType = .resultTypeStatusOnly
        
        do {
            try context.execute(batchRequest)
        } catch {
            Log.debug("batch delete failed: \(error.localizedDescription)")
        }
    }
    
}

// MARK: - Deletion

extension Workout {
    
    func markForLocalDeletion() {
        guard isFault || markedForDeletionDate == nil else { return }
        markedForDeletionDate = Date()
    }
    
}
