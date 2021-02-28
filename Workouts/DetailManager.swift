//
//  DetailManager.swift
//  Workouts
//
//  Created by Axel Rivera on 1/28/21.
//

import Foundation
import MapKit
import SwiftUI

class DetailManager: ObservableObject {
    @Published var points = [CLLocationCoordinate2D]()
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    @Published var showDetailMap = false
    @Published var locationName: String?
    @Published var avgHeartRate: Double?
    @Published var maxHeartRate: Double?
    
    var isFetchingLocation = false
    var workout: UUID
    
    init(workoutID: UUID) {
        self.workout = workoutID
        fetchData()
    }
    
}

extension DetailManager {
    
    func fetchData() {
        fetchHeartRate()
        fetchRoute()
    }
    
    var showHeartRateSection: Bool {
        avgHeartRate != nil || maxHeartRate != nil
    }
    
    func fetchHeartRate() {
        WorkoutDataStore.fetchHeartRateSample(for: workout) { result in
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
        WorkoutDataStore.fetchRoute(for: workout) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let coordinates):
                    self.region = MKCoordinateRegion(coordinates: coordinates)
                    self.points = coordinates
                    
                    Log.debug("total coordinates: \(coordinates.count)")
                    
                    if let coordinate = coordinates.first {
                        self.fetchLocationName(coordinate: coordinate)
                    }
                case .failure(let error):
                    Log.debug("fetching route failed: \(error.localizedDescription)")
                    self.showDetailMap = false
                }
            }
        }
    }
    
    func fetchLocationName(coordinate: CLLocationCoordinate2D) {
        if isFetchingLocation { return }
        isFetchingLocation = true
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
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
                strings.append(state)
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
