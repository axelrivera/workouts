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
    
    enum ActiveSheet: Identifiable {
        case settings
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    @EnvironmentObject var statsManager: StatsManager
    
    @State var activeSheet: ActiveSheet?
        
    var weeklySectionTitle: String {
        statsManager.weekStats.dateRangeHeader
    }
    
    var weeklySectionDetail: String {
        statsManager.weekStats.countLabel
    }
    
    var weeklySectionAvg: String {
        String(format: "%@ /week", statsManager.avgWeeklyTotal.formatted())
    }
    
    var monthlySectionTitle: String {
        statsManager.monthStats.dateRangeHeader
    }
    
    var monthlySectionDetail: String {
        statsManager.monthStats.countLabel
    }
    
    var monthlySectionAvg: String {
        String(format: "%@ /month", statsManager.avgMonthlyTotal.formatted())
    }
    
    var yearToDateSectionDetail: String {
        statsManager.yearStats.countLabel
    }
    
    var allTimeSectionDetail: String {
        statsManager.allStats.countLabel
    }
    
    var weeklySummaries: [StatsSummary] {
        purchaseManager.isActive ? statsManager.recentWeekly : StatsSummary.weeklySamples()
    }
    
    var monthlySummaries: [StatsSummary] {
        purchaseManager.isActive ? statsManager.recentMonthly : StatsSummary.monthlySamples()
    }
    
    var summaryViewModel: TagSummaryViewModel {
        TagSummaryViewModel.sample(name: "Tag 1")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 15.0) {
                    VStack(spacing: SECTION_SPACING) {
                        VStack(alignment: .leading, spacing: 5.0) {
                            statsHeader(
                                text: weeklySectionTitle,
                                destination: StatsRecentView(timeframe: .week, sport: statsManager.sport, summaries: weeklySummaries)
                            )
                            
                            HStack(spacing: 10.0) {
                                Text(weeklySectionDetail)
                                    .foregroundColor(.primary)
                                Divider()
                                Text(weeklySectionAvg)
                                    .foregroundColor(.secondary)
                            }
                        }
                        StatsSummaryView(timeframe: .week, manager: statsManager)
                            .padding([.top, .bottom], CGFloat(10.0))
                            .padding([.leading, .trailing])
                            .background(Color.secondarySystemBackground)
                            .cornerRadius(12.0)
                    }
                    .padding([.leading, .trailing])
                                        
                    VStack(spacing: SECTION_SPACING) {
                        VStack(alignment: .leading, spacing: 5.0) {
                            statsHeader(
                                text: monthlySectionTitle,
                                destination: StatsRecentView(timeframe: .month, sport: statsManager.sport, summaries: monthlySummaries)
                            )
                            
                            HStack(spacing: 10.0) {
                                Text(monthlySectionDetail)
                                    .foregroundColor(.primary)
                                Divider()
                                Text(monthlySectionAvg)
                                    .foregroundColor(.secondary)
                            }
                        }
                        StatsSummaryView(timeframe: .month, manager: statsManager)
                            .padding([.top, .bottom], CGFloat(10.0))
                            .padding([.leading, .trailing])
                            .background(Color.secondarySystemBackground)
                            .cornerRadius(12.0)
                            
                    }
                    .padding([.leading, .trailing])
                    
                    Divider()
                                        
                    VStack(spacing: SECTION_SPACING) {
                        statsHeader(
                            text: "Year to Date",
                            destination: StatsTimelineView(sport: statsManager.sport, displayType: .yearToDate)
                        )
                            .padding(.bottom, CGFloat(10.0))
                        SummaryCell(viewModel: statsManager.yearStats)
                    }
                    .padding([.leading, .trailing])
                    
                    Divider()
                                        
                    VStack(spacing: SECTION_SPACING) {
                        statsHeader(
                            text: "All Time",
                            destination: StatsTimelineView(sport: statsManager.sport, displayType: .allTime)
                        )
                            .padding(.bottom, CGFloat(10.0))
                        SummaryCell(viewModel: statsManager.allStats)
                    }
                    .padding([.leading, .trailing])
                }
                .padding([.top, .bottom])
            }
            .onChange(of: workoutManager.isProcessingRemoteData) { isProcessing in
                if isProcessing { return }
                
                Log.debug("refreshing stats and current data")
                statsManager.refresh()
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeSheet = .settings }) {
                       Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
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
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(item: $activeSheet) { item in
            switch item {
            case .settings:
                SettingsView()
                    .environmentObject(purchaseManager)
            }
        }
    }
    
    @ViewBuilder
    func statsHeader<Destination: View>(text: String, destination: Destination) -> some View {
        HStack {
            Text(text)
                .font(.title2)
                .foregroundColor(.primary)
            Spacer()
            NavigationLink(destination: destination) {
                Text("Show More")
            }
        }
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
