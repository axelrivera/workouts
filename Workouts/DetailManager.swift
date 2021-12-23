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
        case lap, metadata
    }
    
    @Published var isProcessingAnalysis: Bool = false
    @Published var isProcessingLaps: Bool = false
        
    @Published var heartRateValues = [ChartInterval]()
    @Published var speedValues = [ChartInterval]()
    @Published var cyclingCadenceValues = [ChartInterval]()
    
    @Published var paceValues = [ChartInterval]()
    @Published var bestPace: Double = 0
    
    @Published var altitudeValues = [ChartInterval]()
    @Published var minElevation: Double = 0
    @Published var maxElevation: Double = 0
    
    @Published var zones = [HRZoneSummary]()
    @Published var zoneManager: HRZoneManager = HRZoneManager()
    
    @Published var showLaps = false
    @Published var selectedLapDistance = LapDistance.option1
    @Published private(set) var lapsDictionary = [LapDistance: [WorkoutLap]]()
    
    @Published var isFavorite = false
    @Published var tags = [TagLabelViewModel]()
            
    var distanceSamples: [Quantity]?
        
    var detail: WorkoutDetailViewModel
    var context: NSManagedObjectContext
    private let metaProvider: MetadataProvider
    private let workoutTagProvider: WorkoutTagProvider
    
    init(viewModel: WorkoutDetailViewModel, context: NSManagedObjectContext) {
        self.detail = viewModel
        self.context = context
        metaProvider = MetadataProvider(context: context)
        workoutTagProvider = WorkoutTagProvider(context: context)
    }
    
    lazy var provider: HealthProvider = {
        HealthProvider.shared
    }()
}

extension DetailManager {
    
    var includesLocation: Bool { detail.includesLocation }
    
    func remoteWorkout() async throws -> HKWorkout {
        try await provider.fetchWorkout(uuid: detail.id)
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
    
    var sport: Sport { detail.sport }
        
    func processWorkout() {
        DispatchQueue.main.async {
            self.isProcessingAnalysis = true
            self.isProcessingLaps = true
        }

        Task(priority: .userInitiated) {
            context.performAndWait {
                let isFavorite = self.metaProvider.isFavorite(self.detail.id)
                let tags: [TagLabelViewModel] = self.workoutTagProvider.visibleTags(forWorkout: self.detail.id).map({ $0.viewModel() })

                DispatchQueue.main.async {
                    self.isFavorite = isFavorite
                    self.tags = tags
                }
            }
            
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
            let (speed, heartRate, cadence, altitude) = intervals.chartIntervals(duration: detail.movingTime, avgCadence: avgCadence)
            
            let paceValues: [ChartInterval]
            let bestPace: Double
            
            if sport.isWalkingOrRunning {
                let paceIntervals = try await processor.intervalsForDistanceSamples(samples, lapDistance: Sport.paceDistanceValue)
                
                let paceSamples = paceIntervals.doubleValues(keyPath: \.avgPace)
                paceValues = ChartInterval.paceChartIntervals(samples: paceSamples, movingTime: detail.movingTime)
                bestPace = paceSamples.min() ?? 0
            } else {
                paceValues = []
                bestPace = 0
            }
            
            let zoneMaxHeartRate = detail.zoneMaxHeartRate
            let zoneValues = detail.zoneValues
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
                self.paceValues = paceValues
                self.bestPace = bestPace
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
            let processor = WorkoutIntervalProcessor(workout: remoteWorkout)

            let lapIntervals = try await processor.intervalsForDistanceSamples(samples, lapDistance: lapDistance.distanceInMeters(for: sport))
            let laps = lapIntervals.map { interval in
                WorkoutLap(
                    sport: interval.sport,
                    lapNumber: interval.number,
                    distance: interval.distance,
                    duration: interval.movingTime,
                    avgSpeed: interval.avgSpeed,
                    avgPace: interval.avgPace,
                    avgCadence: interval.avgCadence,
                    avgHeartRate: interval.avgHeartRate,
                    maxHeartRate: interval.maxHeartRate
                )
            }
            return laps
        } catch {
            Log.debug("unable to process intervals")
            return []
        }
    }
    
    func updateZones(maxHeartRate: Int, values: [Int]) async {
        guard let remoteWorkout = try? await remoteWorkout() else { return }
        guard let workout = Workout.find(using: remoteWorkout.uuid, in: context) else { return }
                
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
    
    func fetchWorkout() throws -> WorkoutMetadata {
        return try metaProvider.fetchWorkout(identifier: detail.id)
    }
    
    func fetchTags() -> [TagLabelViewModel] {
        workoutTagProvider.visibleTags(forWorkout: detail.id).map({ $0.viewModel() })
    }
    
    func reloadTags() {
        WorkoutStorage.resetTags(forID: detail.id)
        
        let tags = fetchTags()
        DispatchQueue.main.async {
            withAnimation {
                self.tags = tags
            }
        }
    }
    
    func toggleFavorite() throws {
        let identifier = detail.id
        
        var isFavorite = self.isFavorite
        if isFavorite {
            try metaProvider.unfavoriteWorkout(for: identifier)
            isFavorite = false
        } else {
            try metaProvider.favoriteWorkout(for: identifier)
            isFavorite = true
        }
        
        WorkoutStorage.updateFavorite(isFavorite, forID: identifier)
        DispatchQueue.main.async {
            withAnimation {
                self.isFavorite = isFavorite
            }
        }
    }
    
}

extension DetailManager {
    
    var shareViewModel: WorkoutCardViewModel {
        WorkoutCardViewModel(
            sport: sport,
            indoor: detail.indoor,
            title: detail.title,
            date: formattedWorkoutShareDateString(for: detail.start),
            duration: formattedHoursMinutesPrettyString(for: detail.totalTime),
            distance: detail.distance > 0 ? formattedDistanceString(for: detail.distance) : nil,
            speed: detail.avgSpeed > 0 ? formattedSpeedString(for: detail.avgSpeed) : nil,
            pace: detail.avgPace > 0 ? formattedRunningWalkingPaceString(for: detail.avgPace) : nil,
            heartRate: detail.avgHeartRate > 0 ? formattedHeartRateString(for: detail.avgHeartRate) : nil,
            elevation: detail.elevationAscended > 0 ? formattedElevationString(for: detail.elevationAscended) : nil,
            calories: detail.energyBurned > 0 ? formattedCaloriesString(for: detail.energyBurned) : nil,
            coordinates: detail.coordinates
        )
    }
    
}
