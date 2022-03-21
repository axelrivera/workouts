//
//  StatsView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/16/21.
//

import SwiftUI
import CoreData

struct StatsView: View {
    let SECTION_SPACING = 10.0
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    @EnvironmentObject var statsManager: StatsManager
        
    var body: some View {
        LazyVStack(spacing: 0.0) {
            recentSummary(stats: statsManager.weekStats)
                .padding(.bottom)
            recentSummary(stats: statsManager.monthStats)
                .padding(.bottom)
            
            Divider()
            
            NavigationLink(destination: timelineDestination(forTimeframe: .yearToDate)) {
                SummaryCell(viewModel: statsManager.yearStats, active: true)
                    .padding([.leading, .trailing])
                    .padding([.top, .bottom], CGFloat(10.0))
            }
            .buttonStyle(WorkoutPlainButtonStyle())
            
            Divider()
                                
            NavigationLink(destination: timelineDestination(forTimeframe: .allTime)) {
                SummaryCell(viewModel: statsManager.allStats, active: true)
                    .padding([.leading, .trailing])
                    .padding([.top, .bottom], CGFloat(10.0))
            }
            .buttonStyle(WorkoutPlainButtonStyle())
        }
        .padding([.top, .bottom])
        .onChange(of: workoutManager.isProcessingRemoteData) { isProcessing in
            if isProcessing { return }
            statsManager.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        statsManager.sport = nil
                    }, label: {
                        HStack {
                            Text("All Workouts")
                            if statsManager.sport == nil {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                    
                    Divider()
                     
                    ForEach(statsManager.availableSports) { sport in
                        Button(action: {
                            statsManager.sport = sport
                        }, label: {
                            Text(sport.activityName)
                            if statsManager.sport == sport {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        })
                    }
                } label: {
                    Text(statsManager.sport?.activityName ?? "All Workouts")
                }
            }
        }
    }
    
}

// MARK: - Methods

extension StatsView {
    
    func avgLabel(forTimeframe timeframe: StatsSummary.Timeframe) -> String {
        switch timeframe {
        case .week:
            return String(format: "%@ /week", statsManager.avgWeeklyTotal.formatted())
        case .month:
            return String(format: "%@ /month", statsManager.avgMonthlyTotal.formatted())
        default:
            return ""
        }
    }
    
    func avgDistance(forTimeframe timeframe: StatsSummary.Timeframe) -> Double {
        switch timeframe {
        case .week:
            return nativeDistanceToLocalizedUnit(for: statsManager.avgWeeklyDistance)
        case .month:
            return nativeDistanceToLocalizedUnit(for: statsManager.avgMonthlyDistance)
        default:
            return 0
        }
    }
    
    func summaries(forTimeframe timeframe: StatsSummary.Timeframe) -> [StatsSummary] {
        switch timeframe {
        case .week:
            return purchaseManager.isActive ? statsManager.recentWeekly : StatsSummary.weeklySamples()
        case .month:
            return purchaseManager.isActive ? statsManager.recentMonthly : StatsSummary.monthlySamples()
        default:
            return []
        }
    }
    
    func recentSummary(stats: StatsSummary) -> some View {
        VStack(spacing: SECTION_SPACING) {
            VStack(alignment: .leading, spacing: 5.0) {
                Text(stats.title)
                    .font(.title2)
                    .foregroundColor(.primary)
                
                HStack(spacing: 10.0) {
                    Text(stats.countLabel)
                        .font(.fixedBody)
                        .foregroundColor(.primary)
                    Divider()
                    Text(avgLabel(forTimeframe: stats.timeframe))
                        .font(.fixedBody)
                        .foregroundColor(.secondary)
                    Spacer()
                    NavigationLink(destination: recentDestination(for: stats)) {
                        Text("Show More")
                    }
                }
            }
            StatsSummaryView(timeframe: stats.timeframe, manager: statsManager)
                .padding([.top, .bottom], CGFloat(10.0))
                .padding([.leading, .trailing])
                .background(Color.secondarySystemBackground)
                .cornerRadius(12.0)
        }
        .padding([.leading, .trailing])
    }
    
    func recentDestination(for stats: StatsSummary) -> some View {
        StatsRecentView(
            timeframe: stats.timeframe,
            sport: statsManager.sport,
            summaries: summaries(forTimeframe: stats.timeframe),
            avgValue: avgDistance(forTimeframe: stats.timeframe)
        )
    }
        
    @ViewBuilder
    func timelineDestination(forTimeframe timeframe: StatsSummary.Timeframe) -> some View {
        switch timeframe {
        case .yearToDate:
            StatsTimelineView(
                title: "Year to Date",
                subtitle: statsManager.sport?.activityName ?? "All Workouts",
                sport: statsManager.sport,
                interval: statsManager.yearToDateInterval,
                timeframe: .month,
                identifiers: []
            )
        case .allTime:
            StatsTimelineView(
                title: "All Time",
                subtitle: statsManager.sport?.activityName ?? "All Workouts",
                sport: statsManager.sport,
                interval: statsManager.allTimeDateInterval,
                timeframe: .year,
                identifiers: []
            )
        default:
            EmptyView()
        }
    }
    
}


// MARK: - Previews

struct StatsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        return manager
    }()
    
    static var previews: some View {
        NavigationView {
            ScrollView {
                StatsView()
            }
            .navigationTitle("Progress")
        }
        .colorScheme(.dark)
        .environmentObject(StatsManager(context: viewContext))
        .environmentObject(purchaseManager)
        .environmentObject(workoutManager)
    }
}


// MARK: - SubViews

struct StatsSummaryView: View {
    var timeframe: StatsSummary.Timeframe = .week
    @ObservedObject var manager: StatsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15.0) {
            HStack(spacing: 20.0) {
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
                        
            HStack(spacing: 20.0) {
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
        .padding([.top, .bottom], 5.0)
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
        stats.durationString
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
