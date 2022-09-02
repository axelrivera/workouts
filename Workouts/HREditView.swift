//
//  HREditView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/19/22.
//

import SwiftUI

struct HREditView: View {
    enum Field {
        case max, resting
    }
    
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var manager: HREditManager
    
    @State private var maxHeartRate = ""
    @State private var isMaxHeartRateValid = true
    
    @State private var restingHeartRate = ""
    @State private var isRestingHeartRateValid = true
    
    @FocusState private var focusedField: Field?
    
    @State var isPresentingValidationError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text(LabelStrings.maxHeartRate)
                            .foregroundColor(isMaxHeartRateValid ? .secondary : .red)
                        Spacer()
                        
                        if manager.useFormulaMaxHeartRate {
                            Text(estimateHeartRateString)
                        } else {
                            TextField(LabelStrings.bpm, text: $maxHeartRate.animation())
                                .focused($focusedField, equals: .max)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                                
                                .onChange(of: maxHeartRate) { newValue in
                                    if isNumberString(newValue) {
                                        manager.maxHeartRate = Int(newValue) ?? 0
                                    } else {
                                        maxHeartRate = maxHeartRateString
                                    }
                                }
                        }
                    }
                    
                    Toggle(HeartRateStrings.useFormula, isOn: $manager.useFormulaMaxHeartRate)
                        .foregroundColor(.secondary)
                } footer: {
                    Text(NSLocalizedString("Estimate Max Heart Rate using formula. Date of Birth is required.", comment: "Heart rate footer"))
                }
                
                Section {
                    HStack {
                        Text(LabelStrings.restingHeartRate)
                            .foregroundColor(isRestingHeartRateValid ? .secondary : .red)
                        Spacer()
                        
                        if manager.useHealthRestingHeartRate {
                            Text(recentRestingHeartRateString)
                        } else {
                            TextField(LabelStrings.bpm, text: $restingHeartRate.animation())
                                .focused($focusedField, equals: .resting)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                                .onChange(of: restingHeartRate) { newValue in
                                    if isNumberString(newValue) {
                                        manager.restingHeartRate = Int(newValue) ?? 0
                                    } else {
                                        restingHeartRate = restingHeartRateString
                                    }
                                }
                        }
                    }
                    
                    Toggle(HeartRateStrings.useRecentValue, isOn: $manager.useHealthRestingHeartRate)
                        .foregroundColor(.secondary)
                } footer: {
                    if manager.useHealthRestingHeartRate {
                        if let _ = manager.recentRestingHeartRate {
                            Text(NSLocalizedString("Using your avg resting heart rate over the past 30 days.", comment: "Heart rate footer"))
                        } else {
                            Text(NSLocalizedString("Your resting heart rate is not available on Apple Health. Better Workouts will use a default value but results are different for every individual. Please update your resting heart rate manually to get better results.", comment: "heart rate footer"))
                                .foregroundColor(.red)
                        }
                    } else {
                        if let _ = manager.recentRestingHeartRate {
                            Text(String(format: NSLocalizedString("The avg resting heart rate over the past 30 days is %@.", comment: "Footer"), recentRestingHeartRateString))
                        }
                    }
                }
                
                Section {
                    row(text: NSLocalizedString("Date of Birth", comment: "Label"), detail: dateOfBirthString)
                    row(text: NSLocalizedString("Sex", comment: "Label"), detail: genderString)
                } header: {
                    Text(NSLocalizedString("Health Details", comment: "Label"))
                } footer: {
                    Text(NSLocalizedString("Use the Health App to configure your date of birth and gender. The values are needed to calculate your max heart rate and training load.", comment: "Footer"))
                }
            }
            .navigationTitle(LabelStrings.heartRate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(ActionStrings.done, action: { focusedField = nil })
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button(ActionStrings.cancel, action: dismiss)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActionStrings.save, action: save)
                }
            }
            .onAppear(perform: loadValues)
            .alert(NSLocalizedString("Validation Error", comment: "Alert title"), isPresented: $isPresentingValidationError, actions: {
                Button(ActionStrings.ok, role: .cancel) {}
            }, message: {
                Text(NSLocalizedString("Max heart rate and resting heart rate cannot be empty.", comment: "Alert message"))
            })
        }
    }
    
    @ViewBuilder
    func row(text: String, detail: String) -> some View {
        HStack {
            Text(text)
            Spacer()
            Text(detail)
                .foregroundColor(.secondary)
        }
    }
}

extension HREditView {
    
    func loadValues() {
        maxHeartRate = maxHeartRateString
        restingHeartRate = restingHeartRateString
    }
    
    func save() {
        do {
            try manager.save()
            dismiss()
        } catch {
            withAnimation {
                isMaxHeartRateValid = manager.isMaxHeartRateValid
                isRestingHeartRateValid = manager.isRestingHeartRateValid
                isPresentingValidationError = true
            }
        }
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
    
    func isNumberString(_ value: String) -> Bool {
        if value.isEmpty {
            return true
        } else {
            let nonNumbers = CharacterSet.decimalDigits.inverted
            return value.rangeOfCharacter(from: nonNumbers) == nil
        }
    }
    
    // MARK: Max Heart Rate
    
    var estimateHeartRateString: String {
        let value = manager.estimateMaxHeartRate ?? AppSettings.DEFAULT_MAX_HEART_RATE
        return formattedHeartRateString(for: Double(value))
    }
    
    var maxHeartRateString: String {
        manager.maxHeartRate > 0 ? "\(manager.maxHeartRate)" : ""
    }
    
    // MARK: Resting Heart Rate
    
    var recentRestingHeartRateString: String {
        let value = manager.recentRestingHeartRate ?? AppSettings.DEFAULT_RESTING_HEART_RATE
        return formattedHeartRateString(for: Double(value))
    }
    
    var restingHeartRateString: String {
        manager.restingHeartRate > 0 ? "\(manager.restingHeartRate)" : ""
    }
    
    // MARK: Date and Gender
    
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
        HREditView()
            .environmentObject(HREditManager())
            .preferredColorScheme(.dark)
    }
}
