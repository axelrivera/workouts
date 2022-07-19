//
//  WorkoutSaveOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 7/17/22.
//

import Foundation
import CoreData
import HealthKit

class WorkoutUpdate: Operation {
    let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    override func main() {
        guard let processOperation = dependencies.first as? WorkoutProcess else {
            Log.debug("SYNC: dependency not found")
            return
        }
        
        let identifier = processOperation.identifier
        let result = processOperation.result
        
        viewContext.performAndWait {
            update(identifier: identifier, result: result)
        }
    }
    
}

extension WorkoutUpdate {
    
    func update(identifier: UUID, result: WorkoutProcessor.Result) {
        do {
            guard let workout = Workout.find(using: identifier, in: viewContext) else {
                throw WorkoutError("workout not found")
            }
            
            let now = Date()
            
            let zoneHeartRate = AppSettings.maxHeartRate
            let zoneValues = AppSettings.heartRateZones
            
            workout.dayOfWeek = result.dayOfWeek
            workout.avgCyclingCadence = result.avgCyclingCadence
            workout.maxCyclingCadence = result.maxCyclingCadence
            workout.avgHeartRate = result.avgHeartRate
            workout.maxHeartRate = result.maxHeartRate
            workout.energyBurned = result.energyBurned
            workout.coordinatesValue = result.coordinatesValue
            workout.minElevation = result.minElevation
            workout.maxElevation = result.maxElevation
            workout.trimp = result.trimp
            workout.avgHeartRateReserve = result.avgHeartRateReserve
            workout.updateHeartRateZones(with: zoneHeartRate, values: zoneValues)
            workout.locationUpdated = now
            workout.valuesUpdated = now
            workout.markedForDeletionDate = nil
            
            try viewContext.save()
        } catch {
            Log.debug("SYNC: failed to update workout")
        }
    }
    
}
