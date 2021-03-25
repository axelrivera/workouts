//
//  SettingsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI

struct SettingsView: View {
    enum ActiveSheet: Identifiable {
        case pro, feedback
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var weight: Double = AppSettings.weight
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text("Purchasing helps support Better Workouts")) {
                    Button(action: { activeSheet = .pro }, label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Unlock all Better Workout Features")
                                .foregroundColor(.primary)
                        }
                    })
                }
                
                Section(header: Text("Application Settings")) {
                    NavigationLink(destination: WeightInputView(weight: $weight)) {
                        HStack {
                            Text("Weight")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formattedWeightString(for: weight))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section(header: Text("Help Center"), footer: Text("Helpful hints to learn how to make the most out of Better Workouts.")) {
                    NavigationLink("Import Workout Tutorial", destination: Text("Import Tutorial"))
                    NavigationLink("Frequently Asked Questions", destination: Text("FAQ"))
                    Button("Send Feedback", action: {})
                }
                
                Section(header: Text("Better Workouts")) {
                    Button("Review on the App Store", action: {})
                    NavigationLink("Privacy Policy", destination: Text("Privacy Policy"))
                    HStack {
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1.0 (13)")
                    }
                }
                
            }
            .navigationBarTitle("Settings")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .pro:
                    ProView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(WorkoutManager())
            .colorScheme(.dark)
    }
}
