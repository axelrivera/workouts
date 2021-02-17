//
//  SettingsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State var weight: Double? = AppSettings.weight
    @State var showingWeightAlert = false
            
    var body: some View {
        NavigationView {
            Form {
                VStack {
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text(formattedWeightString(for: weight))
                    }
                    
                    Divider()
                    
                    Text("Your weight is used to calculate the total amount of calories when importing a workout.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Button(action: updateWeight) {
                    Text("Get Weight from Health App")
                }
                .alert(isPresented: $showingWeightAlert) {
                    Alert(
                        title: Text("Health Error"),
                        message: Text("Unable to fetch weight from Health App. Make sure Workouts has permission to access your weight in the Health app."),
                        dismissButton: .default(Text("Ok"))
                    )
                }
            }
            .navigationBarTitle("Settings")
        }
    }
}

// MARK: - Methods

extension SettingsView {
    
    func updateWeight() {
        ProfileDataStore.fetchWeightInKilograms { value in
            if let weight = value {
                AppSettings.weight = weight
                self.weight = weight
            } else {
               showingWeightAlert = true
            }
        }
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(WorkoutManager())
    }
}
