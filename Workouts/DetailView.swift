//
//  DetailView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI
import MapKit

struct DetailView: View {
    enum ActiveSheet: Identifiable {
        case map
        case analysis
        var id: Int { hashValue }
    }
    
    @ObservedObject var workout: Workout
    @StateObject var detailManager: DetailManager
    
    @State var activeSheet: ActiveSheet?
    @State var showMapOverlay = false
    
    init(workout: Workout) {
        self.workout = workout
        _detailManager = StateObject(wrappedValue: DetailManager(workoutID: workout.id))
    }
    
    var body: some View {
        List {
            VStack(alignment: .leading, spacing: 0.0) {
                Text(workout.title)
                    .font(.title)
                    .padding(.bottom, 5.0)
                
                HStack(alignment: .lastTextBaseline) {
                    Text(formattedFullDateString(for: workout.startDate))
                        .font(.headline)
                        .padding(.bottom, 2.0)
                    Text(formattedTimeRangeString(start: workout.startDate, end: workout.endDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding([.top, .bottom], 5.0)
            
            if detailManager.showDetailMap {
                Button(action: { activeSheet = .map }) {
                    WorkoutMap(points: $detailManager.points)
                        .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 200.0, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .overlay(showMapOverlay ? Color.black.opacity(0.3) : Color.clear)
                        .cornerRadius(12.0)
                }
                .buttonStyle(PlainButtonStyle())
                
                if let locationName = detailManager.locationName {
                    HStack {
                        Image(systemName: "mappin")
                            .imageScale(.small)
                        Text("Location")
                        Spacer()
                        Text(locationName)
                    }
                }
            }
            
            Group {
                RoundButton(text: "Workout Analysis") {
                    activeSheet = .analysis
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            ForEach(gridRows(for: workout, heartRate: detailManager.avgHeartRate)) { row in
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
                Text(workout.sourceAndDeviceString)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Ride")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(PlainListStyle())
        .fullScreenCover(item: $activeSheet) { (item) in
            switch item {
            case .map:
                DetailMapView(workout: workout, detailManager: detailManager)
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
    
    func gridRows(for workout: Workout, heartRate: Double?) -> [GridRow] {
        var items = [GridItem]()
        var item: GridItem
        
        if let distance = workout.distance {
            item = GridItem(text: "Distance", detail: formattedDistanceString(for: distance), detailColor: .distance)
            items.append(item)
        }
        
        item = GridItem(text: "Time", detail: formattedHoursMinutesDurationString(for: workout.elapsedTime), detailColor: .time)
        items.append(item)
        
        if workout.isPacePresent {
            item = GridItem(text: "Avg Pace", detail: formattedRunningWalkingPaceString(for: workout.avgPace), detailColor: .time)
            items.append(item)
        }
        
        if let heartRate = heartRate {
            item = GridItem(text: "Avg Heart Rate", detail: formattedHeartRateString(for: heartRate), detailColor: .calories)
            items.append(item)
        }
        
        if let calories = workout.energyBurned {
            item = GridItem(text: "Calories", detail: formattedCaloriesString(for: calories), detailColor: .calories)
            items.append(item)
        }
        
        if let speed = workout.avgSpeed {
            item = GridItem(text: "Avg Speed", detail: formattedSpeedString(for: speed), detailColor: .speed)
            items.append(item)
        }
        
        if let cadence = workout.avgCyclingCadence {
            item = GridItem(text: "Avg Cadence", detail: formattedCyclingCadenceString(for: cadence), detailColor: .cadence)
            items.append(item)
        }
        
        if let elevation = workout.elevationAscended {
            item = GridItem(text: "Elevation Gain", detail: formattedElevationString(for: elevation), detailColor: .elevation)
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
    static var previews: some View {
        NavigationView {
            DetailView(workout: Workout.sample)
        }
        .colorScheme(.dark)
    }
}
