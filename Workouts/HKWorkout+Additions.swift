//
//  HKWorkout+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 6/24/22.
//

import Foundation
import HealthKit

extension HKWorkout {
    static let validStoppedEvents: [HKWorkoutEventType] = {
        [.pause, .resume]
    }()
    
    func stoppedIntervals() -> [DateInterval] {
        let events = workoutEvents ?? [HKWorkoutEvent]()
        let sortedEvents = events.sorted(by: { $0.dateInterval.start < $1.dateInterval.start })
        
        var pauseEvent: HKWorkoutEvent?
        
        var intervals = [DateInterval]()
        for event in sortedEvents {
            guard Self.validStoppedEvents.contains(event.type) else { continue }
            
            if event.type == .pause && pauseEvent == nil {
                pauseEvent = event
                continue
            }
            
            if event.type == .pause && pauseEvent != nil { continue }
            
            if let pause = pauseEvent, event.type == .resume {
                let interval = DateInterval(start: pause.dateInterval.start, end: event.dateInterval.start)
                intervals.append(interval)
                pauseEvent = nil
            }
        }
        return intervals
    }
    
}
