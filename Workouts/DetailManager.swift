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
import CoreData

class DetailManager: ObservableObject {
    let baseIntervalPoints : Int = 600
    
    @Published var points = [CLLocationCoordinate2D]()
    @Published var heartRateValues = [ChartInterval]()
    @Published var speedValues = [ChartInterval]()
    @Published var cyclingCadenceValues = [ChartInterval]()
    @Published var altitudeValues = [ChartInterval]()
    @Published var minElevation: Double = 0
    @Published var maxElevation: Double = 0
    
    @Published var zones = [HRZoneSummary]()
    @Published var zoneManager: HRZoneManager = HRZoneManager()
    
    @Published var detail = WorkoutDetail()
    @Published var isMapDisabled = false
    
    @Published var showLaps = false
    @Published var selectedLapDistance = LapDistance.option1 {
        didSet {
            Task(priority: .userInitiated) {
                await reloadLaps()
            }
        }
    }
    @Published var laps = [WorkoutLap]()
    
    var distanceSamples: [Quantity]?
    
    private var context: NSManagedObjectContext?
    private var _workout: Workout?
    
    var remoteIdentifier: UUID
            
    init(remoteIdentifier: UUID) {
        self.remoteIdentifier = remoteIdentifier
    }
    
    lazy var provider: HealthProvider = {
        HealthProvider.shared
    }()
}

extension DetailManager {
    
    var workout: Workout {
        if _workout == nil {
            _workout = Workout.find(using: remoteIdentifier, in: context!)
        }
        return _workout!
    }
    
    func remoteWorkout() async throws -> HKWorkout {
        try await provider.fetchWorkout(uuid: workout.remoteIdentifier!)
    }
    
    private func defaultDistanceSamples(remoteWorkout: HKWorkout) async -> [Quantity] {
        if let currentSamples = distanceSamples { return currentSamples }
        
        let interval = DateInterval(start: remoteWorkout.startDate, end: remoteWorkout.endDate)
        let source = remoteWorkout.sourceRevision.source
        
        var samples = [Quantity]()
        do {
            if sport.isCycling {
                samples = try await provider.fetchDistanceSamples(distanceType: .distanceCycling(), interval: interval, source: source)
            } else {
                samples = try await provider.fetchDistanceSamples(distanceType: .distanceWalkingRunning(), interval: interval, source: source)
            }
        } catch {
            samples = []
        }
        
        return samples.normalizedByDistance(sport: sport)
    }
    
    var sport: Sport { workout.sport }
        
    func loadWorkout(with context: NSManagedObjectContext) {
        self.context = context
        self.detail = WorkoutDetail(workout: workout)
        self.points = workout.coordinates
        
        Task(priority: .userInitiated) {
            await run()
        }
    }
    
    func run() async {
        do {
            guard let remoteWorkout = try? await remoteWorkout() else { return }
            
            let locations = (try? await provider.fetchLocations(for: remoteWorkout)) ?? []
            let samples = await defaultDistanceSamples(remoteWorkout: remoteWorkout)            
            let processor = WorkoutIntervalProcessor(workout: remoteWorkout)
            let intervals = try await processor.intervalsForDistanceSamples(samples, lapDistance: sport.defaultDistanceValue)
            let avgCadence = remoteWorkout.avgCyclingCadence ?? 0
            
            let (speed, heartRate, cadence, _, altitude) = intervals.chartIntervals(avgCadence: avgCadence)
            
            let zoneMaxHeartRate = workout.zoneMaxHeartRate
            let zoneValues = workout.zoneValues
            let zoneManager = HRZoneManager(maxHeartRate: zoneMaxHeartRate, zoneValues: zoneValues)
            
            let zones: [HRZoneSummary]
            if let fetchedZones = try? await zoneManager.fetchZones(for: remoteWorkout),  heartRate.isPresent {
                zones = fetchedZones
            } else {
                zones = []
            }
            
            let locationAltitudes = locations.altitudeValues()
            let maxElevation = locationAltitudes.max() ?? 0
            let minElevation = locationAltitudes.min() ?? 0
            
            DispatchQueue.main.async {
                self.speedValues = speed
                self.heartRateValues = heartRate
                self.cyclingCadenceValues = cadence
                self.altitudeValues = altitude
                self.minElevation = minElevation
                self.maxElevation = maxElevation
                self.zoneManager = zoneManager
                self.zones = zones
            }
        } catch {
            Log.debug("unable to process intervals")
        }
    }
    
    func reloadLapsIfNeeded() {
        guard laps.isEmpty else { return }
        Task(priority: .userInitiated) {
            await reloadLaps()
        }
    }
    
    func reloadLaps() async {
        do {
            guard let remoteWorkout = try? await remoteWorkout() else { return }
            
            let samples = await defaultDistanceSamples(remoteWorkout: remoteWorkout)
            let processor = WorkoutIntervalProcessor(workout: remoteWorkout)
            
            let lapIntervals = try await processor.intervalsForDistanceSamples(samples, lapDistance: selectedLapDistance.distanceInMeters(for: sport))
            let laps = lapIntervals.map { interval in
                WorkoutLap(
                    sport: interval.sport,
                    lapNumber: interval.number,
                    distance: interval.distance,
                    duration: interval.duration,
                    avgSpeed: interval.avgSpeed,
                    avgPace: interval.avgPace,
                    avgCadence: interval.avgCadence,
                    avgHeartRate: interval.avgHeartRate,
                    maxHeartRate: interval.maxHeartRate
                )
            }
            
            DispatchQueue.main.async {
                self.laps = laps
            }
        } catch {
            Log.debug("unable to process intervals")
        }
    }
    
    func updateZones(maxHeartRate: Int, values: [Int]) async {
        guard let remoteWorkout = try? await remoteWorkout() else { return }
        guard let context = context else { return }
        
        let workout = self.workout
        workout.updateHeartRateZones(with: maxHeartRate, values: values)
        context.saveOrRollback()
        
        let zoneManager = HRZoneManager(maxHeartRate: maxHeartRate, zoneValues: values)
        let zones: [HRZoneSummary]
        if let fetchedZones = try? await zoneManager.fetchZones(for: remoteWorkout) {
            zones = fetchedZones
        } else {
            zones = []
        }

        DispatchQueue.main.async {
            withAnimation {
                self.zoneManager = zoneManager
                self.zones = zones
            }
        }
    }
    
}
