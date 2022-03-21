//
//  StatsRecentView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/1/21.
//

import SwiftUI

struct StatsRecentView: View {
    let timeframe: StatsSummary.Timeframe
    let sport: Sport?
    let summaries: [StatsSummary]
    let avgValue: Double
    
    @State private var values = [Double]()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section(header: headerView()) {
                    ForEach(summaries, id: \.self) { summary in
                        NavigationLink(destination: StatsWorkoutsView(identifiers: summary.workouts, title: summary.title)) {
                            VStack(spacing: 10.0) {
                                HStack {
                                    Text(summary.title)
                                        .font(.fixedHeadline)
                                        .foregroundColor(summary.isCurrentInterval ? .time : .primary)
                                    
                                    Spacer()
                                    
                                    Text(summary.total.formatted())
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text(summary.distanceString)
                                        .workoutCellLabelStyle(color: .distance)
                                    
                                    Text(summary.durationString)
                                        .workoutCellLabelStyle(color: .time)
                                    
                                    Text(summary.caloriesString)
                                        .workoutCellLabelStyle(color: .calories)
                                    
                                    Text(summary.elevationString)
                                        .workoutCellLabelStyle(color: .elevation)
                                }
                            }
                            .padding([.top, .bottom], CGFloat(10))
                            .padding([.leading, .trailing])
                        }
                        .buttonStyle(WorkoutPlainButtonStyle())
                        Divider()
                    }
                }
            }
        }
        .overlay(emptyOverlay())
        .paywallButtonOverlay()
        .navigationTitle(timeframe.recentTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(timeframe.recentTitle)
                        .font(.system(size: 13.0, weight: .semibold, design: .default))
                    Text(sport?.activityName ?? "All Workouts")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    func headerView() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(rangeString)
                    .font(.fixedBody)
                    .bold()
                
                Spacer()
                
                Text(distanceString)
                    .foregroundColor(.distance)
            }
            .padding([.leading, .trailing])
            .frame(maxWidth: .infinity)
            
            RecentChart(
                values: distanceChartIntervals,
                avgValue: avgValue,
                lineColor: .distance,
                yAxisFormatter: UnitValueFormatter(unit: .distance)
            )
            .padding([.leading, .trailing])
            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
        }
        .padding(.top)
        .background(Material.bar)
    }
    
    @ViewBuilder
    func emptyOverlay() -> some View {
        if summaries.isEmpty {
            Text("No Workouts")
                .foregroundColor(.secondary)
        }
    }
}

extension StatsRecentView {
    
    private var rangeString: String {
        guard let start = summaries.last?.interval.start, let end = summaries.first?.interval.end else { return "No Workouts" }
        return formattedRangeString(start: start, end: end)
    }
    
    private var distanceString: String {
        let total: Double = summaries.reduce(0) { $0 + $1.distance }
        return formattedDistanceString(for: total, mode: .compact, zeroPadding: true)
    }
    
    private var distanceChartIntervals: [ChartInterval] {
        summaries.map { (summary) -> ChartInterval in
            ChartInterval(
                xValue: summary.interval.start.timeIntervalSince1970,
                yValue: nativeDistanceToLocalizedUnit(for: summary.distance)
            )
        }.reversed()
    }
    
}

struct StatsRecentView_Previews: PreviewProvider {
    static var summaries = StatsSummary.weeklySamples()
    
    static var previews: some View {
        NavigationView {
            StatsRecentView(
                timeframe: .week,
                sport: .cycling,
                summaries: summaries,
                avgValue: 100
            )
            .environmentObject(IAPManagerPreview.manager(isActive: true))
            .preferredColorScheme(.dark)
        }
    }
}
