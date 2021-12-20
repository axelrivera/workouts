//
//  RemoteUpdator.swift
//  Workouts
//
//  Created by Axel Rivera on 12/6/21.
//

import CoreData

class RemoteUpdator {
    private let context: NSManagedObjectContext
    private let provider: HealthProvider
    
    init(context: NSManagedObjectContext) {
        self.context = context
        provider = HealthProvider.shared
    }
    
    func updatePendingWorkouts() async {
        let identifiers = Workout.pendingWorkouts(in: context)
        let totalWorkouts = identifiers.count
        Log.debug("LOG - updating location data for workouts: \(totalWorkouts)")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .willBeginProcessingRemoteLocationData,
                object: nil
            )
        }
        
        for identifier in identifiers {
            guard let workout = Workout.find(using: identifier, in: context) else { continue }
            guard let remoteWorkout = try? await provider.fetchWorkout(uuid: identifier) else { continue }
            let object = await WorkoutProcessor(workout: remoteWorkout).updateObject()
            
            context.performAndWait {
                workout.coordinatesValue = object.coordinatesValue
                workout.minElevation = object.minElevation
                workout.maxElevation = object.maxElevation
                workout.isLocationPending = false
            }
            
            let identifier = workout.workoutIdentifier
            let coordinates = workout.coordinates
            
            let userInfo: [String: Any] = [
                Notification.remoteWorkoutKey: identifier,
                Notification.coordinatesKey: coordinates
            ]
            
            context.saveOrRollback()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didUpdateRemoteLocationData, object: nil, userInfo: userInfo)
            }
        }
                
        DispatchQueue.main.async {
            Log.debug("LOG - send finish updating location data")
            NotificationCenter.default.post(
                name: .didFinishProcessingRemoteLocationData,
                object: nil
            )
        }
    }
    
    
}
