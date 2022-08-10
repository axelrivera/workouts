//
//  AdvancedSettingsView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/7/21.
//

import SwiftUI
import CoreData

struct AdvancedSettingsView: View {
    enum ActiveAlert: Identifiable {
        case regenerateWorkouts
        case resetHeartRateZones
        case regenerateWorkoutImages
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var workoutManager: WorkoutManager
    private let provider = HealthProvider.shared
    
    @State private var activeAlert: ActiveAlert?
    @State private var maxHeartRate: Double = 0
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Button(action: { activeAlert = .regenerateWorkouts }) {
                        Text("Reset Workout Data")
                    }
                    
                    if workoutManager.isProcessingRemoteData {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            } footer: {
                Text("Regenerate your local workout data from Apple Health.")
            }
            
            Section {
                Button(action: { activeAlert = .resetHeartRateZones }) {
                    Text("Reset Heart Rate Zones")
                }
            } footer: {
                Text("Regenerate heart rate zones for all workouts using current settings and max heart rate of \(maxHeartRateString).")
            }
            
            Section {
                HStack {
                    Button(action: { activeAlert = .regenerateWorkoutImages }) {
                        Text("Regenerate Workout Maps")
                    }
                    
                    if workoutManager.isProcessingMapImages {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            } footer: {
                Text("Regnerate maps in workout feeds.")
            }
            
            Section {
                NavigationLink("Tags", destination: TagsResetView())
            } footer: {
                Text("Clear tags from existing workouts.")
            }
        }
        .onAppear(perform: load)
        .disabled(isDisabled)
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .regenerateWorkouts:
                let title = "Reset Workouts"
                let message = "This action will reset and regenerate your local workout data from Apple Health."
                
                let action = {
                    Synchronizer.fetchRemoteData(regenerate: true)
                }
                
                return Alert.showAlertWithTitle(title, message: message, action: action)
            case .resetHeartRateZones:
                let title = "Reset Heart Rate Zones"
                let message = "This action will reset and regenerate the heart rate zones for all your workouts using current settings."
                
                let action = {
                    Synchronizer.resetHeartRateZones()
                }
                
                return Alert.showAlertWithTitle(title, message: message, action: action)
            case .regenerateWorkoutImages:
                let title = "Regenerate Workout Maps"
                let message = "This action will regenerate maps for all workout feeds."
                
                let action = {
                    Synchronizer.resetImages()
                }
                
                return Alert.showAlertWithTitle(title, message: message, action: action)
            }
        }
    }
}

extension AdvancedSettingsView {
    
    func load() {
        self.maxHeartRate = Double(provider.maxHeartRate())
    }
    
    var maxHeartRateString: String {
        formattedHeartRateString(for: maxHeartRate)
    }
    
    var isDisabled: Bool {
        workoutManager.isProcessingRemoteData || workoutManager.isProcessingMapImages
    }
    
}

struct AdvancedSettingsView_Previews: PreviewProvider {
    static let viewContext = WorkoutsProvider.preview.container.viewContext
    
    static var previews: some View {
        NavigationView {
            AdvancedSettingsView()
                .environmentObject(WorkoutManagerPreview.manager(context: viewContext))
        }
        .preferredColorScheme(.dark)
    }
}
