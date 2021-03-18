//
//  DetailManager.swift
//  Workouts
//
//  Created by Axel Rivera on 1/28/21.
//

import Foundation
import MapKit
import SwiftUI
import HealthKit

class DetailManager: ObservableObject {
    @Published var locations = [CLLocation]() {
        didSet {
            points = locations.map { $0.coordinate }
        }
    }
    
    @Published var points = [CLLocationCoordinate2D]()
    
    @Published var showDetailMap = false
    @Published var locationName: String?
    @Published var avgHeartRate: Double?
    @Published var maxHeartRate: Double?
    
    @Published var movingTime: Double = 0
    @Published var bestPace: Double = 0
    
    @Published var minElevation: Double = 0
    @Published var maxElevation: Double = 0
    
    @Published var heartRateValues = [TimeAxisValue]()
    @Published var speedValues = [TimeAxisValue]()
    @Published var cyclingCadenceValues = [TimeAxisValue]()
    @Published var paceValues = [TimeAxisValue]()
    @Published var altitudeValues = [TimeAxisValue]()
    
    var isFetchingLocation = false
    var workoutID: UUID
    private var workout: HKWorkout?
    
    init(workoutID: UUID) {
        self.workoutID = workoutID
        fetchData()
    }
    
}

extension DetailManager {
    
    func fetchWorkout(completionHandler: @escaping (() -> Void)) {
        WorkoutDataStore.fetchWorkout(for: workoutID) { (workout) in
            self.workout = workout
            completionHandler()
        }
    }
    
    func fetchData() {
        func fetchDataDependencies() {
            fetchHeartRate()
            fetchRoute()
            fetchHeartRateSamples()
            fetchPaceSamples()
            fetchCyclingCadenceSamples()
        }
        
        if let _ = workout {
            fetchDataDependencies()
        } else {
            fetchWorkout {
                fetchDataDependencies()
            }
        }
    }
    
    var showHeartRateSection: Bool {
        avgHeartRate != nil || maxHeartRate != nil
    }
    
    func fetchHeartRate() {
        guard let workout = workout else { return }
        
        WorkoutDataStore.fetchHeartRateStatsValue(workout: workout) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let sample):
                    self.avgHeartRate = sample.avg
                    self.maxHeartRate = sample.max
                case .failure(let error):
                    Log.debug("fetching heart rate failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchRoute() {
        guard let workout = workout else { return }
                
        WorkoutDataStore.fetchRoute(for: workout) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let locations):
                    self.locations = locations
                    
                    if let location = locations.first {
                        self.fetchLocationName(location: location)
                    }
                    
                    self.fetchSpeedSamples()
                    self.updateMovingTime()
                case .failure(let error):
                    Log.debug("fetching route failed: \(error.localizedDescription)")
                    self.showDetailMap = false
                }
            }
        }
    }
    
    func fetchLocationName(location: CLLocation) {
        if isFetchingLocation { return }
        isFetchingLocation = true
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) { placemarks, error -> Void in
            self.isFetchingLocation = false
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
        
        showDetailsMapIfNeeded()
    }
    
    private func showDetailsMapIfNeeded() {
        DispatchQueue.main.async {
            withAnimation {
                self.showDetailMap = !self.points.isEmpty
            }
        }
    }
    
}

// MARK: - Heart Rate Samples

extension DetailManager {
    
    func fetchHeartRateSamples() {
        guard let workout = workout else { return }
        
        WorkoutDataStore.fetchHeartRateSamples(workout: workout) { result in
            guard let samples = try? result.get(), !samples.isEmpty else { return }
            
            let startDate = samples[0].timestamp
            let values = samples.map { quantity in
                TimeAxisValue(duration: quantity.timestamp.timeIntervalSince(startDate), value: quantity.value)
            }
            
            DispatchQueue.main.async {
                self.heartRateValues = values
            }
        }
    }
    
    func fetchPaceSamples() {
        guard let workout = workout, Workout.paceActivities.contains(workout.workoutActivityType) else { return }
        
        WorkoutDataStore.fetchRunningWalkingPaceSamples(workout: workout) { result in
            guard let samples = try? result.get(), !samples.isEmpty else { return }
            
            let bestPace = samples.map({ $0.value }).min() ?? 0
            let startDate = samples[0].timestamp
            let values = samples.map { quantity in
                TimeAxisValue(duration: quantity.timestamp.timeIntervalSince(startDate), value: quantity.value)
            }
            
            DispatchQueue.main.async {
                self.paceValues = values
                self.bestPace = bestPace
            }
        }
    }
    
}

// MARK: - Speed & Altitude Samples

extension DetailManager {
    
    func fetchSpeedSamples() {
        guard let duration = workout?.duration, duration > 0 else { return }
        if locations.isEmpty { return }
                
        DispatchQueue.global(qos: .userInteractive).async {
            var speedSamples = [TimeAxisValue]()
            var altitudeSamples = [TimeAxisValue]()
            
            let grouped = self.locations.slicedByMinute(for: \.timestamp)
            var sortedDates = grouped.keys.sorted()
            if sortedDates.count > 2 {
                sortedDates = sortedDates.dropFirst().dropLast()
            }
            let startDate = sortedDates[0]
            
            for date in sortedDates {
                let sampleDuration = date.timeIntervalSince(startDate)
                
                if let samples = grouped[date]?.map({ Double($0.speed) }), let max = samples.max() {
                    speedSamples.append(TimeAxisValue(duration: sampleDuration, value: nativeSpeedToLocalizedUnit(for: max)))
                }
                
                if let samples = grouped[date]?.map({ Double($0.altitude) }), let max = samples.max() {
                    altitudeSamples.append(TimeAxisValue(duration: sampleDuration, value: nativeAltitudeToLocalizedUnit(for: max)))
                }
            }
            
            let altitudes = self.locations.map { $0.altitude }
            let minElevation = altitudes.min()
            let maxElevation = altitudes.max()
            
            DispatchQueue.main.async {
                self.speedValues = speedSamples
                self.minElevation = minElevation ?? 0
                self.maxElevation = maxElevation ?? 0
                self.altitudeValues = altitudeSamples
            }
        }
    }
    
    func updateMovingTime() {
        var duration = 0.0
        for (left, right) in zip(locations, locations.dropFirst()) {
            let interval = right.timestamp.timeIntervalSince(left.timestamp)
            guard interval > 0 && left.speed > 0 && right.speed > 0 else { continue }
            duration += interval
        }
        DispatchQueue.main.async {
            self.movingTime = duration
        }
    }
    
    func fetchCyclingCadenceSamples() {
        guard let workout = workout else { return }
        
        WorkoutDataStore.fetchCyclingCadenceSamples(workout: workout) { result in
            guard let samples = try? result.get(), !samples.isEmpty else { return }
            self.updateCyclingCadenceSamples(samples)
        }
    }
    
    private func updateCyclingCadenceSamples(_ samples: [Quantity]) {
        var cadenceSamples = [TimeAxisValue]()
                
        let grouped = samples.slicedByMinute(for: \.timestamp)
        let sortedDates = grouped.keys.sorted()
        let startDate = sortedDates[0]
        
        for date in sortedDates {
            let sampleDuration = date.timeIntervalSince(startDate)
            
            if let slice = grouped[date]?.map({ Double($0.value) }), let max = slice.max() {
                cadenceSamples.append(TimeAxisValue(duration: sampleDuration, value: max))
            }
        }
        
        DispatchQueue.main.async {
            self.cyclingCadenceValues = cadenceSamples
        }
    }
    
}
