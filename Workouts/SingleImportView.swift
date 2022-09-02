//
//  SingleImportView.swift
//  Workouts
//
//  Created by Axel Rivera on 8/10/22.
//

import SwiftUI
import MapKit

struct SingleImportView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var manager: ImportManager
    
    @StateObject var workout: WorkoutImport
    
    @State private var isDuplicateAlertVisible = false
    
    init(workout: WorkoutImport) {
        _workout = StateObject(wrappedValue: workout)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 10) {
                    if workout.status.isValid {
                        statusView()
                        importView()
                    }
                }
            }
            bottomBar()
        }
        .disabled(manager.isProcessing)
        .overlay(content: hudView)
        .navigationTitle(NSLocalizedString("Import Preview", comment: "Screen title"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var statusTitle: String {
        workout.status.title
    }
    
    var statusColor: Color {
        workout.status.color
    }
    
    var statusIcon: String {
        workout.status.imageName
    }
    
    @ViewBuilder
    func hudView() -> some View {
        if manager.isProcessing {
            HUDView()
        }
    }
    
    @ViewBuilder
    func statusView() -> some View {
        Label(statusTitle, systemImage: statusIcon)
            .foregroundColor(statusColor)
            .padding([.top, .leading, .trailing])
    }
    
    @ViewBuilder
    func importView() -> some View {
        VStack(alignment: .center, spacing: 20) {
            if workout.showMap {
                WorkoutMap(points: workout.coordinates)
                    .frame(height: 200)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(formattedImportRelativeDateString(for: workout.startDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(workout.formattedTitle)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        rowItem(text: LabelStrings.distance, detail: distanceString, color: .distance)
                        
                        if let elevation = elevationString {
                            rowItem(text: LabelStrings.elevationGain, detail: elevation, color: .elevation)
                        }
                    }
                    
                    if pausedTime > 0 {
                        Divider()
                        
                        HStack {
                            rowItem(text: LabelStrings.movingTime, detail: movingTimeString, color: .time)
                        }
                        
                        Divider()
                        
                        HStack {
                            rowItem(text: LabelStrings.pausedTime, detail: pausedTimeString, color: .time)
                            rowItem(text: LabelStrings.totalTime, detail: totalTimeString, color: .time)
                        }
                    } else {
                        Divider()
                        
                        HStack {
                            rowItem(text: LabelStrings.totalTime, detail: totalTimeString, color: .time)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .alert(NSLocalizedString("Duplicate Workout", comment: "Alert title"), isPresented: $isDuplicateAlertVisible) {
            Button(ActionStrings.cancel, role: .cancel, action: {})
            Button(ActionStrings.import) {
                workout.status = .new
                process()
            }
        } message: {
            Text(NSLocalizedString("Looks like this workout already exists in Apple Health. Importing it may result in duplicate health metrics. Are you sure you want to continue?", comment: "Alert message"))
        }

    }
    
    @ViewBuilder
    func bottomBar() -> some View {
        HStack {
            Button(action: processConfirmation) {
                Text(ActionStrings.import)
                    .padding(CGFloat(10))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .disabled(!manager.PROCESS_WHITELIST.contains(workout.status))
            
            Button(action: delete) {
                Text(ActionStrings.discard)
                    .padding(CGFloat(10))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding([.leading, .trailing])
        .padding([.top, .bottom], CGFloat(10))
    }
    
    @ViewBuilder
    func rowItem(text: String, detail: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text)
            Text(detail)
                .font(.fixedLargeTitle)
                .foregroundColor(color)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

extension SingleImportView {
    
    func processConfirmation() {
        switch workout.status {
        case .duplicate:
            isDuplicateAlertVisible = true
        case .new:
            process()
        default:
            break
        }
    }
    
    func process() {
        Task(priority: .userInitiated) {
            await manager.processWorkouts(singleWorkout: workout)
        }
    }
    
    func delete() {
        withAnimation {
            manager.delete(workout: workout) { shouldDismiss in
                if shouldDismiss {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
}

extension SingleImportView {
        
    var distanceString: String {
        formattedDistanceString(for: workout.distanceValue, zeroPadding: true)
    }
    
    var elevationString: String? {
        guard let elevation = workout.elevationGainValue else {
            return nil
        }
        return formattedElevationString(for: elevation)
    }
    
    var movingTime: Double {
        workout.totalTimerTimeValue ?? 0
    }
    
    var movingTimeString: String {
        formattedHoursMinutesSecondsDurationString(for: movingTime)
    }
    
    var totalTime: Double {
        workout.totalElapsedTimeValue ?? 0
    }
    
    var totalTimeString: String {
        formattedHoursMinutesSecondsDurationString(for: totalTime)
    }
    
    var pausedTime: Double {
        workout.pausedTimeValue ?? 0
    }
    
    var pausedTimeString: String {
        formattedHoursMinutesSecondsDurationString(for: pausedTime)
    }
    
}

struct SingleImportView_Previews: PreviewProvider {
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    static var manager = ImportManager(viewContext: viewContext)
    
    static var previews: some View {
        NavigationView {
            SingleImportView(workout: manager.singleWorkout)
                .environmentObject(manager)
        }
        .preferredColorScheme(.dark)
    }
}
