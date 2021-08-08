//
//  Workout2toWorkout3MigrationPolicy.swift
//  Workouts
//
//  Created by Axel Rivera on 8/8/21.
//

import CoreData

final class Workout2ToWorkout3MigrationPolicy: NSEntityMigrationPolicy {
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        
        guard let destinationWorkout = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
            fatalError("expecting a workout")
        }
        
        let sportValue =  sInstance.value(forKey: "sportValue") as? String ?? ""
        
        var avgPace: Double = 0
        if let sport = Sport(rawValue: sportValue), sport.isWalkingOrRunning {
            let totalTime = sInstance.value(forKey: "duration") as? Double ?? 0
            let movingTime = sInstance.value(forKey: "movingTime") as? Double ?? 0
            
            let duration = movingTime > 0 ? movingTime : totalTime
            let distance = sInstance.value(forKey: "distance") as? Double ?? 0
            avgPace = calculateRunningWalkingPace(distanceInMeters: distance, duration: duration) ?? 0
        }
        
        destinationWorkout.setValue(avgPace, forKey: "avgPace")
    }
    
}
