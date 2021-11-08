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
        case laps
        case sharing
        case tags
        var id: Int { hashValue }
    }
    
    enum ActiveAlert: Hashable, Identifiable {
        case error(message: String)
        var id: Self { self }
    }
    
    enum RowType: Identifiable, CaseIterable {
        case row1, row2, row3, row4
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var purchaseManager: IAPManager
    @StateObject var detailManager: DetailManager
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
        
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
                Button(action: { activeSheet = .map }) {
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
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Tags")
                        .font(.body)
                    
                    if !detailManager.tags.isEmpty {
                        Spacer()
                        Button("Edit", action: { activeSheet = .tags })
                            .buttonStyle(.borderless)
                    }
                }
                
                if detailManager.tags.isEmpty {
                    Button(action: { activeSheet = .tags }) {
                        Label("Add Tags", systemImage: "tag")
                            .padding([.top, .bottom], CGFloat(10.0))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                        
                } else {
                    TagGrid(tags: detailManager.tags)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
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
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: detailManager.isFavorite ? "heart.fill" : "heart")
                }
                
                Button(action: { activeSheet = .sharing }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .map:
                DetailMapView(title: workout.analysisTitle, points: detailManager.detail.coordinates)
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
            case .tags:
                TagSelectorView(tagManager: tagManager()) {
                    detailManager.reloadTags()
                }
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .error(let message):
                return Alert(
                    title: Text("Workout Error"),
                    message: Text(message),
                    dismissButton: Alert.Button.default(Text("Ok"))
                )
            }
        }
    }
    
    func tagManager() -> TagManager {
        TagManager(
            context: viewContext,
            sport: detailManager.sport,
            workoutIdentifier: detailManager.detail.id
        )
    }
    
    func toggleFavorite() {
        do {
            try detailManager.toggleFavorite()
        } catch {
            activeAlert = .error(message: "Unable to update favorite status.")
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
            DetailView(detailManager: DetailManager(viewModel: workout.detailViewModel, context: viewContext))
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(purchaseManager)
        }
        .colorScheme(.dark)
    }
}
