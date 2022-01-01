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
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State var selectedLap: WorkoutLap?
    
    var selectedLaps: [WorkoutLap] {
        detailManager.selectedLaps()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section(header: headerView()) {
                        ForEach(detailManager.selectedLaps(), id: \.self) { lap in
                            rowView(lap: lap)
                            Divider()
                        }
                    }
                }
            }
            .overlay(overlayView())
            .paywallButtonOverlay(sample: false)
            .navigationTitle("Splits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: { presentationMode.wrappedValue.dismiss() })
                }
            }
        }
    }
    
    @ViewBuilder
    func overlayView() -> some View {
        if purchaseManager.isActive && detailManager.isProcessingLaps {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        } else {
            if selectedLaps.isEmpty {
                Text("No Data Available")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Text(selectedLapTitle)
                .font(.title2)
                .foregroundColor(.secondary)
            
            HStack {
                detailView(text: "Distance", detail: selectedDistance, detailColor: .distance)
                detailView(text: detailManager.detail.totalTimeLabel, detail: selectedTime, detailColor: .time)
            }

            HStack {
                if detailManager.sport.isCycling {
                    detailView(text: "Avg Speed", detail: selectedAvgSpeed, detailColor: .speed)
                } else if detailManager.sport.isWalkingOrRunning {
                    detailView(text: "Avg Pace", detail: selectedAvgPace, detailColor: .pace)
                }

                if detailManager.sport.isCycling {
                    detailView(text: "Avg Cadence", detail: selectedAvgCadence, detailColor: .cadence)
                }
            }

            HStack {
                detailView(text: "Avg Heart Rate", detail: selectedAvgHeartRate, detailColor: .calories)
                detailView(text: "Max Heart Rate", detail: selectedMaxHeartRate, detailColor: .calories)
            }
                        
            Picker("Display", selection: $detailManager.selectedLapDistance) {
                ForEach(LapDistance.allCases, id: \.self) { distance in
                    Text(distance.title(for: detailManager.sport))
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.top, CGFloat(10.0))
            .disabled(!purchaseManager.isActive || detailManager.isProcessingLaps)
            .onChange(of: detailManager.selectedLapDistance) { value in
                selectedLap = nil
            }

        }
        .padding()
        .background(.bar)
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
    
    @ViewBuilder
    func rowView(lap: WorkoutLap) -> some View {
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
                        .foregroundColor(.pace)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else if detailManager.sport.isCycling {
                    Text(formattedLapSpeedString(for: lap.avgSpeed))
                        .foregroundColor(.speed)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .font(.fixedBody)
            .padding()
        }
        .buttonStyle(WorkoutPlainButtonStyle())
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
        guard let selected = selectedLap else { return detailManager.detail.title }
        return "Lap \(selected.lapNumber)"
    }
    
    var selectedDistance: String {
        let value = selectedLap?.distance ?? detailManager.detail.distance
        guard value > 0 else { return "--" }
        return formattedLapDistanceString(for: value)
    }
    
    var selectedTime: String {
        let value = selectedLap?.duration ?? detailManager.detail.totalTime
        guard value > 0 else { return "--" }
        return formattedHoursMinutesSecondsDurationString(for: value)
    }
    
    var selectedAvgSpeed: String {
        let value = selectedLap?.avgSpeed ?? detailManager.detail.avgSpeed
        guard value > 0 else { return "--" }
        return formattedLapSpeedString(for: value)
    }
    
    var selectedAvgPace: String {
        let value = selectedLap?.avgPace ?? detailManager.detail.avgPace
        guard value > 0 else { return "--" }
        return formattedRunningWalkingPaceString(for: value)
    }
    
    var selectedAvgCadence: String {
        let value = selectedLap?.avgCadence ?? detailManager.detail.avgCyclingCadence
        guard value > 0 else { return "--" }
        return formattedCyclingCadenceString(for: value)
    }
    
    var selectedAvgHeartRate: String {
        let value = selectedLap?.avgHeartRate ?? detailManager.detail.avgHeartRate
        guard value > 0 else { return "--" }
        return formattedHeartRateString(for: value)
    }
    
    var selectedMaxHeartRate: String {
        let value = selectedLap?.maxHeartRate ?? detailManager.detail.maxHeartRate
        guard value > 0 else { return "--" }
        return formattedHeartRateString(for: value)
    }
    
}

struct LapsView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    static let workout = StorageProvider.sampleWorkout(moc: viewContext)
    
    static let detailManager: DetailManager = {
        let manager = DetailManager(viewModel: workout.detailViewModel, context: viewContext)
        manager.processWorkout()
        manager.isProcessingLaps = true
        return manager
    }()
    
    static let purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    static var previews: some View {
        LapsView()
            .environmentObject(detailManager)
            .environmentObject(purchaseManager)
            .preferredColorScheme(.light)
    }
}


