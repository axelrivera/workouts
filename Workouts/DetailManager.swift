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
    
    @Published var detail = WorkoutDetailViewModel.empty()
    @Published var isProcessingAnalysis: Bool = false
    @Published var isProcessingLaps: Bool = false
        
    @Published var heartRateValues = [ChartInterval]()
    @Published var speedValues = [ChartInterval]()
    @Published var cyclingCadenceValues = [ChartInterval]()
    
    @Published var paceValues = [ChartInterval]()
    @Published var bestPace: Double = 0
    
    @Published var altitudeValues = [ChartInterval]()
    
    @Published var zones = [HRZoneSummary]()
    
    @Published var showLaps = false
    @Published var selectedLapDistance = LapDistance.option1
    @Published private(set) var lapsDictionary = [LapDistance: [WorkoutLap]]()
    
    @Published var isFavorite = false
    @Published var tags = [TagLabelViewModel]()
                
    var distanceSamples: [Quantity]?
    
    var id: UUID
    var context: NSManagedObjectContext
    
    private lazy var healthProvider = HealthProvider.shared
    private let metaProvider: MetadataProvider
    private let workoutTagProvider: WorkoutTagProvider
    private let zonesProvider = HRZonesProvider()
    
    init(id: UUID, context: NSManagedObjectContext) {
        self.id = id
        self.context = context
        metaProvider = MetadataProvider(context: context)
        workoutTagProvider = WorkoutTagProvider(context: context)
    }
}

extension DetailManager {
    
    var includesLocation: Bool { detail.includesLocation }
    
    func remoteWorkout() async throws -> HKWorkout {
        try await healthProvider.fetchWorkout(uuid: id)
    }
    
    private func defaultDistanceSamples(remoteWorkout: HKWorkout) async -> [Quantity] {
        if let currentSamples = distanceSamples { return currentSamples }

        let interval = DateInterval(start: remoteWorkout.startDate, end: remoteWorkout.endDate)
        let source = remoteWorkout.sourceRevision.source

        var samples = [Quantity]()
        do {
            if sport.isCycling {
                samples = try await healthProvider.fetchDistanceSamples(distanceType: .distanceCycling(), interval: interval, source: source)
            } else {
                samples = try await healthProvider.fetchDistanceSamples(distanceType: .distanceWalkingRunning(), interval: interval, source: source)
            }
        } catch {
            Log.debug("failed distance samples: \(error.localizedDescription)")
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
            Log.debug("DETAIL: processing workout")
            
            await context.perform {
                let viewModel = Workout.find(using: self.id, in: self.context)?.detailViewModel ?? WorkoutDetailViewModel.empty()
                let isFavorite = self.metaProvider.isFavorite(self.id)
                let tags: [TagLabelViewModel] = self.workoutTagProvider.visibleTags(forWorkout: self.id).map({ $0.viewModel() })

                DispatchQueue.main.async {
                    self.detail = viewModel
                    self.isFavorite = isFavorite
                    self.tags = tags
                }
            }
            
            Log.debug("DETAIL: processing metrics")
            
            await process()
            await processLaps()
        }
    }
    
    private func process() async {
        do {
            guard let remoteWorkout = try? await remoteWorkout() else {
                throw WorkoutError("missing workout")
            }
            
            let samples = await defaultDistanceSamples(remoteWorkout: remoteWorkout)
            Log.debug("DETAIL: distance samples \(samples.count)")
            
            let processor = WorkoutIntervalProcessor(workout: remoteWorkout)
            let intervals = await processor.intervalsForDistanceSamples(samples, lapDistance: sport.defaultDistanceValue)
            
            let avgCadence = remoteWorkout.avgCyclingCadenceValue
            let (speed, heartRate, cadence, altitude) = intervals.chartIntervals(duration: detail.movingTime, avgCadence: avgCadence)
            
            let paceValues: [ChartInterval]
            let bestPace: Double
            
            if sport.isWalkingOrRunning {
                let paceIntervals = await processor.intervalsForDistanceSamples(samples, lapDistance: Sport.paceDistanceValue)
                
                let paceSamples = paceIntervals.doubleValues(keyPath: \.avgPace)
                paceValues = ChartInterval.paceChartIntervals(samples: paceSamples, movingTime: detail.movingTime)
                bestPace = paceSamples.min() ?? 0
            } else {
                paceValues = []
                bestPace = 0
            }
                        
            let zones: [HRZoneSummary]
            if let fetchedZones = try? await zonesProvider.fetchZones(for: remoteWorkout, values: detail.zoneValues),  heartRate.isPresent {
                zones = fetchedZones
            } else {
                zones = []
            }
            
            DispatchQueue.main.async {
                self.speedValues = speed
                self.paceValues = paceValues
                self.bestPace = bestPace
                self.heartRateValues = heartRate
                self.cyclingCadenceValues = cadence
                self.altitudeValues = altitude
                self.zones = zones
                
                withAnimation {
                    self.isProcessingAnalysis = false
                }
            }
        } catch {
            Log.debug("DETAIL: unable to process intervals: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                withAnimation {
                    self.isProcessingAnalysis = false
                }
            }
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

            let lapIntervals = await processor.intervalsForDistanceSamples(samples, lapDistance: lapDistance.distanceInMeters(for: sport))
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
            AnalyticsManager.shared.capture(.unfavorited)
        } else {
            try metaProvider.favoriteWorkout(for: identifier)
            isFavorite = true
            AnalyticsManager.shared.capture(.favorited)
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
            speed: detail.avgMovingSpeed > 0 ? formattedSpeedString(for: detail.avgMovingSpeed) : nil,
            maxSpeed: detail.maxSpeed > 0 ? formattedSpeedString(for: detail.maxSpeed) : nil,
            pace: detail.avgPace > 0 ? formattedRunningWalkingPaceString(for: detail.avgPace) : nil,
            heartRate: detail.avgHeartRate > 0 ? formattedHeartRateString(for: detail.avgHeartRate) : nil,
            maxHeartRate: detail.maxHeartRate > 0 ? formattedHeartRateString(for: detail.maxHeartRate) : nil,
            elevation: detail.elevationAscended > 0 ? formattedElevationString(for: detail.elevationAscended) : nil,
            calories: detail.energyBurned > 0 ? formattedCaloriesString(for: detail.energyBurned) : nil,
            coordinates: detail.coordinates
        )
    }
    
}
