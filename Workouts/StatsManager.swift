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
    
    var sport: Sport? {
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
    
    @Published var recentWeekly = [StatsSummary]()
    @Published var recentMonthly = [StatsSummary]()
    
    @Published var avgWeeklyDistance: Double = 0
    @Published var avgWeeklyDuration: Double = 0
    @Published var avgWeeklyElevation: Double = 0
    @Published var avgWeeklyCalories: Double = 0
    
    @Published var avgMonthlyDistance: Double = 0
    @Published var avgMonthlyDuration: Double = 0
    @Published var avgMonthlyElevation: Double = 0
    @Published var avgMonthlyCalories: Double = 0
    
    @Published var isDirty = true
    
    private var refreshCancellable: Cancellable?
        
    init(context: NSManagedObjectContext) {
        sport = AppSettings.defaultStatsFilter
        dataProvider = DataProvider(context: context)
        
        weekStats = StatsSummary(sport: sport, timeframe: .week)
        monthStats = StatsSummary(sport: sport, timeframe: .month)
        yearStats = StatsSummary(sport: sport, timeframe: .year)
        allStats = StatsSummary(sport: sport, timeframe: .allTime)
                
        fetchSummaries()
        addObservers()
    }
}

// MARK: - Fetching Summaries

extension StatsManager {
    
    func refreshIfNeeded() {
        guard isDirty else {
            Log.debug("ignoring stats refresh")
            return
        }
        
        Log.debug("stats dirty -> trigger refresh")
        fetchSummaries()
    }
    
    func fetchSummaries() {
        Log.debug("fetching stats summaries for sport: \(String(describing: sport?.rawValue))")
        
        dataProvider.context.perform { [weak self] in
            guard let self = self else { return }
            
            let weekly = self.fetchSummary(for: .week)
            let monthly = self.fetchSummary(for: .month)
            let yearly = self.fetchSummary(for: .year)
            let all = self.fetchSummary(for: .allTime)
            
            let recentWeekly = self.fetchRecentSummary(for: .week)
            let recentMonthly = self.fetchRecentSummary(for: .month)
            
            let avgWeeklyValues = recentWeekly 
            let totalWeekly = Double(avgWeeklyValues.count)
            let avgWeeklyDistance = avgWeeklyValues.map({ $0.distance }).reduce(0, +) / totalWeekly
            let avgWeeklyDuration = avgWeeklyValues.map({ $0.duration }).reduce(0, +) / totalWeekly
            let avgWeeklyElevation = avgWeeklyValues.map({ $0.elevation }).reduce(0, +) / totalWeekly
            let avgWeeklyCalories = avgWeeklyValues.map({ $0.energyBurned }).reduce(0, +) / totalWeekly
            
            let avgMonthlyValues = recentMonthly.dropFirst()
            let totalMonthly = Double(avgMonthlyValues.count)
            let avgMonthlyDistance = avgMonthlyValues.map({ $0.distance }).reduce(0, +) / totalMonthly
            let avgMonthlyDuration = avgMonthlyValues.map({ $0.duration }).reduce(0, +) / totalMonthly
            let avgMonthlyElevation = avgMonthlyValues.map({ $0.elevation }).reduce(0, +) / totalMonthly
            let avgMonthlyCalories = avgMonthlyValues.map({ $0.energyBurned }).reduce(0, +) / totalMonthly
            
            DispatchQueue.main.async {
                self.weekStats = weekly
                self.monthStats = monthly
                self.yearStats = yearly
                self.allStats = all
                
                self.avgWeeklyDistance = avgWeeklyDistance
                self.avgWeeklyDuration = avgWeeklyDuration
                self.avgWeeklyElevation = avgWeeklyElevation
                self.avgWeeklyCalories = avgWeeklyCalories
                
                self.avgMonthlyDistance = avgMonthlyDistance
                self.avgMonthlyDuration = avgMonthlyDuration
                self.avgMonthlyElevation = avgMonthlyElevation
                self.avgMonthlyCalories = avgMonthlyCalories
                
                self.recentWeekly = recentWeekly
                self.recentMonthly = recentMonthly
                
                self.isDirty = false
            }
        }
    }
    
    private func fetchSummary(for timeframe: Timeframe) -> StatsSummary {
        let interval = StatsSummary.currentInterval(for: timeframe)
        
        do {
            let dictionary = try dataProvider.fetchStatsSummary(sport: sport, interval: interval)
            return StatsSummary(sport: sport, timeframe: timeframe, dictionary: dictionary)
        } catch {
            Log.debug("fetch summary error: \(error.localizedDescription)")
            return StatsSummary(sport: sport, timeframe: timeframe, interval: interval)
        }
    }
    
    private func fetchRecentSummary(for timeframe: Timeframe) -> [StatsSummary] {
        var intervals = [DateInterval]()
        
        switch timeframe {
        case .week:
            intervals = StatsSummary.lastTwelveWeeks
        case .month:
            intervals = StatsSummary.lastTwelveMonths
        default:
            break
        }
        
        if intervals.isEmpty { return [] }
        
        do {
            var summaries = [StatsSummary]()
            for interval in intervals {
                let dictionary = try dataProvider.fetchStatsSummary(sport: sport, interval: interval)
                let summary = StatsSummary(sport: sport, timeframe: timeframe, interval: interval, dictionary: dictionary)
                summaries.append(summary)
            }
            return summaries
        } catch {
            Log.debug("fetch recent error: \(error.localizedDescription)")
            return []
        }
    }
    
}

// MARK: - Observers

extension StatsManager {
    
    func addObservers() {
        refreshCancellable = NotificationCenter.default.publisher(for: .didRefreshWorkouts)
            .sink { _ in
                self.isDirty = true
            }
    }
    
}
