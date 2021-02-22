//
//  StatsSummary.swift
//  Workouts
//
//  Created by Axel Rivera on 2/19/21.
//

import Foundation

struct StatsSummary {
    enum Timeframe: Identifiable, CaseIterable {
        case week, month, year, allTime
        var id: Int { hashValue }
        
        var interval: (Date, Date) {
            let date = Date()
            switch self {
            case .week:
                return (date.workoutWeekStart, date.workoutWeekEnd)
            case .month:
                return (date.startOfMonth, date.endOfMonth)
            case .year:
                return (date.startOfYear, date.endOfYear)
            case .allTime:
                return (Date.distantPast, Date.distantFuture)
            }
        }
    }
    
    let sport: Sport
    let timeframe: Timeframe
    var count: Int
    var distance: Double
    var duration: Double
    var elevation: Double
    var energyBurned: Double
    var longestDistance: Double
    var highestElevation: Double
    
    init(sport: Sport, timeframe: Timeframe) {
        self.sport = sport
        self.timeframe = timeframe
        count = 0
        distance = 0
        duration = 0
        elevation = 0
        energyBurned = 0
        longestDistance = 0
        highestElevation = 0
    }
}
