//
//  StatsView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/16/21.
//

import SwiftUI
import CoreData

struct StatsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    @EnvironmentObject var statsManager: StatsManager
        
    var weeklySectionTitle: String {
        statsManager.weekStats.dateRangeHeader
    }
    
    var weeklySectionDetail: String {
        statsManager.weekStats.countLabel
    }
    
    var monthlySectionTitle: String {
        statsManager.monthStats.dateRangeHeader
    }
    
    var monthlySectionDetail: String {
        statsManager.monthStats.countLabel
    }
    
    var yearToDateSectionDetail: String {
        statsManager.yearStats.countLabel
    }
    
    var allTimeSectionDetail: String {
        statsManager.allStats.countLabel
    }
    
    func workoutsDestination(sport: Sport?, interval: DateInterval?, title: String) -> some View {
        WorkoutsView(sport: .constant(sport), interval: interval, showFilter: false)
            .navigationTitle(title)
    }
    
    var weeklySummaries: [StatsSummary] {
        purchaseManager.isActive ? statsManager.recentWeekly : StatsSummary.weeklySamples()
    }
    
    var monthlySummaries: [StatsSummary] {
        purchaseManager.isActive ? statsManager.recentMonthly : StatsSummary.monthlySamples()
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: StatsHeader(text: weeklySectionTitle, detail: weeklySectionDetail)) {
                    StatsSummaryView(timeframe: .week, manager: statsManager)
                    
                    NavigationLink(destination: StatsRecentView(timeframe: .week, summaries: weeklySummaries)) {
                        Label(StatsSummary.Timeframe.week.recentTitle, systemImage: "calendar")
                    }
                }
                .textCase(nil)
                
                Section(header: StatsHeader(text: monthlySectionTitle, detail: monthlySectionDetail)) {
                    StatsSummaryView(timeframe: .month, manager: statsManager)
                    
                    NavigationLink(destination: StatsRecentView(timeframe: .month, summaries: monthlySummaries)) {
                        Label(StatsSummary.Timeframe.month.recentTitle, systemImage: "calendar")
                    }
                }
                .textCase(nil)
                
                Section(header: StatsHeader(text: "Year to Date", detail: yearToDateSectionDetail)) {
                    StatsRow(text: "Distance", detail: statsManager.yearStats.distanceString, detailColor: .distance)
                    StatsRow(text: "Time", detail: statsManager.yearStats.timeString, detailColor: .time)
                    StatsRow(text: "Elevation Gain", detail: statsManager.yearStats.elevationString, detailColor: .elevation)
                    
                    NavigationLink(destination: workoutsDestination(sport: statsManager.sport, interval: statsManager.yearStats.interval, title: "Year to Date")) {
                        Text("See All")
                    }
                }
                .textCase(nil)
                
                Section(header: StatsHeader(text: "All Time", detail: allTimeSectionDetail)) {
                    StatsRow(text: "Distance", detail: statsManager.allStats.distanceString, detailColor: .distance)
                                        
                    if statsManager.sport == .cycling {
                        StatsRow(text: "Longest Ride", detail: statsManager.allStats.longestDistanceString, detailColor: .distance)
                        StatsRow(text: "Highest Climb", detail: statsManager.allStats.highestElevationString, detailColor: .elevation)
                    } else if statsManager.sport == .running {
                        StatsRow(text: "Longest Run", detail: statsManager.allStats.longestDistanceString, detailColor: .distance)
                    }
                    
                    NavigationLink(destination: workoutsDestination(sport: statsManager.sport, interval: nil, title: "All Time")) {
                        Text("See All")
                    }
                }
                .textCase(nil)
            }
            .onChange(of: workoutManager.isProcessingRemoteData) { isProcessing in
                if isProcessing { return }
                
                Log.debug("refreshing stats and current data")
                statsManager.refresh()
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            statsManager.sport = nil
                        }, label: {
                            Text("All Workouts")
                        })
                        
                        Divider()
                         
                        ForEach(Sport.supportedSports) { sport in
                            Button(action: {
                                statsManager.sport = sport
                            }, label: {
                                Text(sport.title)
                            })
                        }
                    } label: {
                        Text(statsManager.sport?.title ?? "All Workouts")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Methods

struct StatsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        return manager
    }()
    
    static var previews: some View {
        StatsView()
            .colorScheme(.dark)
            .environmentObject(StatsManager(context: viewContext))
            .environmentObject(purchaseManager)
            .environmentObject(workoutManager)
    }
}


// MARK: - SubViews

struct StatsHeader: View {
    var text: String
    var detail: String
    
    var body: some View {
        HStack {
            Text(text)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Text(detail)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding([.top, .bottom])
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

struct StatsSummaryView: View {
    var timeframe: StatsSummary.Timeframe = .week
    @ObservedObject var manager: StatsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            HStack(spacing: 10.0) {
                StatsSummaryItem(
                    text: "Distance",
                    detail: distance,
                    average: avgDistance,
                    detailColor: .distance,
                    timeframe: timeframe
                )
                Divider()
                StatsSummaryItem(
                    text: "Time",
                    detail: time,
                    average: avgTime,
                    detailColor: .time,
                    timeframe: timeframe
                )
            }
            
            Divider()
            
            HStack {
                StatsSummaryItem(
                    text: "Calories",
                    detail: calories,
                    average: avgCalories,
                    detailColor: .calories,
                    timeframe: timeframe
                )
                Divider()
                StatsSummaryItem(
                    text: "Elevation Gain",
                    detail: elevation,
                    average: avgElevation,
                    detailColor: .elevation,
                    timeframe: timeframe
                )
            }
        }
        .padding([.top, .bottom], 5)
    }
    
    var stats: StatsSummary {
        timeframe == .week ? manager.weekStats : manager.monthStats
    }
    
    var distance: String {
        stats.distanceString
    }
    
    var avgDistance: String {
        let distance = timeframe == .week ? manager.avgWeeklyDistance : manager.avgMonthlyDistance
        return formattedDistanceString(for: distance, mode: .compact, zeroPadding: true)
    }
    
    var time: String {
        stats.timeString
    }
    
    var avgTime: String {
        let duration = timeframe == .week ? manager.avgWeeklyDuration : manager.avgMonthlyDuration
        return formattedHoursMinutesPrettyString(for: duration)
    }
    
    var elevation: String {
        stats.elevationString
    }
    
    var avgElevation: String {
        let elevation = timeframe == .week ? manager.avgWeeklyElevation : manager.avgMonthlyElevation
        return formattedElevationString(for: elevation, zeroPadding: true)
    }
    
    var calories: String {
        stats.caloriesString
    }
    
    var avgCalories: String {
        let calories = timeframe == .week ? manager.avgWeeklyCalories : manager.avgMonthlyCalories
        return formattedCaloriesString(for: calories, zeroPadding: true)
    }
}

struct StatsSummaryItem: View {
    var text: String
    var detail: String
    var average: String
    var detailColor = Color.primary
    var timeframe: StatsSummary.Timeframe = .week
    
    var body: some View {
        VStack(spacing: 5.0) {
            Group {
                Text(text)
                    .font(.fixedBody)
                    .foregroundColor(.secondary)
                Text(detail)
                    .font(.title)
                    .foregroundColor(detailColor)
                
                HStack {
                    Text(average)
                        .foregroundColor(detailColor)
                    Text(timeframe == .week ? "/week" : "/month")
                        .foregroundColor(.secondary)
                }
                .font(.fixedSubheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct StatsRow: View {
    var text: String
    var detail: String
    var detailColor = Color.primary
    
    var body: some View {
        HStack {
            Text(text)
                .foregroundColor(.secondary)
            Spacer()
            Text(detail)
                .foregroundColor(detailColor)
        }
    }
    
}
