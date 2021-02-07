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
        var id: Int { hashValue }
    }
    
    @ObservedObject var workout: Workout
    @StateObject var detailManager = DetailManager()
    
    @State var activeSheet: ActiveSheet?
    
    var body: some View {
        Form {
            Section {
                Button(action: { activeSheet = .map }) {
                    WorkoutMap(points: $detailManager.points)
                        .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 200.0, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .disabled(true)
                }
            }
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            Section {
                TextRow(item: RowItem(text: "Date", detail: formattedRelativeDateString(for: workout.startDate)))
                TextRow(item: RowItem(text: "Start", detail: formattedTimeString(for: workout.startDate)))
                TextRow(item: RowItem(text: "Total Time", detail: formattedTimeDurationString(for: workout.elapsedTime)))
            }
            Section(header: Text("Distance")) {
                TextRow(item: RowItem(text: "Distance", detail: formattedDistanceString(for: workout.distance)))
            }
            
            if showSpeedSection(workout: workout) {
                Section(header: Text("Speed")) {
                    if let average = workout.avgSpeed {
                        TextRow(item: RowItem(text: "Avg. Speed", detail: formattedSpeedString(for: average)))
                    }
                    
                    if let maximum = workout.maxSpeed {
                        TextRow(item: RowItem(text: "Max. Speed", detail: formattedSpeedString(for: maximum)))
                    }
                }
            }
            
            if detailManager.showHeartRateSection {
                Section(header: Text("Heart Rate")) {
                    if let average = detailManager.avgHeartRate {
                        TextRow(item: RowItem(text: "Avg. Heart Rate", detail: formattedHeartRateString(for: average)))
                    }
                    
                    if let maximum = detailManager.maxHeartRate {
                        TextRow(item: RowItem(text: "Max Heart Rate", detail: formattedHeartRateString(for: maximum)))
                    }
                }
            }
            
            Section(header: Text("Energy")) {
                TextRow(item: RowItem(text: "Calories", detail: formattedCaloriesString(for: workout.energyBurned)))
            }
            
            if showCadenceSection(workout: workout) {
                Section(header: Text("Cadence")) {
                    if let average = workout.avgCyclingCadence {
                        TextRow(item: RowItem(text: "Avg. Cadence", detail: formattedCyclingCadenceString(for: average)))
                    }
                    
                    if let maximum = workout.maxCyclingCadence {
                        TextRow(item: RowItem(text: "Max Cadence", detail: formattedCyclingCadenceString(for: maximum)))
                    }
                }
            }
            
            Section {
                TextRow(item: RowItem(text: "Source", detail: workout.source))
                
                if let device = workout.device {
                    TextRow(item: RowItem(text: "Device", detail: device))
                }
            }
        }
        .onAppear(perform: { detailManager.workout = workout.id })
        .navigationTitle(formattedActivityTypeString(for: workout.activityType, indoor: workout.indoor))
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(InsetGroupedListStyle())
        .sheet(item: $activeSheet) { (item) in
            switch item {
            case .map:
                DetailMapView(workout: workout, detailManager: detailManager)
            }
        }
    }
}

extension DetailView {
    
    func showSpeedSection(workout: Workout) -> Bool {
        workout.avgSpeed != nil || workout.maxSpeed != nil
    }
    
    func showCadenceSection(workout: Workout) -> Bool {
        workout.avgCyclingCadence != nil || workout.maxCyclingCadence != nil
    }
    
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(workout: Workout.sample)
    }
}
