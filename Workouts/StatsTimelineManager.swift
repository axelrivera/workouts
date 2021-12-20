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
        case yearToDate, allTime
        var id: Int { hashValue }
        
        var cases: [Timeframe] {
            switch self {
            case .yearToDate:
                return Timeframe.yearToDateCases
            case .allTime:
                return Timeframe.allTimeCases
            }
        }
        
        var title: String {
            switch self {
            case .yearToDate:
                return "Year to Date"
            case .allTime:
                return "All Time"
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
    }
    
    private let context: NSManagedObjectContext
    private let dataProvider: DataProvider
    
    let sport: Sport?
    let displayType: DisplayType
    
    @Published var stats = [StatsSummary]()
    @Published var timeframe: Timeframe = .month {
        didSet {
            reload()
        }
    }
    
    init(sport: Sport?, displayType: DisplayType, context: NSManagedObjectContext) {
        self.context = context
        self.dataProvider = DataProvider(context: context)
        self.sport = sport
        self.displayType = displayType
        
        if let timeframe = displayType.cases.first {
            self.timeframe = timeframe
        } else {
            self.timeframe = .month
        }
    }
    
    func reload() {
        context.perform { [weak self] in
            guard let self = self else { return }
            
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

extension StatsTimelineManager {
    
    var currentDateRange: ClosedRange<Date> {
        switch displayType {
        case .allTime:
            return dataProvider.dateRangeForActiveWorkouts()
        case .yearToDate:
            let now = Date()
            return now.startOfYear ... now
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
            guard let dictionary = try? dataProvider.fetchStatsSummary(sport: sport, interval: interval) else { return nil }
            let summary = StatsSummary(sport: sport, timeframe: .year, interval: interval, title: "\(year)", dictionary: dictionary)
            guard summary.total > 0 else { return nil }
            return summary
        }
        
        return stats.reversed()
    }
    
    func fetchMonthlyStats() -> [StatsSummary] {
        let range = currentDateRange
        let intervals = Date.monthIntervals(from: range.lowerBound, to: range.upperBound)
        
        let stats = intervals.compactMap { (interval) -> StatsSummary? in
            guard let dictionary = try? dataProvider.fetchStatsSummary(sport: sport, interval: interval) else { return nil }
            let summary = StatsSummary(
                sport: sport,
                timeframe: .year,
                interval: interval,
                title: DateFormatter.monthYear.string(from: interval.start),
                dictionary: dictionary
            )
            guard summary.total > 0 else { return nil }
            return summary
        }
        
        return stats.reversed()
    }
    
    func fetchWeeklyStats() -> [StatsSummary] {
        let range = currentDateRange
        let intervals = Date.weekIntervals(from: range.lowerBound, to: range.upperBound)
        
        let stats = intervals.compactMap { (interval) -> StatsSummary? in
            guard let dictionary = try? dataProvider.fetchStatsSummary(sport: sport, interval: interval) else { return nil }
            
            let title = String(
                format: "%@ - %@",
                interval.start.formatted(date: .abbreviated, time: .omitted),
                interval.end.formatted(date: .abbreviated, time: .omitted)
            )
            
            let summary = StatsSummary(
                sport: sport,
                timeframe: .year,
                interval: interval,
                title: title,
                dictionary: dictionary
            )
            guard summary.total > 0 else { return nil }
            return summary
        }
        
        return stats.reversed()
    }
    
}
