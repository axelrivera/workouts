//
//  StatsRecentView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/1/21.
//

import SwiftUI

extension StatsRecentView {
    
    enum Options: String, Identifiable, CaseIterable {
        case distance, calories, elevation
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .distance: return "Distance"
            case .calories: return "Calories"
            case .elevation: return "Elevation"
            }
        }
        
        var color: Color {
            switch self {
            case .distance: return .distance
            case .calories: return .calories
            case .elevation: return .elevation
            }
        }
    }
    
}

struct StatsRecentView: View {
    @EnvironmentObject var purchaseManager: IAPManager
    
    let options: [Options] = [.distance, .calories, .elevation]
    @State var option = Options.distance
    
    var timeframe: StatsSummary.Timeframe
    var summaries: [StatsSummary]
    
    @State private var values = [Double]()
    
    var body: some View {
        VStack(spacing: 0.0) {
            VStack(spacing: 10.0) {
                Picker(selection: $option, label: Text("Select Option")) {
                    ForEach(options, id: \.self) {
                        Text($0.title)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                RecentChart(
                    values: valuesForSelectedOption(),
                    lineColor: option.color,
                    yAxisFormatter: chartFormatterForSelectedOption()
                )
                .frame(maxWidth: .infinity, maxHeight: 200.0)
            }
            .padding([.top, .leading, .trailing])
            .padding(.bottom, 5.0)
            .background(Color.secondarySystemBackground)
            .zIndex(2.0)
            
            Divider()
                .zIndex(3.0)
            
            
            List(summaries, id: \.self) { summary in
                NavigationLink(destination: destination(for: summary)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5.0) {
                            Text(summary.dateRangeHeader)
                                .font(.title3)
                                .foregroundColor(summary.isCurrentInterval ? .time : .primary)
                            
                            HStack {
                                Text(summary.timeString)
                                    .foregroundColor(.time)
                                
                                Divider()
                                
                                Text(summary.countLabel)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(stringForSelectedOption(in: summary))
                            .font(.title2)
                            .foregroundColor(option.color)
                    }
                }
            }
            .zIndex(0.0)
            .listStyle(PlainListStyle())
        }
        .paywallOverlay()
        .navigationBarTitle(timeframe.recentTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension StatsRecentView {
    
    func destination(for summary: StatsSummary) -> some View {
        StatsWorkoutsView(sport: summary.sport, interval: summary.interval)
            .navigationBarTitle(summary.dateRangeHeader)
    }
    
}

extension StatsRecentView {
    
    func chartFormatterForSelectedOption() -> UnitValueFormatter {
        switch option {
        case .distance:
            return UnitValueFormatter(unit: .distance)
        case .calories:
            return UnitValueFormatter(unit: .calories)
        case .elevation:
            return UnitValueFormatter(unit: .elevation)
        }
    }
    
    func valuesForSelectedOption() -> [ChartInterval] {
        switch option {
        case .distance: return distanceChartIntervals
        case .calories: return caloriesChartIntervals
        case .elevation: return elevationChartIntervals
        }
    }
    
    func stringForSelectedOption(in summary: StatsSummary) -> String {
        switch option {
        case .distance: return summary.distanceString
        case .calories: return summary.caloriesString
        case .elevation: return summary.elevationString
        }
    }
    
    private var distanceChartIntervals: [ChartInterval] {
        summaries.map { (summary) -> ChartInterval in
            ChartInterval(
                xValue: summary.interval.start.timeIntervalSince1970,
                yValue: nativeDistanceToLocalizedUnit(for: summary.distance)
            )
        }.reversed()
    }
    
    private var caloriesChartIntervals: [ChartInterval] {
        summaries.map { (summary) -> ChartInterval in
            ChartInterval(
                xValue: summary.interval.start.timeIntervalSince1970,
                yValue: summary.energyBurned
            )
        }.reversed()
    }
    
    private var elevationChartIntervals: [ChartInterval] {
        summaries.map { (summary) -> ChartInterval in
            ChartInterval(
                xValue: summary.interval.start.timeIntervalSince1970,
                yValue: nativeAltitudeToLocalizedUnit(for: summary.elevation)
            )
        }.reversed()
    }
    
}

struct StatsRecentView_Previews: PreviewProvider {
    static var summaries = StatsSummary.weeklySamples()
    
    static let purchaseManager: IAPManager = {
        let manager = IAPManager()
        manager.isActive = false
        return manager
    }()
    
    static var previews: some View {
        NavigationView {
            StatsRecentView(timeframe: .week, summaries: summaries)
                .environmentObject(purchaseManager)
                .preferredColorScheme(.dark)
        }
    }
}
