//
//  AdvancedSettingsView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/7/21.
//

import SwiftUI

struct AdvancedSettingsView: View {
    enum ActiveAlert: Identifiable {
        case regenerateWorkouts, resetCachedImages
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State private var activeAlert: ActiveAlert?
    
    var body: some View {
        ZStack {
            Form {
                Section(footer: Text("Regenerate your local workout data from Apple Health.")) {
                    Button(action: { activeAlert = .regenerateWorkouts }) {
                        Text("Reset Workout Data")
                    }
                }
                
                Section(footer: Text("Deletes all cached images for maps.")) {
                    Button(action: { activeAlert = .resetCachedImages }) {
                        Text("Reset Map Images")
                    }
                }
            }
            .disabled(workoutManager.isProcessingRemoteData)
            
            if workoutManager.isProcessingRemoteData {
                ProcessView(
                    title: "Processing Workouts",
                    value: $workoutManager.processingRemoteDataValue
                )
            }
        }
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .regenerateWorkouts:
                let title = "Reset Workouts"
                let message = "This action will reset and regenerate your local workout data from Apple Health."
                
                let action = {
                    let userInfo = [Notification.regenerateDataKey: true]
                    NotificationCenter.default.post(
                        name: .shouldFetchRemoteData,
                        object: nil,
                        userInfo: userInfo
                    )
                }
                
                return Alert.showAlertWithTitle(title, message: message, action: action)
            case .resetCachedImages:
                let title = "Reset Map Images"
                let message = "This action will reset all cached images used in maps."
                
                let action = {
                    let cache = MapImageCache.getImageCache()
                    cache.resetAll()
                }
                
                return Alert.showAlertWithTitle(title, message: message, action: action)
            }
        }
    }
}

struct AdvancedSettingsView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static var previews: some View {
        NavigationView {
            AdvancedSettingsView()
                .environmentObject(WorkoutManagerPreview.manager(context: viewContext))
        }
        .preferredColorScheme(.dark)
    }
}
