//
//  StatsManager.swift
//  Workouts
//
//  Created by Axel Rivera on 2/18/21.
//

import Foundation
import HealthKit
import Combine

class StatsManager: ObservableObject {
    typealias Timeframe = StatsSummary.Timeframe
    
    var sport: Sport {
        didSet {
            AppSettings.defaultStatsFilter = sport
            fetchSummaries()
        }
    }
        
    @Published var weekStats: StatsSummary
    @Published var monthStats: StatsSummary
    @Published var yearStats: StatsSummary
    @Published var allStats: StatsSummary
    
    var summariesPublishers = [Timeframe: Cancellable]()
    
    init() {
        sport = AppSettings.defaultStatsFilter
        weekStats = StatsSummary(sport: sport, timeframe: .week)
        monthStats = StatsSummary(sport: sport, timeframe: .month)
        yearStats = StatsSummary(sport: sport, timeframe: .year)
        allStats = StatsSummary(sport: sport, timeframe: .allTime)
        fetchSummaries()
    }
}

// MARK: - Dates

extension StatsManager {
    
    var weekStart: Date {
        let (start, _) = weekStats.timeframe.interval
        return start
    }
    
    var weekEnd: Date {
        let (_, end) = weekStats.timeframe.interval
        return end
    }
    
    var monthStart: Date {
        let (start, _) = monthStats.timeframe.interval
        return start
    }
    
}

// MARK: - Distance

extension StatsManager {
    
    func fetchSummaries() {
        for timeframe in Timeframe.allCases {
            fetchSummary(for: timeframe)
        }
    }
    
    func fetchSummary(for timeframe: Timeframe) {
        if let publisher = summariesPublishers[timeframe] {
            publisher.cancel()
            summariesPublishers.removeValue(forKey: timeframe)
        }
        
        summariesPublishers[timeframe] = StatsProvider.fetchStatsSummary(sport: sport, timeframe: timeframe)
            .sink(receiveCompletion: { (completion) in
                Log.debug("summary for timeframe completed: \(timeframe)")
            }, receiveValue: { (summary) in
                self.updateSummary(summary)
            })
    }
    
    func updateSummary(_ summary: StatsSummary) {
        DispatchQueue.main.async {
            switch summary.timeframe {
            case .week:
                self.weekStats = summary
            case .month:
                self.monthStats = summary
            case .year:
                self.yearStats = summary
            case .allTime:
                self.allStats = summary
            }
        }
    }
    
}
