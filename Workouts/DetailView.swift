//
//  DetailView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI
import MapKit
import CoreData

struct DetailView: View {
    enum ActiveSheet: Identifiable {
        case map
        case analysis
        var id: Int { hashValue }
    }
    
    var viewContext: NSManagedObjectContext
    @ObservedObject var workout: Workout
    @StateObject var detailManager: DetailManager
    
    @State var activeSheet: ActiveSheet?
    @State var showMapOverlay = false
    
    init(workout: Workout, context: NSManagedObjectContext) {
        self.workout = workout
        self.viewContext = context
        
        let manager = DetailManager(workout: workout, context: context)
        _detailManager = StateObject(wrappedValue: manager)
    }
    
    var body: some View {
        List {
            VStack(alignment: .leading, spacing: 0.0) {
                Text(workout.title)
                    .font(.title)
                    .padding(.bottom, 5.0)
                
                HStack(alignment: .lastTextBaseline) {
                    Text(formattedFullDateString(for: workout.start))
                        .font(.headline)
                        .padding(.bottom, 2.0)
                    Text(formattedTimeRangeString(start: workout.start, end: workout.end))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding([.top, .bottom], 5.0)
            
            if workout.showMap {
                Button(action: { activeSheet = .map }) {
                    WorkoutMap(points: $detailManager.points)
                        .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: .infinity, minHeight: 200.0, alignment: .center)
                        .overlay(showMapOverlay ? Color.black.opacity(0.3) : Color.clear)
                        .cornerRadius(Constants.cornerRadius)
                }
                .buttonStyle(PlainButtonStyle())
                
//                if let locationName = detailManager.locationName {
//                    HStack {
//                        Image(systemName: "mappin")
//                            .imageScale(.small)
//                        Text("Location")
//                        Spacer()
//                        Text(locationName)
//                    }
//                }
            }
            
            Group {
                RoundButton(text: "Workout Analysis") {
                    activeSheet = .analysis
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            ForEach(gridRows(for: workout, heartRate: workout.avgHeartRate)) { row in
                HStack(spacing: 5.0) {
                    if let left = row.left {
                        DetailGridView(text: left.text, detail: left.detail, detailColor: left.detailColor)
                    }
                    
                    if let right = row.right {
                        DetailGridView(text: right.text, detail: right.detail, detailColor: right.detailColor)
                    }
                }
            }
            
            HStack {
                Text("Source")
                Spacer()
                Text(workout.source)
                    .foregroundColor(.secondary)
            }
            
            if let device = workout.deviceString {
                HStack {
                    Text("Device")
                    Spacer()
                    Text(device)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear(perform: {
            detailManager.run()
        })
        .navigationTitle(workout.detailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(PlainListStyle())
        .fullScreenCover(item: $activeSheet) { (item) in
            switch item {
            case .map:
                DetailMapView(points: detailManager.points)
            case .analysis:
                DetailAnalysisView(workout: workout, detailManager: detailManager)
            }
        }
    }
}

extension DetailView {
    struct GridItem: Identifiable {
        let id = UUID()
        var text: String
        var detail: String
        var detailColor = Color.primary
    }
    
    struct GridRow: Identifiable {
        let id = UUID()
        var left: GridItem?
        var right: GridItem?
        
        var isEmpty: Bool {
            left == nil && right == nil
        }
        
        var isPresent: Bool {
            !isEmpty
        }
    }
    
    var totalTime: Workout.Time {
        workout.totalTime
    }
    
    func gridRows(for workout: Workout, heartRate: Double?) -> [GridRow] {
        var items = [GridItem]()
        var item: GridItem
        
        if workout.distance > 0 {
            item = GridItem(text: "Distance", detail: formattedDistanceString(for: workout.distance), detailColor: .distance)
            items.append(item)
        }
        
        switch workout.totalTime {
        case .moving(let duration):
            item = GridItem(text: workout.totalTime.title, detail: formattedHoursMinutesDurationString(for: duration), detailColor: .time)
            items.append(item)
        case .total(let duration):
            item = GridItem(text: workout.totalTime.title, detail: formattedHoursMinutesDurationString(for: duration), detailColor: .time)
            items.append(item)
        }
        
        if workout.avgHeartRate > 0 {
            item = GridItem(text: "Avg Heart Rate", detail: formattedHeartRateString(for: workout.avgHeartRate), detailColor: .calories)
            items.append(item)
        }
        
        if workout.energyBurned > 0 {
            item = GridItem(text: "Calories", detail: formattedCaloriesString(for: workout.energyBurned), detailColor: .calories)
            items.append(item)
        }
        
        if workout.sport.isSpeedSport && workout.avgSpeed > 0 {
            item = GridItem(text: "Avg Speed", detail: formattedSpeedString(for: workout.avgSpeed), detailColor: .speed)
            items.append(item)
        }
        
        if workout.sport.isWalkingOrRunning  && detailManager.avgPace > 0 {
            item = GridItem(text: "Avg Pace", detail: formattedRunningWalkingPaceString(for: detailManager.avgPace), detailColor: .cadence)
            items.append(item)
        }
        
        if workout.sport.isCycling && workout.avgCyclingCadence > 0 {
            item = GridItem(text: "Avg Cadence", detail: formattedCyclingCadenceString(for: workout.avgCyclingCadence), detailColor: .cadence)
            items.append(item)
        }
        
        if workout.showMap && workout.elevationAscended > 0 {
            item = GridItem(text: "Elevation Gain", detail: formattedElevationString(for: workout.elevationAscended), detailColor: .elevation)
            items.append(item)
        }
        
        var rows = [GridRow]()
        
        let chunkedItems = items.chunked(into: 2)
        for row in chunkedItems {
            if row.count == 2 {
                rows.append(GridRow(left: row[0], right: row[1]))
            } else if row.count == 1 {
                rows.append(GridRow(left: row[0], right: nil))
            }
        }
        
        return rows
    }
    
}

struct DetailGridView: View {
    var text: String
    var detail: String
    var detailColor = Color.primary
    
    var body: some View {
        VStack(spacing: 0.0) {
            Group {
                Text(text)
                Text(detail)
                    .font(.title)
                    .foregroundColor(detailColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static var previews: some View {
        NavigationView {
            DetailView(workout: Workout(context: viewContext), context: viewContext)
        }
        .colorScheme(.dark)
    }
}
