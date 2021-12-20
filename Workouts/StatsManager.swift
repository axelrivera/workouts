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
    
    @Published var sport: Sport? {
        didSet {
            fetchSummaries()
        }
    }
    
    private let dataProvider: DataProvider
        
    @Published var availableSports = [Sport]()
    @Published var weekStats: StatsSummary
    @Published var monthStats: StatsSummary
    @Published var yearStats: StatsSummary
    @Published var allStats: StatsSummary
    
    @Published var recentWeekly = [StatsSummary]()
    @Published var recentMonthly = [StatsSummary]()
    
    @Published var avgWeeklyTotal: Int = 0
    @Published var avgWeeklyDistance: Double = 0
    @Published var avgWeeklyDuration: Double = 0
    @Published var avgWeeklyElevation: Double = 0
    @Published var avgWeeklyCalories: Double = 0
    
    @Published var avgMonthlyTotal: Int = 0
    @Published var avgMonthlyDistance: Double = 0
    @Published var avgMonthlyDuration: Double = 0
    @Published var avgMonthlyElevation: Double = 0
    @Published var avgMonthlyCalories: Double = 0
    
    init(context: NSManagedObjectContext) {
        let sport: Sport? = nil
        self.sport = sport
        dataProvider = DataProvider(context: context)
        
        weekStats = StatsSummary(sport: sport, timeframe: .week)
        monthStats = StatsSummary(sport: sport, timeframe: .month)
        yearStats = StatsSummary(sport: sport, timeframe: .year)
        allStats = StatsSummary(sport: sport, timeframe: .allTime)
    }
    
    // MARK: - Methods
    
    func refresh() {
        fetchSummaries()
    }
}

// MARK: - Fetching Summaries

extension StatsManager {
    
    private func fetchSummaries() {
        Log.debug("fetching stats summaries for sport: \(String(describing: sport?.rawValue))")
        
        dataProvider.context.perform { [weak self] in
            guard let self = self else { return }
            
            let availableSports = Workout.availableSports(in: self.dataProvider.context)
            
            // Screenshot Values
            
//            let weekly = StatsSummary.weeklySample()
//            let recentWeekly = StatsSummary.weeklySamples()
//            let avgWeeklyDistance: Double = 241402
//            let avgWeeklyDuration: Double = 34200
//            let avgWeeklyElevation: Double = 915
//            let avgWeeklyCalories: Double = 6000
//
//            let monthly = StatsSummary.monthlySample()
//            let recentMonthly = StatsSummary.monthlySamples()
//            let avgMonthlyDistance: Double = 724205
//            let avgMonthlyDuration: Double = 88200
//            let avgMonthlyElevation: Double = 9000.0
//            let avgMonthlyCalories: Double = 24500.0
//
//            let yearly = StatsSummary.yearlySample()
//            let all = StatsSummary.allSample()
            
            // End of Screenshot Values
            
            let weekly = self.fetchSummary(for: .week)
            let recentWeekly = self.fetchRecentSummary(for: .week)

            let avgWeeklyValues = recentWeekly.dropFirst()
            let totalWeekly = Double(avgWeeklyValues.count)
            
            let avgWeeklyTotal = avgWeeklyValues.map({ Double($0.total) }).reduce(0, +) / totalWeekly
            let avgWeeklyDistance = avgWeeklyValues.map({ $0.distance }).reduce(0, +) / totalWeekly
            let avgWeeklyDuration = avgWeeklyValues.map({ $0.duration }).reduce(0, +) / totalWeekly
            let avgWeeklyElevation = avgWeeklyValues.map({ $0.elevation }).reduce(0, +) / totalWeekly
            let avgWeeklyCalories = avgWeeklyValues.map({ $0.calories }).reduce(0, +) / totalWeekly
            
            let monthly = self.fetchSummary(for: .month)
            let recentMonthly = self.fetchRecentSummary(for: .month)
            
            let avgMonthlyValues = recentMonthly.dropFirst()
            let totalMonthly = Double(avgMonthlyValues.count)
            
            let avgMontlyTotal = avgMonthlyValues.map({ Double($0.total) }).reduce(0, +) / totalMonthly
            let avgMonthlyDistance = avgMonthlyValues.map({ $0.distance }).reduce(0, +) / totalMonthly
            let avgMonthlyDuration = avgMonthlyValues.map({ $0.duration }).reduce(0, +) / totalMonthly
            let avgMonthlyElevation = avgMonthlyValues.map({ $0.elevation }).reduce(0, +) / totalMonthly
            let avgMonthlyCalories = avgMonthlyValues.map({ $0.calories }).reduce(0, +) / totalMonthly

            let yearly = self.fetchSummary(for: .year)
            let all = self.fetchSummary(for: .allTime)
            
            DispatchQueue.main.async {
                self.availableSports = availableSports
                self.weekStats = weekly
                self.monthStats = monthly
                self.yearStats = yearly
                self.allStats = all
                
                self.avgWeeklyTotal = Int(avgWeeklyTotal.rounded())
                self.avgWeeklyDistance = avgWeeklyDistance
                self.avgWeeklyDuration = avgWeeklyDuration
                self.avgWeeklyElevation = avgWeeklyElevation
                self.avgWeeklyCalories = avgWeeklyCalories
                
                self.avgMonthlyTotal = Int(avgMontlyTotal.rounded())
                self.avgMonthlyDistance = avgMonthlyDistance
                self.avgMonthlyDuration = avgMonthlyDuration
                self.avgMonthlyElevation = avgMonthlyElevation
                self.avgMonthlyCalories = avgMonthlyCalories
                
                self.recentWeekly = recentWeekly
                self.recentMonthly = recentMonthly
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

// MARK: Previews

class StatsManagerPreview: StatsManager {
    
    static func manager(context: NSManagedObjectContext) -> StatsManager {
        StatsManagerPreview(context: context) as StatsManager
    }
    
    override func refresh() {
        // no-op
    }
    
}
