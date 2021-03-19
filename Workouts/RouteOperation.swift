//
//  RouteOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 3/19/21.
//

import HealthKit
import CoreLocation

class RouteOperation: SyncOperation {
    private var workout: HKWorkout
    
    private(set) var locations = [CLLocation]()
    private(set) var locationName: String?
    
    private(set) var movingTime: Double = 0
    
    private(set) var speedValues = [TimeAxisValue]()
    private(set) var altitudeValues = [TimeAxisValue]()
    
    private(set) var avgSpeed: Double = 0
    private(set) var avgMovingSpeed: Double = 0
    private(set) var maxSpeed: Double = 0
    
    private(set) var minElevation: Double = 0
    private(set) var maxElevation: Double = 0
    
    init(workout: HKWorkout) {
        self.workout = workout
        super.init()
    }
    
    override func start() {
        super.start()
        
        WorkoutDataStore.fetchRoute(for: workout) { (result) in
            switch result {
            case .success(let locations):
                self.locations = locations
                self.fetchSpeedSamples()
                self.updateMovingTime()
                
                // Call fetch location name last
                // since it runs in background and calls finish
                if let location = locations.first {
                    self.fetchLocationName(location: location)
                } else {
                    self.finish()
                }
            case .failure(let error):
                Log.debug("fetching route failed: \(error.localizedDescription)")
                self.finish()
            }
        }
    }
    
    private func fetchSpeedSamples() {
        guard workout.duration > 0 else { return }
        if locations.isEmpty { return }
                
        var speedValues = [TimeAxisValue]()
        var altitudeValues = [TimeAxisValue]()
        
        let grouped = self.locations.slicedByMinute(for: \.timestamp)
        var sortedDates = grouped.keys.sorted()
        if sortedDates.count > 2 {
            sortedDates = sortedDates.dropFirst().dropLast()
        }
        let startDate = sortedDates[0]
        
        for date in sortedDates {
            let sampleDuration = date.timeIntervalSince(startDate)
            
            if let samples = grouped[date]?.map({ Double($0.speed) }), let max = samples.max() {
                speedValues.append(TimeAxisValue(duration: sampleDuration, value: nativeSpeedToLocalizedUnit(for: max)))
            }
            
            if let samples = grouped[date]?.map({ Double($0.altitude) }), let max = samples.max() {
                altitudeValues.append(TimeAxisValue(duration: sampleDuration, value: nativeAltitudeToLocalizedUnit(for: max)))
            }
        }
        
        let altitudes = self.locations.map { $0.altitude }
        
        self.speedValues = speedValues
        self.altitudeValues = altitudeValues
        maxSpeed = locations.map({ $0.speed }).max() ?? 0
        minElevation = altitudes.min() ?? 0
        maxElevation = altitudes.max() ?? 0
    }
    
    private func updateMovingTime() {
        var movingTime = 0.0
        
        for (left, right) in zip(locations, locations.dropFirst()) {
            let interval = right.timestamp.timeIntervalSince(left.timestamp)
            guard interval > 0 && left.speed > 0 && right.speed > 0 else { continue }
            movingTime += interval
        }
        
        let elapsedTime = workout.duration
        
        var avgSpeed = 0.0
        var avgMovingSpeed = 0.0
        if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
            avgSpeed = elapsedTime > 0 ? distance / elapsedTime : 0
            avgMovingSpeed = movingTime > 0 ? distance / movingTime : 0
        }
        
        self.movingTime = movingTime
        self.avgSpeed = avgSpeed
        self.avgMovingSpeed = avgMovingSpeed
    }
    
    func fetchLocationName(location: CLLocation) {
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            self.updateLocationIfNeeded(placemark: placemarks?.first)
        }
    }
    
    private func updateLocationIfNeeded(placemark: CLPlacemark?) {
        if let placemark = placemark {
            var strings = [String]()
            if let city = placemark.locality {
                strings.append(city)
            }
            
            if let state = placemark.administrativeArea {
                strings .append(state)
            }
            
            if !strings.isEmpty {
                self.locationName = strings.joined(separator: ", ")
            }
        }
        finish()
    }
}
