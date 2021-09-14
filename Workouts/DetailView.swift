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
    enum ActiveFullSheet: Identifiable {
        case map
        var id: Int { hashValue }
    }
    
    enum ActiveSheet: Identifiable {
        case analysis
        case laps
        case sharing
        var id: Int { hashValue }
    }
    
    enum RowType: Identifiable, CaseIterable {
        case row1, row2, row3, row4
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var purchaseManager: IAPManager
    @StateObject var detailManager: DetailManager
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeFullSheet: ActiveFullSheet?
        
    var workout: WorkoutDetailViewModel { detailManager.detail }
    var sport: Sport { detailManager.detail.sport }
    
    var body: some View {
        List {
            VStack(alignment: .leading, spacing: 5.0) {
                Text(workout.title)
                    .font(.largeTitle)
                
                HStack(alignment: .lastTextBaseline) {
                    Text(formattedFullDateString(for: workout.start))
                        .font(.fixedSubheadline)
                    Text(formattedTimeRangeString(start: workout.start, end: workout.end))
                        .font(.fixedSubheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding([.top, .bottom], CGFloat(5.0))
            
            if detailManager.includesLocation {
                Button(action: { activeFullSheet = .map }) {
                    WorkoutMap(points: detailManager.detail.coordinates)
                }
                .buttonStyle(WorkoutMapButtonStyle())
            }
                        
            HStack {
                Button(action: { activeSheet = .analysis }) {
                    Label("Analysis", systemImage: "flame")
                        .padding([.top, .bottom], CGFloat(10.0))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: { activeSheet = .laps }) {
                    Label("Splits", systemImage: "arrow.2.squarepath")
                        .padding([.top, .bottom], CGFloat(10.0))
                        .frame(maxWidth: .infinity)
                    
                }
                .buttonStyle(.bordered)
            }
            
            ForEach(RowType.allCases) { rowType in
                viewForRow(rowType)
            }
            
            HStack {
                Text("Source")
                Spacer()
                Text(workout.source)
                    .foregroundColor(.secondary)
            }
            
            if let device = workout.device {
                HStack {
                    Text("Device")
                    Spacer()
                    Text(device)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear { detailManager.processWorkout() }
        .navigationTitle(workout.detailTitle )
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(PlainListStyle())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { activeSheet = .sharing }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .analysis:
                AnalysisView()
                    .environmentObject(detailManager)
                    .environmentObject(purchaseManager)
            case .laps:
                LapsView()
                    .environmentObject(detailManager)
                    .environmentObject(purchaseManager)
            case .sharing:
                ShareView(viewModel: detailManager.shareViewModel)
                    .environmentObject(purchaseManager)
            }
        }
        .fullScreenCover(item: $activeFullSheet) { item in
            switch item {
            case .map:
                DetailMapView(points: detailManager.detail.coordinates)
            }
        }
    }
}

extension DetailView {
    
    @ViewBuilder
    func viewForRow(_ rowType: RowType) -> some View {
        HStack {
            switch rowType {
            case .row1:
                DetailGridView(text: "Distance", detail: distanceString, detailColor: .distance)
                DetailGridView(text: timeLabel, detail: timeString, detailColor: .time)
            case .row2:
                if sport.isCycling {
                    DetailGridView(text: "Avg Speed", detail: avgSpeedString, detailColor: .speed)
                } else if sport.isWalkingOrRunning {
                    DetailGridView(text: "Avg Pace", detail: avgPaceString, detailColor: .cadence)
                }
                
                if sport.isCycling {
                    DetailGridView(text: "Avg Cadence", detail: avgCadenceString, detailColor: .cadence)
                }
            case .row3:
                DetailGridView(text: "Avg Heart Rate", detail: avgHeartRateString, detailColor: .calories)
                DetailGridView(text: "Max Heart Rate", detail: maxHeartRateString, detailColor: .calories)
            case .row4:
                DetailGridView(text: "Calories", detail: caloriesString, detailColor: .calories)
                DetailGridView(text: "Elevation", detail: elevationString, detailColor: .elevation)
            }
        }
    }
    
    var distanceString: String {
        formattedDistanceString(for: workout.distance)
    }
    
    var timeLabel: String {
        workout.totalTimeLabel
    }
    
    var timeString: String {
        formattedHoursMinutesSecondsDurationString(for: workout.totalTime)
    }
    
    var speedUnit: String {
        speedUnitString()
    }
    
    var avgSpeedString: String {
        guard workout.displayAvgSpeed > 0 else { return "-- \(speedUnit)" }
        return formattedSpeedString(for: workout.displayAvgSpeed)
    }
    
    var avgCadenceString: String {
        guard workout.avgCyclingCadence > 0 else { return "--" }
        return formattedCyclingCadenceString(for: workout.avgCyclingCadence)
    }
    
    var paceUnit: String {
        formattedRunningWalkingPaceUnitString()
    }
    
    var avgPaceString: String {
        guard workout.avgPace > 0 else { return "--" }
        return formattedRunningWalkingPaceString(for: workout.avgPace)
    }
    
    var avgHeartRateString: String {
        guard workout.avgHeartRate > 0 else { return "--" }
        return formattedHeartRateString(for: workout.avgHeartRate)
    }
    
    var maxHeartRateString: String {
        guard workout.maxHeartRate > 0 else { return "--" }
        return formattedHeartRateString(for: workout.maxHeartRate)
    }
    
    var caloriesString: String {
        guard workout.energyBurned > 0 else { return "--"}
        return formattedCaloriesString(for: workout.energyBurned)
    }
    
    var elevationString: String {
        formattedElevationString(for: workout.elevationAscended)
    }
    
}

struct DetailGridView: View {
    var text: String
    var detail: String
    var detailColor = Color.primary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Group {
                Text(text)
                Text(detail)
                    .font(.largeTitle)
                    .foregroundColor(detailColor)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    static let workout = StorageProvider.sampleWorkout(moc: viewContext)
    static let purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    static var previews: some View {
        NavigationView {
            DetailView(detailManager: DetailManager(viewModel: workout.detailViewModel))
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(purchaseManager)
        }
        .colorScheme(.dark)
    }
}
