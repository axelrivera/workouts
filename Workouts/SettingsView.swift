//
//  SettingsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var workoutManager: WorkoutManager
        
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preferences")) {
                    Text("Distance")
                    Text("Temperature")
                }
            }
            .navigationBarTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: doneButton())
        }
    }
}

// MARK: - Methods

extension SettingsView {
    
    func doneButton() -> some View{
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Text("Done")
                .bold()
        }
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(WorkoutManager())
    }
}
