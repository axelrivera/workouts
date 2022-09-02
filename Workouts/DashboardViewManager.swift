//
//  DashboardViewManager.swift
//  Workouts
//
//  Created by Axel Rivera on 3/5/22.
//

import SwiftUI
import Combine

extension DashboardViewManager {
    enum IntervalType: String, Hashable, Identifiable, CaseIterable {
        case today, yesterday, week, prevWeek, month, prevMonth, year, prevYear, all, range
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .today: return DashboardStrings.today
            case .yesterday: return DashboardStrings.yesterday
            case .week: return DashboardStrings.currentWeek
            case .prevWeek: return DashboardStrings.lastWeek
            case .month: return DashboardStrings.currentMonth
            case .prevMonth: return DashboardStrings.lastMonth
            case .year: return DashboardStrings.currentYear
            case .prevYear: return DashboardStrings.lastYear
            case .all: return DashboardStrings.allTime
            case .range: return DashboardStrings.dates
            }
        }
    }
}

final class DashboardViewManager: ObservableObject {
    let TIMER_INTERVAL: TimeInterval = 60
    
    @Published var isLoading = false
    @Published var currentInterval = IntervalType.month
    private var lastInterval: IntervalType?
    
    @Published var dateRange: ClosedRange<Date> = Date.distantPast...Date()
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    
    @Published var metrics = [DashboardMetricViewModel]()
    @Published var activities = [DashboardActivityViewModel]()
    @Published var showEmptyMetrics = false
    
    @Published var image: UIImage?
    
    private lazy var provider = HealthProvider.shared
    private var originDate: Date?
    private let appleWatchDate = Date.dateFor(month: 1, day: 1, year: 2015)!
    
    private var cancellable: Cancellable?
    private var intervalCancellable: Cancellable?
    
    init() {
        originDate = AppSettings.dashboardStartDate
        currentInterval = IntervalType(rawValue: AppSettings.dashboardInterval) ?? .month
        
        let dateInterval = DateInterval.lastThreeMonths()
        startDate = dateInterval.start
        endDate = dateInterval.end
        
        cancellable = Timer.publish(every: TIMER_INTERVAL, on: .current, in: .common)
            .autoconnect()
            .sink(receiveValue: refreshTimer(_:))
    }
}

extension DashboardViewManager {
    
    var title: String {
        if currentInterval == .range {
            let dateInterval = currentDateInterval()
            if dateInterval.isSameDay {
                return LabelStrings.day
            } else if dateInterval.isFullWeek {
                return LabelStrings.week
            } else if dateInterval.isFullMonth {
                return LabelStrings.month
            } else if dateInterval.isFullYear {
                return LabelStrings.year
            } else {
                return currentInterval.title
            }
        } else {
            return currentInterval.title
        }
    }
    
    var rangeString: String {
        let dateInterval = currentDateInterval()
        switch currentInterval {
        case .today, .yesterday:
            return DateFormatter.longDayShortMonthFormatter.string(from: dateInterval.start)
        case .week, .prevWeek:
            return formattedRangeString(start: dateInterval.start, end: dateInterval.end)
        case .month, .prevMonth:
            return formattedMonthYearString(for: dateInterval.start)
        case .year, .prevYear:
            return DateFormatter.year.string(from: dateInterval.start)
        case .all:
            let start = originDate ?? appleWatchDate
            return String(format: "%@ %@", LabelStrings.since, DateFormatter.medium.string(from: start))
        case .range:
            if dateInterval.isSameDay {
                return DateFormatter.longDayShortMonthFormatter.string(from: dateInterval.start)
            } else if dateInterval.isFullWeek {
                return formattedRangeString(start: dateInterval.start, end: dateInterval.end)
            } else if dateInterval.isFullMonth {
                return DateFormatter.monthYear.string(from: dateInterval.start)
            } else if dateInterval.isFullYear {
                let year = DateFormatter.year.string(from: dateInterval.start)
                return String(format: "%@ %@", LabelStrings.year, year)
            } else {
                return formattedRangeString(start: dateInterval.start, end: dateInterval.end)
            }
        }
    }
    
    var subheaderString: String {
        let dateInterval = currentDateInterval()
        switch currentInterval {
        case .today, .yesterday:
            return DashboardStrings.dailyStats
        case .week, .prevWeek:
            return DashboardStrings.weeklyStats
        case .month, .prevMonth:
            return DashboardStrings.monthlyStats
        case .year, .prevYear:
            return DashboardStrings.yearlyStats
        case .all:
            return DashboardStrings.allTimeStats
        case .range:
            if dateInterval.isSameDay {
                return DashboardStrings.dailyStats
            } else if dateInterval.isFullWeek {
                return DashboardStrings.weeklyStats
            } else if dateInterval.isFullMonth {
                return DashboardStrings.monthlyStats
            } else if dateInterval.isFullYear {
                return DashboardStrings.yearlyStats
            } else {
                return DashboardStrings.fitnessStats
            }
        }
    }
    
    func currentDateInterval() -> DateInterval {
        let start: Date
        let end: Date
        
        switch currentInterval {
        case .today:
            start = Date().startOfDay
            end = Date().endOfDay
        case .yesterday:
            let yesterday = Date().dayBefore
            start = yesterday.startOfDay
            end = yesterday.endOfDay
        case .week:
            start = Date().workoutWeekStart
            end = Date().workoutWeekEnd
        case .prevWeek:
            let interval = DateInterval.prevWeek()
            start = interval.start
            end = interval.end
        case .month:
            start = Date().startOfMonth
            end = Date().endOfMonth
        case .prevMonth:
            let interval = DateInterval.prevMonth()
            start = interval.start
            end = interval.end
        case .year:
            start = Date().startOfYear
            end = Date().endOfYear
        case .prevYear:
            let interval = DateInterval.prevYear()
            start = interval.start
            end = interval.end
        case .all:
            start = originDate ?? appleWatchDate
            end = Date().endOfDay
            
        case .range:
            if endDate < startDate {
                endDate = startDate
            }
            
            start = startDate.startOfDay
            end = endDate.endOfDay
        }
        
        return DateInterval(start: start, end: end)
    }
    
    func refreshTimer(_ output: Timer.TimerPublisher.Output) {
//        Log.debug("reloading timer")
        reload(showLoading: false)
    }
    
    func load(showLoading: Bool = true) async throws {
        if showLoading {
            if lastInterval == nil || currentInterval == .range || lastInterval != currentInterval {
//                Log.debug("previous: \(String(describing: lastInterval)), current: \(currentInterval)")
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.showEmptyMetrics = false
                        self.isLoading = true
                    }
                }
            }
        }
        
        if originDate == nil {
            let originDate = try? await provider.fetchStartDate()
            self.originDate = originDate
            AppSettings.dashboardStartDate = originDate
        }

        let interval = currentDateInterval()

        var metrics = [DashboardMetricViewModel]()
        
        await withTaskGroup(of: DashboardMetricViewModel.self) { group in
            for metric in DashboardMetric.sumMetrics {
                guard let (quantityType, unit) = metric.quantityAndUnit() else { continue }
                
                group.addTask(priority: .userInitiated) {
//                    Log.debug("fetch metric for \(metric.title)")
                    
                    if let value = try? await self.provider.fetchSum(for: quantityType, unit: unit, interval: interval) {
                        return DashboardMetricViewModel(metric: metric, value: value)
                    } else {
                        return DashboardMetricViewModel(metric: metric, value: 0)
                    }
                }
            }
            
            for await viewModel in group {
                if viewModel.isVisible || viewModel.value > 0 {
                    metrics.append(viewModel)
                }
            }
        }

        let data = try await provider.fetchWorkoutData(for: interval)

        let workoutCount = DashboardMetricViewModel(
            metric: .workouts,
            value: Double(data.total)
        )

        let workoutDuration = DashboardMetricViewModel(
            metric: .workoutTime,
            value: data.duration
        )

        let otherMetrics = [workoutCount, workoutDuration].filter({ $0.value > 0 })
        metrics.append(contentsOf: otherMetrics)

        let activityTypes = data.activities
        var activities = [DashboardActivityViewModel]()
        
        await withTaskGroup(of: DashboardActivityViewModel.self) { group in
            for type in activityTypes {
                group.addTask(priority: .userInitiated) {
                    do {
//                        Log.debug("fetching activity for \(type.name)")
                        
                        let activity = try await self.provider.fetchActivityType(for: type, interval: interval)
                        return DashboardActivityViewModel(
                            activity: type,
                            total: activity.total,
                            distance: activity.distance,
                            duration: activity.duration
                        )
                    } catch {
                        return DashboardActivityViewModel(activity: type, total: 0, distance: 0, duration: 0)
                    }
                }
            }
            
            for await viewModel in group {
                if viewModel.duration > 0 {
                    activities.append(viewModel)
                }
            }
        }

        let sortedMetrics = metrics.sorted { lhs, rhs in
            lhs.metric.rawValue < rhs.metric.rawValue
        }

        let cardMetrics = sortedMetrics.filter { $0.metric.isVisibleInCard }
        
        let sortedActivities = activities.sorted { lhs, rhs in
            lhs.duration > rhs.duration
        }

        let rangeStart = originDate ?? Date.distantPast
        
        let workout = DashboardWorkoutViewModel(
            title: rangeString,
            subtitle: subheaderString,
            total: workoutCount,
            duration: workoutDuration,
            activities: Array(sortedActivities.prefix(3))
        )
        
        AppSettings.dashboardInterval = currentInterval.rawValue
        lastInterval = currentInterval

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let view = DashboardCard(metrics: cardMetrics, workout: workout)
            self.image = view.takeScreenshot(origin: .zero, size: workout.size)
            
            withAnimation() {
                self.isLoading = false
                self.metrics = sortedMetrics
                self.activities = sortedActivities
                self.dateRange = rangeStart...Date()
                self.showEmptyMetrics = sortedMetrics.isEmpty
            }
        }

    }
    
    func reload(showLoading: Bool = true) {
        if isLoading { return }
        
        Task(priority: .userInitiated) {
            do {
                try await load(showLoading: showLoading)
            } catch {
                Log.debug("reload failed: \(error.localizedDescription)")
            }
        }
    }
    
}
