//
//  StatsView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/16/21.
//

import SwiftUI
import CoreData

struct StatsView: View {
    @EnvironmentObject var purchaseManager: IAPManager
    @StateObject var statsManager: StatsManager
    
    let availableSports: [Sport] = [.cycling, .running]
    
    init(context: NSManagedObjectContext) {
        let manager = StatsManager(context: context)
        _statsManager = StateObject(wrappedValue: manager)
    }
    
    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .leading, spacing: 10.0) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(formattedMonthDayRangeString(start: statsManager.weekStart, end: statsManager.weekEnd))
                            .font(.title2)
                        Spacer()
                        Text(String(format: "%@ %@", statsManager.weekStats.formattedCount, statsManager.sport == .cycling ? "Rides" : "Runs"))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 10.0) {
                        StatsWeekly(text: "Distance", detail: distanceString(for: statsManager.weekStats.distance), detailColor: .distance)
                        Divider()
                        StatsWeekly(text: "Time", detail: timeString(for: statsManager.weekStats.duration), detailColor: .time)
                    }
                    
                    Divider()
                    
                    HStack {
                        StatsWeekly(text: "Elevation Gain", detail: elevationString(for: statsManager.weekStats.elevation), detailColor: .elevation)
                        Divider()
                        StatsWeekly(text: "Calories", detail: caloriesString(for: statsManager.weekStats.energyBurned), detailColor: .calories)
                    }
                }
                
                Section(header: Text(formattedMonthYearString(for: statsManager.monthStart))) {
                    StatsRow(text: sportTitle, detail: statsManager.monthStats.formattedCount)
                    StatsRow(text: "Distance", detail: distanceString(for: statsManager.monthStats.distance), detailColor: .distance)
                    StatsRow(text: "Time", detail: timeString(for: statsManager.monthStats.duration), detailColor: .time)
                    StatsRow(text: "Elevation Gain", detail: elevationString(for: statsManager.monthStats.elevation), detailColor: .elevation)
                    StatsRow(text: "Calories", detail: caloriesString(for: statsManager.monthStats.energyBurned), detailColor: .calories)
                }
                
                Section(header: Text("Year to Date")) {
                    StatsRow(text: sportTitle, detail: statsManager.yearStats.formattedCount)
                    StatsRow(text: "Distance", detail: distanceString(for: statsManager.yearStats.distance), detailColor: .distance)
                    StatsRow(text: "Time", detail: timeString(for: statsManager.yearStats.duration), detailColor: .time)
                    StatsRow(text: "Elevation Gain", detail: elevationString(for: statsManager.yearStats.elevation), detailColor: .elevation)
                }
                
                Section(header: Text("All Time")) {
                    StatsRow(text: sportTitle, detail: statsManager.allStats.formattedCount)
                    StatsRow(text: "Distance", detail: distanceString(for: statsManager.allStats.distance), detailColor: .distance)
                    
                    if statsManager.sport == .cycling {
                        StatsRow(text: "Longest Ride", detail: distanceString(for: statsManager.allStats.longestDistance), detailColor: .distance)
                        StatsRow(text: "Highest Climb", detail: elevationString(for: statsManager.allStats.highestElevation), detailColor: .elevation)
                    } else if statsManager.sport == .running {
                        StatsRow(text: "Longest Run", detail: distanceString(for: statsManager.allStats.longestDistance), detailColor: .distance)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .zIndex(1.0)
            .navigationBarTitle("Statistics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(availableSports) { sport in
                            Button(action: {
                                statsManager.sport = sport
                            }, label: {
                                Text(sport.title)
                            })
                        }
                    } label: {
                        Text(statsManager.sport.title)
                    }
                }
            }
        }
    }
}

// MARK: - Methods

extension StatsView {
    
    var sportTitle: String {
        switch statsManager.sport {
        case .cycling:
            return "Rides"
        default:
            return "Runs"
        }
    }
    
    func distanceString(for distance: Double?) -> String {
        formattedDistanceString(for: distance)
    }
    
    func timeString(for duration: Double?) -> String {
        formattedHoursMinutesDurationString(for: duration)
    }
    
    func elevationString(for elevation: Double?) -> String {
        formattedElevationString(for: elevation)
    }
    
    func caloriesString(for calories: Double?) -> String {
        formattedCaloriesString(for: calories)
    }
    
}

// MARK: - SubViews

struct StatsWeekly: View {
    var text: String
    var detail: String
    var detailColor = Color.primary
    
    var body: some View {
        VStack(spacing: 5.0) {
            Group {
                Text(text)
                    .foregroundColor(.secondary)
                Text(detail)
                    .font(.title)
                    .foregroundColor(detailColor)
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

struct StatsView_Previews: PreviewProvider {
    static var purchaseManager: IAPManager = {
        let manager = IAPManager()
        manager.isActive = true
        return manager
    }()
    
    static var context = StorageProvider.preview.persistentContainer.viewContext
    
    static var previews: some View {
        StatsView(context: context)
            .colorScheme(.dark)
            .environmentObject(purchaseManager)
    }
}
