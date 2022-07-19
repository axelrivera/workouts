//
//  SynchronizerStorage.swift
//  Workouts
//
//  Created by Axel Rivera on 7/18/22.
//

import Foundation
import HealthKit

class SyncronizerStorage {
    private let queue = DispatchQueue(label: "synchronizerStorage.queue")
    
    private var _isAuthorized = false
    private var _regenerate = false
    private var _resetAnchor = false
    private var _anchor: HKQueryAnchor?
    
    private var _pendingWorkouts = Set<UUID>()
    
    var isAuthorized: Bool {
        get {
            queue.sync {
                return _isAuthorized
            }
        }
        set {
            queue.sync {
                _isAuthorized = newValue
            }
        }
    }
    
    var regenerate: Bool {
        get {
            queue.sync {
                return _regenerate
            }
        }
        set {
            queue.sync {
                _regenerate = newValue
            }
        }
    }
    
    var resetAnchor: Bool {
        get {
            queue.sync {
                _resetAnchor
            }
        }
        
        set {
            queue.sync {
                _resetAnchor = newValue
            }
        }
    }
    
    var anchor: HKQueryAnchor? {
        get {
            queue.sync {
                return _anchor
            }
        }
        set {
            queue.sync {
                AppSettings.workoutsQueryAnchor = newValue
                _anchor = newValue
            }
        }
    }
    
    var isProcessingWorkouts: Bool {
        queue.sync {
            return _pendingWorkouts.isPresent
        }
    }
    
    func isProcessing(workoutID id: UUID) -> Bool {
        queue.sync {
            return _pendingWorkouts.contains(id)
        }
    }
    
    func addWorkout(withID id: UUID) {
        queue.sync {
            let _ = _pendingWorkouts.insert(id)
        }
    }
    
    func removeWorkout(withID id: UUID) {
        queue.sync {
            let _ = _pendingWorkouts.remove(id)
        }
    }
}
