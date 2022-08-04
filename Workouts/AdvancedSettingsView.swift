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
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State private var activeAlert: ActiveAlert?
    
    var body: some View {
        Form {
            Section(footer: Text("Regenerate your local workout data from Apple Health.")) {
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
            }
            
            Section(footer: Text("Clear tags from existing workouts.")) {
                NavigationLink("Tags", destination: TagsResetView())
            }
        }
        .disabled(workoutManager.isProcessingRemoteData)
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
            }
        }
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
