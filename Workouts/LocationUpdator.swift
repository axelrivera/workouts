//
//  WorkoutImageGenerator.swift
//  Workouts
//
//  Created by Axel Rivera on 7/12/22.
//

import Foundation
import CoreData
import HealthKit
import Polyline
import MapKit

//actor LocationUpdator {
//    private let identifier: UUID
//    private let provider = HealthProvider.shared
//    
//    private var remoteWorkout: HKWorkout!
//    private var workout: Workout!
//    
//    private(set) var coordinates = [CLLocationCoordinate2D]()
//    private(set) var coordinatesValue: String?
//    private(set) var minElevation: Double?
//    private(set) var maxElevation: Double?
//    
//    init(identifier: UUID) {
//        self.identifier = identifier
//    }
//}
//
//extension LocationUpdator {
//    
//    enum UpdatorError: Error, LocalizedError {
//        case missingWorkout
//        case missingRemote
//        
//        var errorDescription: String? {
//            switch self {
//            case .missingWorkout:
//                return "missing workout"
//            case .missingRemote:
//                return "missing remote workout"
//            }
//        }
//    }
//    
//    @discardableResult
//    func updateValues(context: NSManagedObjectContext) async throws -> Workout {
//        guard let remoteWorkout = try? await provider.fetchWorkout(uuid: identifier) else {
//            throw UpdatorError.missingRemote
//        }
//        
//        guard let workout = Workout.find(using: identifier, in: context) else {
//            throw UpdatorError.missingWorkout
//        }
//        
//        self.remoteWorkout = remoteWorkout
//        self.workout = workout
//        
//        await loadValues()
//        
//        context.performAndWait {
//            if let coordinatesValue = coordinatesValue {
//                workout.coordinatesValue = coordinatesValue
//            }
//            workout.isLocationPending = false
//            
//            if let minElevation = minElevation {
//                workout.minElevation = minElevation
//            }
//            
//            if let maxElevation = maxElevation {
//                workout.maxElevation = maxElevation
//            }
//            
//            // Mark as Completed
//            workout.locationUpdated = Date()
//        }
//                
//        return workout
//    }
//    
//}
//
//extension LocationUpdator {
//    
//    private func loadValues() async {
//        await updateLocationData()
//        await generateImageData()
//    }
//    
//    private func updateLocationData() async {
//        let locations: [CLLocation]
//        do {
//            locations = try await provider.fetchLocations(for: remoteWorkout)
//        } catch {
//            locations = []
//        }
//        
//        guard locations.isPresent else { return }
//
//        var coordinates = [CLLocationCoordinate2D]()
//        var altitudes = [Double]()
//        
//        if abs(workout.maxElevation) > 0 && abs(workout.maxElevation) > 0 {
//            coordinates = locations.map { $0.coordinate }
//        } else {
//            for location in locations {
//                coordinates.append(location.coordinate)
//                altitudes.append(location.altitude)
//            }
//        }
//        
//        self.coordinates = coordinates
//        coordinatesValue = Polyline(coordinates: coordinates).encodedPolyline
//        minElevation = altitudes.min()
//        maxElevation = altitudes.max()
//    }
//    
//    private func generateImageData() async {
//        if coordinates.isEmpty { return }
//
//        do {
//            let darkData = try await MKMapView.workoutMapData(coordinates: coordinates, colorScheme: .dark)
//            let lightData = try await MKMapView.workoutMapData(coordinates: coordinates, colorScheme: .light)
//
//            try FileManager.writeWorkoutImageData(
//                dark: darkData,
//                light: lightData,
//                workout: workout.workoutIdentifier
//            )
//        } catch {
//            Log.debug("unable to generate images for \(workout.workoutIdentifier): \(error.localizedDescription)")
//        }
//    }
//    
//}
