//
//  StatsTimelineManager.swift
//  Workouts
//
//  Created by Axel Rivera on 12/18/21.
//

import Foundation
import CoreData
import SwiftUI

final class StatsTimelineManager: ObservableObject {
    private let context: NSManagedObjectContext
    private let dataProvider: DataProvider
    private let workoutTagProvider: WorkoutTagProvider
    
    let interval: DateInterval
    var sport: Sport?
    var identifiers = [UUID]()
    @Published var stats = [StatsSummary]()
    @Published var timeframe: StatsSummary.Timeframe {
        didSet {
            reload()
        }
    }
    
    init(sport: Sport?, interval: DateInterval, timeframe: StatsSummary.Timeframe, identifiers: [UUID] = [UUID](), context: NSManagedObjectContext) {
        self.context = context
        self.dataProvider = DataProvider(context: context)
        self.workoutTagProvider = WorkoutTagProvider(context: context)
        self.interval = interval
        self.timeframe = timeframe
        self.sport = sport
        self.identifiers = identifiers
    }
    
    func reload() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            
            self.context.perform {
                var stats: [StatsSummary]
                switch self.timeframe {
                case .week:
                    stats = self.fetchWeeklyStats()
                case .month:
                    stats = self.fetchMonthlyStats()
                case .year:
                    stats = self.fetchYearlyStats()
                default:
                    stats = []
                }
                
                DispatchQueue.main.async {
                    self.stats = stats
                }
            }
        }
    }
    
    var menuOptions: [StatsSummary.Timeframe] {
        if timeframe == .year {
            return []
        } else {
            return [.month, .week]
        }
    }
    
}

extension StatsTimelineManager {
    
    func fetchWorkouts(forInterval interval: DateInterval) -> [UUID] {
        if identifiers.isPresent {
            let predicate = Workout.activePredicate(sport: nil, interval: interval, identifiers: identifiers)
            return dataProvider.workoutIdentifiers(for: predicate)
        } else {
            let predicate = Workout.activePredicate(sport: sport, interval: interval)
            return dataProvider.workoutIdentifiers(for: predicate)
        }
        
    }
    
    func fetchYearlyStats() -> [StatsSummary] {
        let startYear = interval.start.year()
        let endYear = interval.end.year()
        
        let years = Array(startYear ... endYear)
        let stats = years.compactMap { (year) -> StatsSummary? in
            guard let start = Date.dateFor(month: 1, day: 1, year: year) else { return nil }
            let end = start.endOfYear
            let interval = DateInterval(start: start, end: end)
            let workouts = fetchWorkouts(forInterval: interval)
            if workouts.isEmpty { return nil }
            
            guard let dictionary = try? dataProvider.fetchStatsSummary(for: workouts) else { return nil }
            let summary = StatsSummary(
                sport: sport,
                timeframe: .year,
                interval: interval,
                dictionary: dictionary,
                workouts: workouts
            )
            return summary
        }
        
        return stats.reversed()
    }
    
    func fetchMonthlyStats() -> [StatsSummary] {
        let intervals = Date.monthIntervals(from: interval.start, to: interval.end)
        
        let stats = intervals.compactMap { (interval) -> StatsSummary? in
            let workouts = fetchWorkouts(forInterval: interval)
            if workouts.isEmpty { return nil }
            
            guard let dictionary = try? dataProvider.fetchStatsSummary(for: workouts) else { return nil }
            let summary = StatsSummary(
                sport: sport,
                timeframe: .month,
                interval: interval,
                dictionary: dictionary,
                workouts: workouts
            )
            return summary
        }
        
        return stats.reversed()
    }
    
    func fetchWeeklyStats() -> [StatsSummary] {
        let intervals = Date.weekIntervals(from: interval.start, to: interval.end)
        
        let stats = intervals.compactMap { (interval) -> StatsSummary? in
            let workouts = fetchWorkouts(forInterval: interval)
            guard let dictionary = try? dataProvider.fetchStatsSummary(for: workouts) else { return nil }
            
            let summary = StatsSummary(
                sport: sport,
                timeframe: .week,
                interval: interval,
                dictionary: dictionary,
                workouts: workouts
            )
            return summary
        }
        
        return stats.reversed()
    }
    
}
