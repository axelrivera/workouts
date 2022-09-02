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
                        Text(NSLocalizedString("Reset All Workouts", comment: "Action"))
                    }
                    
                    if workoutManager.isProcessingRemoteData {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            } footer: {
                Text(NSLocalizedString("Regenerate your local workout data from Apple Health.", comment: "Footer"))
            }
            
            Section {
                Button(action: { activeAlert = .resetHeartRateZones }) {
                    Text(NSLocalizedString("Reset Heart Rate Zones", comment: "Action"))
                }
            } footer: {
                Text(
                    String(
                        format: "%@ %@",
                        NSLocalizedString("Regenerate heart rate zones for all workouts using current settings and max heart rate of %@.", comment: "Text"),
                        maxHeartRateString
                    )
                )
            }
            
            Section {
                HStack {
                    Button(action: { activeAlert = .regenerateWorkoutImages }) {
                        Text(NSLocalizedString("Regenerate Workout Maps", comment: "Action"))
                    }
                    
                    if workoutManager.isProcessingMapImages {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            } footer: {
                Text(NSLocalizedString("Regnerate maps in workout feeds.", comment: "Footer"))
            }
            
            Section {
                NavigationLink(LabelStrings.tags, destination: TagsResetView())
            } footer: {
                Text(NSLocalizedString("Clear tags from existing workouts.", comment: "Footer"))
            }
        }
        .onAppear(perform: load)
        .disabled(isDisabled)
        .navigationTitle(NSLocalizedString("Advanced Settings", comment: "Screen title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .regenerateWorkouts:
                let title = NSLocalizedString("Reset All Workouts", comment: "Alert title")
                let message = NSLocalizedString("This action will reset and regenerate your local workout data from Apple Health.", comment: "Alert message")
                
                return Alert.showAlertWithTitle(title, message: message, action: regenerate)
            case .resetHeartRateZones:
                let title = NSLocalizedString("Reset Heart Rate Zones", comment: "Alert title")
                let message = NSLocalizedString("This action will reset and regenerate the heart rate zones for all your workouts using current settings.", comment: "Alert message")
                
                let action = {
                    Synchronizer.resetHeartRateZones()
                }
                
                return Alert.showAlertWithTitle(title, message: message, action: action)
            case .regenerateWorkoutImages:
                let title = NSLocalizedString("Regenerate Workout Maps", comment: "Alert title")
                let message = NSLocalizedString("This action will regenerate maps for all workout feeds.", comment: "Alert message")
                
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
    
    func regenerate() {
        do {
            FileManager.deleteImageCacheDirectory()
            try FileManager.createImagesCacheDirectoryIfNeeded()
        } catch {
            Log.debug("error deleting images directory: \(error.localizedDescription)")
        }
        Synchronizer.fetchRemoteData(regenerate: true)
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
