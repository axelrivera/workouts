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
        yearStats = StatsSummary(sport: sport, timeframe: .yearToDate)
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
            
            let weekly = self.fetchSummary(for: .week)
            let weeklySummaries = self.fetchRecentSummary(for: .week)
            let recentWeekly = Array(weeklySummaries.dropLast())

            let avgWeeklyValues = weeklySummaries.dropFirst()
            let totalWeekly = Double(avgWeeklyValues.count)
            
            var avgWeeklyTotal: Double?
            var avgWeeklyDistance: Double?
            var avgWeeklyDuration: Double?
            var avgWeeklyElevation: Double?
            var avgWeeklyCalories: Double?
            
            if totalWeekly > 0 {
                avgWeeklyTotal = avgWeeklyValues.map({ Double($0.total) }).reduce(0, +) / totalWeekly
                avgWeeklyDistance = avgWeeklyValues.map({ $0.distance }).reduce(0, +) / totalWeekly
                avgWeeklyDuration = avgWeeklyValues.map({ $0.duration }).reduce(0, +) / totalWeekly
                avgWeeklyElevation = avgWeeklyValues.map({ $0.elevation }).reduce(0, +) / totalWeekly
                avgWeeklyCalories = avgWeeklyValues.map({ $0.calories }).reduce(0, +) / totalWeekly
            }
            
            let monthly = self.fetchSummary(for: .month)
            let monthlySummaries = self.fetchRecentSummary(for: .month)
            let recentMonthly = Array(monthlySummaries.dropLast())
            
            let avgMonthlyValues = monthlySummaries.dropFirst()
            let totalMonthly = Double(avgMonthlyValues.count)
            
            var avgMontlyTotal: Double?
            var avgMonthlyDistance: Double?
            var avgMonthlyDuration: Double?
            var avgMonthlyElevation: Double?
            var avgMonthlyCalories: Double?
            
            if totalMonthly > 0 {
                avgMontlyTotal = avgMonthlyValues.map({ Double($0.total) }).reduce(0, +) / totalMonthly
                avgMonthlyDistance = avgMonthlyValues.map({ $0.distance }).reduce(0, +) / totalMonthly
                avgMonthlyDuration = avgMonthlyValues.map({ $0.duration }).reduce(0, +) / totalMonthly
                avgMonthlyElevation = avgMonthlyValues.map({ $0.elevation }).reduce(0, +) / totalMonthly
                avgMonthlyCalories = avgMonthlyValues.map({ $0.calories }).reduce(0, +) / totalMonthly
            }
            
            let yearly = self.fetchSummary(for: .yearToDate)
            let all = self.fetchSummary(for: .allTime)
            
            DispatchQueue.main.async {
                self.availableSports = availableSports
                self.weekStats = weekly
                self.monthStats = monthly
                self.yearStats = yearly
                self.allStats = all
                
                self.avgWeeklyTotal = Int(avgWeeklyTotal?.rounded() ?? 0)
                self.avgWeeklyDistance = avgWeeklyDistance ?? 0
                self.avgWeeklyDuration = avgWeeklyDuration ?? 0
                self.avgWeeklyElevation = avgWeeklyElevation ?? 0
                self.avgWeeklyCalories = avgWeeklyCalories ?? 0
                
                self.avgMonthlyTotal = Int(avgMontlyTotal?.rounded() ?? 0)
                self.avgMonthlyDistance = avgMonthlyDistance ?? 0
                self.avgMonthlyDuration = avgMonthlyDuration ?? 0
                self.avgMonthlyElevation = avgMonthlyElevation ?? 0
                self.avgMonthlyCalories = avgMonthlyCalories ?? 0
                
                self.recentWeekly = recentWeekly
                self.recentMonthly = recentMonthly
            }
        }
    }
    
    private func fetchSummary(for timeframe: StatsSummary.Timeframe) -> StatsSummary {
        let interval = StatsSummary.currentInterval(for: timeframe)
        
        do {
            let predicate = Workout.activePredicate(sport: sport, interval: interval)
            let workouts = dataProvider.workoutIdentifiers(for: predicate)
            
            let dictionary = try dataProvider.fetchStatsSummary(for: workouts)
            return StatsSummary(sport: sport, timeframe: timeframe, dictionary: dictionary, workouts: workouts)
        } catch {
            Log.debug("fetch summary error: \(error.localizedDescription)")
            return StatsSummary(sport: sport, timeframe: timeframe, interval: interval)
        }
    }
    
    private func fetchRecentSummary(for timeframe: StatsSummary.Timeframe) -> [StatsSummary] {
        var intervals = [DateInterval]()
        
        switch timeframe {
        case .week:
            intervals = StatsSummary.lastThirteenWeeks
        case .month:
            intervals = StatsSummary.lastThirteenMonths
        default:
            break
        }
                
        if intervals.isEmpty { return [] }
        
        var summaries = [StatsSummary]()
        for interval in intervals {
            let predicate = Workout.activePredicate(sport: sport, interval: interval)
            let workouts = dataProvider.workoutIdentifiers(for: predicate)
            
            var summary: StatsSummary
            if let dictionary = try? dataProvider.fetchStatsSummary(for: workouts) {
                summary = StatsSummary(sport: sport, timeframe: timeframe, interval: interval, dictionary: dictionary, workouts: workouts)
            } else {
                summary = StatsSummary(sport: sport, timeframe: timeframe, interval: interval)
            }
            summaries.append(summary)
        }
        return summaries
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
