//
//  MovingSpeedProcessor.swift
//  MovingSpeedProcessor
//
//  Created by Axel Rivera on 8/11/21.
//

import CoreLocation
import HealthKit

class MovingTimeProcessor {
    private static let validEvents: [HKWorkoutEventType] = [.pause, .resume]
    
    let workout: HKWorkout
    let locations: [CLLocation]
        
    init(workout: HKWorkout, locations: [CLLocation]) {
        self.workout = workout
        self.locations = locations
    }
    
    private lazy var workoutEvents: [HKWorkoutEvent] = {
        workout.workoutEvents ?? []
    }()
    
    private lazy var stoppedIntervals: [DateInterval] = {
        workoutEvents.isEmpty ? manualIntervals() : systemIntervals()
    }()
    
}

// MARK: - External Method

extension MovingTimeProcessor {
    
    func movingTime() -> Double {
        if let workoutMovingTime = self.workoutMovingTime {
            return workoutMovingTime
        }
        
        if locations.isEmpty {
            return duration
        } else {
            return duration - pausedTime()
        }
    }
    
}

// MARK: - Workout Helpers

extension MovingTimeProcessor {
    
    var start: Date {
        workout.startDate
    }
    
    var end: Date {
        workout.endDate
    }
    
    var duration: Double {
        workout.duration
    }
    
    var workoutMovingTime: Double? {
        workout.movingTime
    }
    
}

// MARK: - Records

extension MovingTimeProcessor {
    
    private func pausedTime() -> Double {
        var pauseDuration: Double = 0
        for interval in stoppedIntervals {
            pauseDuration += interval.duration
        }
        return pauseDuration
    }
    
}

// MARK: - Events

extension MovingTimeProcessor {
    
    private func totalDistance() -> Double {
        workout.totalDistance?.doubleValue(for: .meter()) ?? 0
    }
    
    private func avgSpeed() -> Double {
        if let speed = workout.avgSpeed?.doubleValue(for: .metersPerSecond()) {
            return speed
        }
        
        guard workout.duration > 0 else { return 0 }
        let distance = totalDistance()
        return distance / workout.duration
    }
    
    private func systemIntervals() -> [DateInterval] {
        let sortedEvents = workoutEvents.sorted(by: { $0.dateInterval.start < $1.dateInterval.start })
        
        var pauseEvent: HKWorkoutEvent?
        
        var intervals = [DateInterval]()
        for event in sortedEvents {
            guard Self.validEvents.contains(event.type) else { continue }
            
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
    
    private func manualIntervals() -> [DateInterval] {
        let speed = avgSpeed()
        let baseDistance = max(speed * 0.25, 1.0)
        
        var pauseTimestamp: Date?
        
        var intervals = [DateInterval]()
        for (prev, current) in zip(locations, locations.dropFirst()) {
            let distance = current.distance(from: prev)
                        
            if distance <= baseDistance && pauseTimestamp == nil {
                pauseTimestamp = current.timestamp
                continue
            }
            
            if distance <= baseDistance && pauseTimestamp != nil { continue }
            
            if let pause = pauseTimestamp, distance > baseDistance {
                let interval = DateInterval(start: pause, end: current.timestamp)
                
                if interval.duration > 1.0 {
                    intervals.append(interval)
                }
                pauseTimestamp = nil
            }
        }
        
        if let pause = pauseTimestamp, let last = locations.last?.timestamp {
            let interval = DateInterval(start: pause, end: last)
            if interval.duration > 0.0 {
                intervals.append(interval)
            }
        }
        
        return intervals
    }
    
}

extension MovingTimeProcessor {
    
    final class Record {
        let timestamp: Date
        var isActive = false
        
        init(timestamp: Date) {
            self.timestamp = timestamp
        }
    }
    
}
