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
    enum DetailError: Error {
        case lap
    }
    
    @Published var isProcessingAnalysis: Bool = false
    @Published var isProcessingLaps: Bool = false
        
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
    
    @Published var showLaps = false
    @Published var selectedLapDistance = LapDistance.option1
    @Published private(set) var lapsDictionary = [LapDistance: [WorkoutLap]]()
        
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
        DispatchQueue.main.async {
            withAnimation {
                self.isProcessingAnalysis = true
                self.isProcessingLaps = true
            }
        }
        
        self.context = context
        self.detail = WorkoutDetail(workout: workout)
        self.points = workout.coordinates
        
        Task(priority: .userInitiated) {
            await process()
            await processLaps()
        }
    }
    
    private func process() async {
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
                
                withAnimation {
                    self.isProcessingAnalysis = false
                }
            }
        } catch {
            Log.debug("unable to process intervals")
        }
    }
    
    func selectedLaps() -> [WorkoutLap] {
        guard let laps = lapsDictionary[selectedLapDistance] else {
            return []
        }
        return laps
    }
    
    private func processLaps() async {
        async let option1 = lapsForDistance(.option1)
        async let option2 = lapsForDistance(.option2)
        async let option3 = lapsForDistance(.option3)
        async let option4 = lapsForDistance(.option4)
        
        let dictionary: [LapDistance: [WorkoutLap]] = [
            .option1: await option1,
            .option2: await option2,
            .option3: await option3,
            .option4: await option4
        ]
        
        DispatchQueue.main.async {
            withAnimation {
                self.lapsDictionary = dictionary
                self.isProcessingLaps = false
            }
        }
    }
    
    private func lapsForDistance(_ lapDistance: LapDistance) async -> [WorkoutLap] {
        do {
            guard let remoteWorkout = try? await remoteWorkout() else { throw  DetailError.lap }

            let samples = await defaultDistanceSamples(remoteWorkout: remoteWorkout)
            Log.debug("samples: \(samples.count)")
            let processor = WorkoutIntervalProcessor(workout: remoteWorkout)

            let lapIntervals = try await processor.intervalsForDistanceSamples(samples, lapDistance: lapDistance.distanceInMeters(for: sport))
            Log.debug("lap intervals: \(lapIntervals.count)")
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
            
            laps.forEach({ Log.debug(String(describing: $0))})
            
            Log.debug("laps: \(laps.count)")
            return laps
        } catch {
            Log.debug("unable to process intervals")
            return []
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

extension DetailManager {
    
    var shareViewModel: WorkoutCardViewModel {
        WorkoutCardViewModel(
            sport: sport,
            indoor: workout.indoor,
            title: workout.title,
            date: formattedWorkoutShareDateString(for: workout.start),
            distance: workout.distance > 0 ? formattedDistanceString(for: workout.distance) : nil,
            duration: formattedHoursMinutesPrettyString(for: workout.totalTime),
            elevation: workout.elevationAscended > 0 ? formattedElevationString(for: workout.elevationAscended) : nil,
            pace: workout.avgPace > 0 ? formattedRunningWalkingPaceString(for: workout.avgPace) : nil,
            coordinates: points
        )
    }
    
}
