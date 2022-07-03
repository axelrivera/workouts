//
//  HREditView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/19/22.
//

import SwiftUI

struct HREditView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var manager: HREditManager
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Max Heart Rate")
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        if !manager.isMaxHeartRateFormulaDisabled() && manager.useFormulaMaxHeartRate {
                            Text(estimateHeartRateString)
                        } else {
                            TextField("bpm", text: $manager.restingHeartRateString)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done", action: {})
                                    }
                                }
                        }
                    }
                    
                    Toggle("Use Formula", isOn: $manager.useFormulaMaxHeartRate)
                        .foregroundColor(.secondary)
                        .disabled(manager.isMaxHeartRateFormulaDisabled())
                } footer: {
                    Text("Estimate Max Heart Rate using formula. Date of Birth is required.")
                }
                
                Section {
                    HStack {
                        Text("Resting Heart Rate")
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        if !manager.isRecentHealthRestingHeartRateDisabled() && manager.useHealthRestingHeartRate {
                            Text(recentRestingHeartRateString)
                        } else {
                            TextField("bpm", text: .constant(""))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                        }
                    }
                    
                    Toggle("Use Recent Value", isOn: $manager.useHealthRestingHeartRate)
                        .foregroundColor(.secondary)
                        .disabled(manager.isRecentHealthRestingHeartRateDisabled())
                    
                } footer: {
                    if manager.useHealthRestingHeartRate {
                        Text("Using your avg resting heart rate over the past 30 days.")
                    } else {
                        Text("The avg resting heart rate over the past 30 days is 60 bpm.")
                    }
                }
                
                Section {
                    row(text: "Date of Birth", detail: dateOfBirthString)
                    row(text: "Sex", detail: genderString)
                } header: {
                    Text("Health Details")
                } footer: {
                    Text("Use the Health App to configure your date of birth and gender. The values are needed to calculate your max heart rate and training load.")
                }
            }
            .navigationTitle("Heart Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { presentationMode.wrappedValue.dismiss() })
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: {})
                }
            }
        }
    }
    
    @ViewBuilder
    func row(text: String, detail: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.secondary)
            Spacer()
            Text(detail)
        }
    }
}

extension HREditView {
    
    var estimateHeartRateString: String {
        formattedHeartRateString(for: Double(manager.estimateMaxHeartRate ?? 0))
    }
    
    var recentRestingHeartRateString: String {
        formattedHeartRateString(for: Double(manager.recentRestingHeartRate ?? 0))
    }
    
    var dateOfBirthString: String {
        guard let dateOfBirth = manager.dateOfBirth, let age = manager.age else { return "n/a" }
        let dobString = dateOfBirth.formatted(date: .abbreviated, time: .omitted)
        let ageString = age.formatted()
        return String(format: "%@ (%@)", dobString, ageString)
    }
    
    var genderString: String {
        manager.userGender.title
    }
    
}

struct HREditView_Previews: PreviewProvider {
    static var previews: some View {
        HREditView(manager: HREditManager())
            .preferredColorScheme(.dark)
    }
}
