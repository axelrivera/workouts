//
//  DetailsManager.swift
//  Workouts
//
//  Created by Axel Rivera on 1/12/21.
//

import Foundation
import MapKit
import HealthKit

struct Location {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
}

extension Location: Identifiable {}

extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D]) {
        var minLat: CLLocationDegrees = 90.0
        var maxLat: CLLocationDegrees = -90.0
        var minLon: CLLocationDegrees = 180.0
        var maxLon: CLLocationDegrees = -180.0
        
        for coordinate in coordinates {
            let lat = Double(coordinate.latitude)
            let long = Double(coordinate.longitude)
            if lat < minLat {
                minLat = lat
            }
            if long < minLon {
                minLon = long
            }
            if lat > maxLat {
                maxLat = lat
            }
            if long > maxLon {
                maxLon = long
            }
        }
        
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat)*2.0, longitudeDelta: (maxLon - minLon)*2.0)
        let center = CLLocationCoordinate2DMake(maxLat - span.latitudeDelta / 4, maxLon - span.longitudeDelta / 4)
        self.init(center: center, span: span)
    }
}

class DetailsManager: ObservableObject {
    var workoutID: UUID
    
    @Published var locations = [Location]()
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        
    init(id workoutID: UUID) {
        self.workoutID = workoutID
    }
}

extension DetailsManager {
    
    func fetchRoute() {
        Log.debug("fetching route for \(workoutID.uuidString)")
        
        locations = [Location]()
        
        WorkoutDataStore.fetchRoute(for: workoutID) { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .success(let routes):
                Log.debug("got routes: \(routes.count)")
                self.fetchLocations(for: routes)
            case .failure(let error):
                Log.debug("route failed: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchLocations(for routes: [HKWorkoutRoute]) {
        var locations = [CLLocation]()
        
        routes.forEach { route in
            WorkoutDataStore.fetchLocation(for: route) { newLocations in
                Log.debug("updating new locations: \(newLocations.count)")
                locations.append(contentsOf: newLocations)
            } completionHandler: { [weak self] (result) in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        Log.debug("setup locations: \(locations)")
                        
                        self.locations = locations.map({ Location(title: "Example", coordinate: $0.coordinate)})
                        self.region = MKCoordinateRegion(coordinates: locations.map({ $0.coordinate }))
                    case .failure(let error):
                        Log.debug("fetch locations failed: \(error.localizedDescription)")
                    }
                }
            }

        }
    }
    
}
