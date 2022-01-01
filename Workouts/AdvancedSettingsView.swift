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
        case regenerateWorkouts, resetCachedImages
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State private var activeAlert: ActiveAlert?
    
    var body: some View {
        Form {
            Section(footer: Text("Regenerate your local workout data from Apple Health.")) {
                Button(action: { activeAlert = .regenerateWorkouts }) {
                    Text("Reset Workout Data")
                }
            }
            
            Section(footer: Text("Regenerates all cached maps in Workouts feed.")) {
                Button(action: { activeAlert = .resetCachedImages }) {
                    Text("Reset Maps")
                }
            }
            
            Section(footer: Text("Clear tags from existing workouts.")) {
                NavigationLink("Tags", destination: TagsResetView())
            }
        }
        .disabled(workoutManager.isProcessingRemoteData)
        .overlay(processOverlay())
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .regenerateWorkouts:
                let title = "Reset Workouts"
                let message = "This action will reset and regenerate your local workout data from Apple Health."
                
                let action = {
                    DispatchQueue.main.async {
                        WorkoutMetadata.fixDuplicates(in: viewContext)
                        
                        NotificationCenter.default.post(
                            name: .shouldFetchRemoteData,
                            object: nil,
                            userInfo: [ Notification.regenerateDataKey: true ]
                        )
                    }
                }
                
                return Alert.showAlertWithTitle(title, message: message, action: action)
            case .resetCachedImages:
                let title = "Reset Map Images"
                let message = "This action will reset all cached map images used in the workouts feed."
                
                let action = {
                    let cache = MapImageCache.getImageCache()
                    cache.resetAll()
                }
                
                return Alert.showAlertWithTitle(title, message: message, action: action)
            }
        }
    }
    
    @ViewBuilder func processOverlay() -> some View {
        if workoutManager.isProcessingRemoteData {
            HUDView()
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
