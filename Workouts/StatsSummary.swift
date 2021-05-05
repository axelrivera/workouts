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
//                let start = Date.dateFor(month: 2, day: 15, year: 2021)
//                let end = Date.dateFor(month: 2, day: 21, year: 2021)
//                return (start!, end!)
                return (date.workoutWeekStart, date.workoutWeekEnd)
            case .month:
//                return (Date.dateFor(month: 2, day: 1, year: 2021)!, Date.dateFor(month: 2, day: 28, year: 2021)!)
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
    
    static let countFormatter: NumberFormatter = {
       let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var formattedCount: String {
        Self.countFormatter.string(from: count as NSNumber) ?? ""
    }
    
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
