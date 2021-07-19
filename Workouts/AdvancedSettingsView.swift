//
//  AdvancedSettingsView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/7/21.
//

import SwiftUI

struct AdvancedSettingsView: View {
    enum ActiveAlert: Identifiable {
        case regenerateWorkouts
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State private var activeAlert: ActiveAlert?
    
    var body: some View {
        ZStack {
            Form {
                Section(header: Color.clear.frame(height: 20), footer: Text("Regenerate your local workout data from Apple Health.")) {
                    Button(action: { activeAlert = .regenerateWorkouts }) {
                        Text("Reset Workout Data")
                    }
                    .disabled(workoutManager.isLoading)
                }
            }
            .disabled(workoutManager.isProcessingRemoteData)
            
            if workoutManager.isProcessingRemoteData {
                ProcessView(text: "Processing Workouts...", value: $workoutManager.processingRemoteDataValue)
            }
        }
        .navigationBarTitle("Advanced Settings")
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
                
                return Alert.contineWithTitle(title, message: message, action: action)
            }
        }
    }
}

struct AdvancedSettingsView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static var previews: some View {
        NavigationView {
            AdvancedSettingsView()
                .environmentObject(WorkoutManager(context: viewContext))
        }
        .preferredColorScheme(.dark)
    }
}
