//
//  LocationOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import Foundation
import HealthKit
import CoreLocation

final class LocationOperation: SyncOperation {
    private var workout: HKWorkout
    private(set) var locations = [CLLocation]()
    
    init(workout: HKWorkout) {
        self.workout = workout
        super.init()
    }
    
    override func start() {
        super.start()
        
        WorkoutDataStore.fetchRoute(for: workout) { [unowned self] (result) in
            switch result {
            case .success(let locations):
                self.locations = locations
                self.finish()
            case .failure(let error):
                Log.debug("fetching route failed: \(error.localizedDescription)")
                self.finish()
            }
        }
    }
    
}
