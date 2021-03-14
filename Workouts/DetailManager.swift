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
    
    @Published var minElevation: Double = 0
    @Published var maxElevation: Double = 0
    
    @Published var heartRateValues = [ChartValue]()
    @Published var speedValues = [ChartValue]()
    @Published var cyclingCadenceValues = [ChartValue]()
    @Published var altitudeValues = [ChartValue]()
    
    var isFetchingLocation = false
    var workoutID: UUID
    private var workout: HKWorkout?
    
    init(workoutID: UUID) {
        self.workoutID = workoutID
        fetchData()
    }
    
}

extension DetailManager {
    
    func workoutInterval() -> (start: Date, end: Date)? {
        guard let workout = workout else { return nil }
        return (workout.startDate, workout.endDate)
    }
    
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
        guard let (start, end) = workoutInterval() else { return }
        
        WorkoutDataStore.fetchHeartRateStatsValue(start: start, end: end) { result in
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
        guard let (start, end) = workoutInterval() else { return }
        
        WorkoutDataStore.fetchHeartRateSamples(start: start, end: end) { result in
            switch result {
            case .success(let values):
                DispatchQueue.main.async {
                    self.heartRateValues = values.sorted(by: { (lhs, rhs) -> Bool in
                        lhs.date < rhs.date
                    })
                }
            case .failure(let error):
                Log.debug("fetching heart rate samples failed: \(error)")
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
            let altitudes = self.locations.map { $0.altitude }
            
            var speedSamples = [ChartValue]()
            var altitudeSamples = [ChartValue]()
            let minElevation = altitudes.min()
            let maxElevation = altitudes.max()
            
            var dateComponents = DateComponents()
            dateComponents.minute = 1
            
            let grouped = self.locations.slicedByMinute(for: \.timestamp)
            for date in grouped.keys.sorted() {
                if let samples = grouped[date]?.map({ Double($0.speed) }), let max = samples.max() {
                    speedSamples.append(ChartValue(date: date, value: nativeSpeedToLocalizedUnit(for: max)))
                }
                
                if let samples = grouped[date]?.map({ Double($0.altitude) }), let max = samples.max() {
                    altitudeSamples.append(ChartValue(date: date, value: nativeAltitudeToLocalizedUnit(for: max)))
                }
            }
            
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
        guard let (start, end) = workoutInterval() else { return }
        
        WorkoutDataStore.fetchCyclingCadenceSamples(start: start, end: end) { result in
            guard let values = try? result.get() else { return }
            self.updateCyclingCadenceSamples(values: values)
        }
    }
    
    private func updateCyclingCadenceSamples(values: [ChartValue]) {
        var cadenceSamples = [ChartValue]()
        
        var dateComponents = DateComponents()
        dateComponents.minute = 1
        
        let grouped = values.slicedByMinute(for: \.date)
        for date in grouped.keys.sorted() {
            if let samples = grouped[date]?.map({ Double($0.value) }), let max = samples.max() {
                cadenceSamples.append(ChartValue(date: date, value: max))
            }
        }
        
        DispatchQueue.main.async {
            self.cyclingCadenceValues = cadenceSamples
        }
    }
    
}
