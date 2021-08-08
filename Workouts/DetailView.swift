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
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var purchaseManager: IAPManager
    @StateObject var detailManager: DetailManager
    
    @State var activeSheet: ActiveSheet?
    
    var workout: WorkoutDetail { detailManager.detail }
    var sport: Sport { detailManager.detail.sport }
        
    init(identifier: UUID) {
        let manager = DetailManager(remoteIdentifier: identifier)
        _detailManager = StateObject(wrappedValue: manager)
        activeSheet = nil
    }
    
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
            .padding([.top, .bottom], 5.0)
            
            HStack {
                Button(action: { activeSheet = .map }) {
                    WorkoutMap(points: $detailManager.points)
                }
                .buttonStyle(WorkoutMapButtonStyle())
                .disabled(detailManager.isMapDisabled)
                .overlay(mapOverlay())
                
                Button(action: { activeSheet = .analysis }) {
                    VStack(alignment: .leading) {
                        Image(systemName: "flame.fill")
                        Spacer()
                        Text("Workout Analysis")
                            .bold()
                    }
                }
                .buttonStyle(WorkoutAnalysisButtonStyle())
            }
            
            HStack {
                DetailGridView(text: "Distance", detail: distanceString, detailColor: .distance)
                DetailGridView(text: timeLabel, detail: timeString, detailColor: .time)
            }
            
            HStack {
                if sport.isCycling {
                    DetailGridView(text: "Avg Speed", detail: avgSpeedString, detailColor: .speed)
                } else if sport.isWalkingOrRunning {
                    DetailGridView(text: "Avg Pace", detail: avgPaceString, detailColor: .cadence)
                }
                
                if sport.isCycling {
                    DetailGridView(text: "Avg Cadence", detail: avgCadenceString, detailColor: .cadence)
                }
            }
            
            HStack {
                DetailGridView(text: "Avg Heart Rate", detail: avgHeartRateString, detailColor: .calories)
                DetailGridView(text: "Max Heart Rate", detail: maxHeartRateString, detailColor: .calories)
            }
            
            HStack {
                DetailGridView(text: "Calories", detail: caloriesString, detailColor: .calories)
                DetailGridView(text: "Elevation", detail: elevationString, detailColor: .elevation)
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
        .onAppear { detailManager.loadWorkout(with: viewContext) }
        .navigationTitle(workout.detailTitle )
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(PlainListStyle())
        .fullScreenCover(item: $activeSheet) { (item) in
            switch item {
            case .map:
                DetailMapView(points: detailManager.points)
            case .analysis:
                DetailAnalysisView()
                    .environmentObject(detailManager)
            }
        }
    }
}

extension DetailView {
    
    @ViewBuilder
    func mapOverlay() -> some View {
        if detailManager.isMapDisabled {
            if workout.indoor {
                Text("Indoor Workout")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
            } else {
                Text("No Map Data")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
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
    static let purchaseManager = IAPManager()
    
    static var previews: some View {
        NavigationView {
            DetailView(identifier: workout.remoteIdentifier!)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(purchaseManager)
        }
        .colorScheme(.dark)
    }
}
