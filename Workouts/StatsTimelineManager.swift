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
    enum DisplayType: Hashable, Identifiable {
        case yearToDate(sport: Sport?), allTime(sport: Sport?), tag(tag: TagSummaryViewModel)
        var id: Int { hashValue }
        
        var cases: [Timeframe] {
            switch self {
            case .yearToDate:
                return Timeframe.yearToDateCases
            case .allTime:
                return Timeframe.allTimeCases
            case .tag:
                return Timeframe.tagCases
            }
        }
        
        var sport: Sport? {
            switch self {
            case .yearToDate(let sport):
                return sport
            case .allTime(let sport):
                return sport
            case .tag(let tag):
                if tag.gearType == .bike {
                    return .cycling
                } else if tag.gearType == .shoes {
                    return .running
                } else {
                    return nil
                }
            }
        }
        
        var tagId: UUID? {
            switch self {
            case .tag(let tag):
                return tag.id
            default:
                return nil
            }
        }
        
        var title: String {
            switch self {
            case .yearToDate:
                return "Year to Date"
            case .allTime:
                return "All Time"
            case .tag(let tag):
                return tag.title
            }
        }
        
        var subtitle: String {
            switch self {
            case .yearToDate(let sport):
                return sport?.activityName ?? "All Workouts"
            case .allTime(let sport):
                return sport?.activityName ?? "All Workouts"
            case .tag(tag: let tag):
                if tag.gearType == .none {
                    return "Tag"
                } else {
                    return tag.gearType.rawValue.capitalized
                }
            }
        }
    }
    
    enum Timeframe: String, Hashable, Identifiable {
        case year, month, week
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .year:
                return "By Year"
            case .month:
                return "By Month"
            case .week:
                return "By Week"
            }
        }
        
        static let yearToDateCases: [Timeframe] = [.month, .week]
        static let allTimeCases: [Timeframe] = [.year, .month]
        static let tagCases: [Timeframe] = [.year, .month, .week]
    }
    
    private let context: NSManagedObjectContext
    private let dataProvider: DataProvider
    private let workoutTagProvider: WorkoutTagProvider
    
    let displayType: DisplayType
    
    var sport: Sport?
    var identifiers = [UUID]()
    @Published var stats = [StatsSummary]()
    @Published var timeframe: Timeframe = .month {
        didSet {
            reload()
        }
    }
    
    init(displayType: DisplayType, context: NSManagedObjectContext) {
        self.context = context
        self.dataProvider = DataProvider(context: context)
        self.workoutTagProvider = WorkoutTagProvider(context: context)
        self.displayType = displayType
        self.sport = displayType.sport
        
        if let tag = displayType.tagId {
            identifiers = workoutTagProvider.workoutIdentifiers(forTag: tag)
        }
        
        if let timeframe = displayType.cases.first {
            self.timeframe = timeframe
        } else {
            self.timeframe = .month
        }
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
                }
                
                DispatchQueue.main.async {
                    self.stats = stats
                }
            }
        }
    }
    
}

extension StatsTimelineManager {
    
    var currentDateRange: ClosedRange<Date> {
        switch displayType {
        case .allTime:
            return dataProvider.dateRangeForActiveWorkouts()
        case .yearToDate:
            let now = Date()
            return now.startOfYear ... now
        case .tag:
            return dataProvider.dateRangeForActiveWorkouts()
        }
    }
    
    func fetchTagggedWorkouts() -> [UUID] {
        switch displayType {
        case .tag(let tag):
            return workoutTagProvider.workoutIdentifiers(forTag: tag.id)
        default:
            return []
        }
    }
    
    func fetchWorkouts(forInterval interval: DateInterval) -> [UUID] {
        if let _ = displayType.tagId {
            if identifiers.isEmpty { return [] }
            let predicate = Workout.activePredicate(sport: nil, interval: interval, identifiers: identifiers)
            return dataProvider.workoutIdentifiers(for: predicate)
        } else {
            let predicate = Workout.activePredicate(sport: sport, interval: interval)
            return dataProvider.workoutIdentifiers(for: predicate)
        }
        
    }
    
    func fetchYearlyStats() -> [StatsSummary] {
        let range = currentDateRange
        let startYear = range.lowerBound.year()
        let endYear = range.upperBound.year()
        
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
        let range = currentDateRange
        let intervals = Date.monthIntervals(from: range.lowerBound, to: range.upperBound)
        
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
        let range = currentDateRange
        let intervals = Date.weekIntervals(from: range.lowerBound, to: range.upperBound)
        
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
