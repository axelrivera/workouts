//
//  LogManager.swift
//  Workouts
//
//  Created by Axel Rivera on 7/26/21.
//

import SwiftUI
import CoreData
import Combine

enum LogDisplayType: String, Identifiable, CaseIterable {
    case distance, time, load
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .load:
            return .load
        case .distance:
            return .distance
        case .time:
            return .time
        }
    }
}

extension LogManager {
    
    enum DateFilter: String, Identifiable, CaseIterable {
        case recentMonths, recentYears, byYear
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .recentMonths:
                return "Last 12 Months"
            case .recentYears:
                return "Last 5 Years"
            case .byYear:
                return "By Year"
            }
        }
    }
    
}

class LogManager: ObservableObject {
    typealias DisplayType = LogDisplayType
    
    @Published var availableSports = [Sport]()
        
    // Filter Related
    @Published var sports = [Sport]() {
        didSet {
            fetchIntervals()
        }
    }
    
    @Published var displayType = DisplayType.distance
    
    @Published var dateFilter = DateFilter.recentMonths {
        didSet {
            fetchIntervals()
        }
    }
    
    @Published var displayYear: String = "" {
        didSet {
            fetchIntervals()
        }
    }
    
    @Published var filterYears = [String]()
    
    // Data
    @Published var intervals = [LogInterval]()
    
    private var refreshCancellable: Cancellable?
    
    fileprivate(set) var context: NSManagedObjectContext
        
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func reloadIntervals() {
        updateFilters()
        fetchIntervals()
    }
    
}

// MARK: - Fetching

extension LogManager {
    
    // most recent three weeks are free
    
    var paywallCutoffDate: Date? {
        intervals.prefix(4).last?.end
    }
    
    func isFreeContent(interval: LogInterval) -> Bool {
        guard let cutoff = paywallCutoffDate, let date = interval.end else { return false }
        return cutoff <= date
    }
    
    private func fetchIntervals() {
        let filterInterval: DateInterval
        
        switch dateFilter {
        case .recentMonths:
            filterInterval = DateInterval.lastTwelveMonths()
        case .recentYears:
            filterInterval = DateInterval.lastFiveYears()
        case .byYear:
            if let year = Int(displayYear), let interval = DateInterval.intervalForYear(year) {
                let now = Date()
                let end = now.year() == year ? now : interval.end
                filterInterval = DateInterval(start: interval.start, end: end)
            } else {
                let date = Date()
                filterInterval = DateInterval(start: date.startOfYear, end: date.endOfYear)
            }
        }
        
        let startDate = filterInterval.start.workoutWeekStart
        let endDate = filterInterval.end.workoutWeekEnd
        let dates = Date.dates(from: startDate, to: endDate)
        
        var dictionary = [String: LogDay]()
        let days: [LogDay] = dates.map { date -> LogDay in
            let day = LogDay(date: date, activities: [])
            dictionary[date.logKey] = day
            return day
        }
        
        context.performAndWait {
            let request = Self.fetchRequest(for: sports, interval: filterInterval, ascending: false)
            let workouts = (try? context.fetch(request)) ?? [Workout]()
            
            for workout in workouts {
                let key = workout.start.logKey
                if let day = dictionary[key] {
                    day.activities.append(workout.logActivity())
                }
            }
        }
        
        let chunk = days.chunked(into: 7)
        let intervals: [LogInterval] = chunk.map({ LogInterval(days: $0)}).reversed()
        
        DispatchQueue.main.async {
            withAnimation(.none) {
                self.intervals = intervals
            }            
        }
    }
    
}

// MARK: - Methods

extension LogManager {
    
    // MARK: Fetch Request
    
    private static func fetchRequest(for sports: [Sport], interval: DateInterval? = nil, ascending: Bool = false) -> NSFetchRequest<Workout> {
        let sort = [Workout.sortedByDateDescriptor(ascending: ascending)]
        let request = Workout.defaultFetchRequest()
        request.predicate = Workout.activePredicate(sports: sports, interval: interval)
        request.sortDescriptors = sort
        return request
    }
    
    private var firstWorkoutDate: Date? {
        context.performAndWait {
            let request = Self.fetchRequest(for: [], interval: nil, ascending: true)
            request.fetchLimit = 1
            let workouts = (try? context.fetch(request)) ?? [Workout]()
            return workouts.first?.start
        }
    }
    
    // MARK: Filters
    
    private func updateFilters() {
        guard let date = firstWorkoutDate else {
            return
        }
        
        let availableSports = Workout.availableSports(in: context)
        let startYear = date.year()
        let endYear = Date().year()
        
        let filters: [String] = Array(startYear ... endYear).map { "\($0)" }.reversed()
        
        let displayYear: String
        if self.displayYear.isPresent && filters.contains(self.displayYear) {
            displayYear = self.displayYear
        } else {
            displayYear = filters.first ?? ""
        }
                
        DispatchQueue.main.async {
            self.availableSports = availableSports
            self.filterYears = filters
            self.displayYear = displayYear
        }
    }
    
    // MARK: Helpers
    
    var filterTitleString: String {
        var string: String
        
        switch dateFilter {
        case .recentMonths, .recentYears:
            string = dateFilter.title
        case .byYear:
            let yearString = displayYear.isEmpty ? "\(Date().year())" : displayYear
            string = String(format: "Year %@", yearString)
        }
        return string
    }
    
    var filterSportString: String {
        if sports.isEmpty { return "All Workouts" }
        return sports.map({ $0.altName }).sorted().joined(separator: ", ")
    }
    
}

// MARK: - Additions

private extension Date {
    
    var logKey: String {
        DateFormatter.localizedString(from: self, dateStyle: .short, timeStyle: .none)
    }
    
}

// MARK: - Preview Class

class LogManagerPreview: LogManager {
    
    static func manager(context: NSManagedObjectContext) -> LogManager {
        LogManagerPreview(context: context) as LogManager
    }
    
    override func reloadIntervals() {
        // no-op
    }
    
}


