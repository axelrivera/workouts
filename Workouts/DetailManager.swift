//
//  DetailManager.swift
//  Workouts
//
//  Created by Axel Rivera on 1/28/21.
//

import Foundation
import MapKit

class DetailManager: ObservableObject {
    @Published var points = [CLLocationCoordinate2D]()
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    func fetchRoute(for id: UUID) {
        WorkoutDataStore.fetchRoute(for: id) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let coordinates):
                    Log.debug("got coordinates: \(coordinates.count)")
                    self.region = MKCoordinateRegion(coordinates: coordinates)
                    self.points = coordinates
                case .failure(let error):
                    Log.debug("fetch route failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
}
