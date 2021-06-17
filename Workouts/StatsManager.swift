//
//  StatsManager.swift
//  Workouts
//
//  Created by Axel Rivera on 2/18/21.
//

import Foundation
import HealthKit
import CoreData
import Combine

class StatsManager: ObservableObject {
    typealias Timeframe = StatsSummary.Timeframe
    
    var sport: Sport {
        didSet {
            AppSettings.defaultStatsFilter = sport
            fetchSummaries()
        }
    }
    
    private let dataProvider: DataProvider
        
    @Published var weekStats: StatsSummary
    @Published var monthStats: StatsSummary
    @Published var yearStats: StatsSummary
    @Published var allStats: StatsSummary
    
    private var refreshCancellable: Cancellable?
        
    init(context: NSManagedObjectContext) {
        sport = AppSettings.defaultStatsFilter
        dataProvider = DataProvider(context: context)
        
        weekStats = StatsSummary(sport: sport, timeframe: .week)
        monthStats = StatsSummary(sport: sport, timeframe: .month)
        yearStats = StatsSummary(sport: sport, timeframe: .year)
        allStats = StatsSummary(sport: sport, timeframe: .allTime)
        fetchSummaries()
        //addObservers()
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
        Log.debug("fetching stats summaries for sport: \(sport.rawValue)")
        
        for timeframe in Timeframe.allCases {
            fetchSummary(for: timeframe)
        }
    }
    
    func fetchSummary(for timeframe: Timeframe) {
        do {
            let summary = try dataProvider.fetchStatsSummary(sport: sport, timeframe: timeframe)
            updateSummary(summary)
        } catch {
            Log.debug("fetch summary error: \(error.localizedDescription)")
        }
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

// MARK: - Observers

extension StatsManager {
    
//    func addObservers() {
//        refreshCancellable = NotificationCenter.default.publisher(for: .didRefreshWorkouts)
//            .sink { _ in
//                self.fetchSummaries()
//            }
//    }
    
}
