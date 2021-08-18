//
//  LapsView.swift
//  Workouts
//
//  Created by Axel Rivera on 8/9/21.
//

import SwiftUI

struct LapsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var detailManager: DetailManager
    
    @State var selectedLap: WorkoutLap?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 10.0) {
                    Text(selectedLapTitle)
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    HStack {
                        detailView(text: "Distance", detail: selectedDistance, detailColor: .distance)
                        detailView(text: detailManager.workout.totalTimeLabel, detail: selectedTime, detailColor: .time)
                    }

                    HStack {
                        if detailManager.sport.isCycling {
                            detailView(text: "Avg Speed", detail: selectedAvgSpeed, detailColor: .speed)
                        } else if detailManager.sport.isWalkingOrRunning {
                            detailView(text: "Avg Pace", detail: selectedAvgPace, detailColor: .cadence)
                        }

                        if detailManager.sport.isCycling {
                            detailView(text: "Avg Cadence", detail: selectedAvgCadence, detailColor: .cadence)
                        }
                    }

                    HStack {
                        detailView(text: "Avg Heart Rate", detail: selectedAvgHeartRate, detailColor: .calories)
                        detailView(text: "Max Heart Rate", detail: selectedMaxHeartRate, detailColor: .calories)
                    }

                }
                .padding()
                .background(Color.secondarySystemBackground)

                Divider()
                
                List {
                    ForEach(detailManager.laps, id: \.self) { lap in
                        Button(action: { selectLap(lap) }) {
                            HStack {
                                Image(systemName: selectedLap == lap ? "checkmark.circle" : "circle")
                                    .foregroundColor(.accentColor)

                                Text("\(lap.lapNumber)")
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(formattedHoursMinutesSecondsDurationString(for: lap.duration))
                                    .foregroundColor(.time)
                                    .frame(maxWidth: .infinity, alignment: .trailing)

                                Text(formattedLapDistanceString(for: lap.distance))
                                    .foregroundColor(.distance)
                                    .frame(maxWidth: .infinity, alignment: .trailing)

                                if detailManager.sport.isWalkingOrRunning {
                                    Text(formattedRunningWalkingPaceString(for: lap.avgPace))
                                        .foregroundColor(.cadence)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                } else if detailManager.sport.isCycling {
                                    Text(formattedLapSpeedString(for: lap.avgSpeed))
                                        .foregroundColor(.speed)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                            .font(.fixedBody)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .paywallOverlay()
            .onAppear { detailManager.reloadLapsIfNeeded() }
            .navigationBarTitle("Laps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done", action: { presentationMode.wrappedValue.dismiss() })
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Picker("Display", selection: $detailManager.selectedLapDistance.animation()) {
                        ForEach(LapDistance.allCases, id: \.self) { distance in
                            Text(distance.title(for: detailManager.sport))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: detailManager.selectedLapDistance) { value in
                        selectedLap = nil
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func detailView(text: String, detail: String, detailColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(text)
                .font(.fixedSubheadline)
            Text(detail)
                .font(.title2)
                .foregroundColor(detailColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

extension LapsView {
    
    func selectLap(_ lap: WorkoutLap) {
        if let current = selectedLap, current == lap {
            self.selectedLap = nil
        } else {
            selectedLap = lap
        }
    }
    
    var selectedLapTitle: String {
        guard let selected = selectedLap else { return "Total" }
        return "Lap \(selected.lapNumber)"
    }
    
    var selectedDistance: String {
        let value = selectedLap?.distance ?? detailManager.workout.distance
        guard value > 0 else { return "--" }
        return formattedLapDistanceString(for: value)
    }
    
    var selectedTime: String {
        let value = selectedLap?.duration ?? detailManager.workout.totalTime
        guard value > 0 else { return "--" }
        return formattedHoursMinutesSecondsDurationString(for: value)
    }
    
    var selectedAvgSpeed: String {
        let value = selectedLap?.avgSpeed ?? detailManager.workout.avgSpeed
        guard value > 0 else { return "--" }
        return formattedLapSpeedString(for: value)
    }
    
    var selectedAvgPace: String {
        let value = selectedLap?.avgPace ?? detailManager.workout.avgPace
        guard value > 0 else { return "--" }
        return formattedRunningWalkingPaceString(for: value)
    }
    
    var selectedAvgCadence: String {
        let value = selectedLap?.avgCadence ?? detailManager.workout.avgCyclingCadence
        guard value > 0 else { return "--" }
        return formattedCyclingCadenceString(for: value)
    }
    
    var selectedAvgHeartRate: String {
        let value = selectedLap?.avgHeartRate ?? detailManager.workout.avgHeartRate
        guard value > 0 else { return "--" }
        return formattedHeartRateString(for: value)
    }
    
    var selectedMaxHeartRate: String {
        let value = selectedLap?.maxHeartRate ?? detailManager.workout.maxHeartRate
        guard value > 0 else { return "--" }
        return formattedHeartRateString(for: value)
    }
    
}

struct LapsView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    static let workout = StorageProvider.sampleWorkout(moc: viewContext)
    static let detailManager: DetailManager = {
        let manager = DetailManager(remoteIdentifier: workout.remoteIdentifier!)
        manager.loadWorkout(with: viewContext)
        return manager
    }()
    
    static var previews: some View {
        LapsView()
            .environmentObject(detailManager)
            .preferredColorScheme(.dark)
    }
}


