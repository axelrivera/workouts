//
//  AddView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/21/20.
//

import SwiftUI

struct AddView: View {
    enum Sports: String, Identifiable, CaseIterable {
        case cycle, run, walk
        
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
        
        static var titles = allCases.map { $0.title }
        static func value(for index: Int) -> Sports { allCases[index] }
    }
    
    @Environment(\.presentationMode) var presentationMode
        
    @State private var selectedSport = 0
    @State private var date = Date()
    @State private var totalSeconds = 0.0
    @State private var paceSeconds = 0.0
    @State private var miles = ""
    @State private var avgSpeed = ""
    @State private var calories = ""
    @State private var heartRate = ""
    @State private var elevation = ""
    
    @State private var showTimePicker = false
    @State private var showPacePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Activity", selection: $selectedSport) {
                    ForEach(0 ..< Sports.titles.count) {
                        Text(Sports.titles[$0])
                    }
                }

                DatePicker("Date", selection: $date)
                
                Button(action: { withAnimation(.spring()) { showTimePicker.toggle() } }) {
                    HStack {
                        Text("Total Time")
                        Spacer()
                        Text(formattedTimer(for: Int(totalSeconds)))
                            .foregroundColor(showTimePicker ? .accentColor : .primary)
                        Image(systemName: showTimePicker ? "chevron.down" : "chevron.up")
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if showTimePicker {
                    TimePicker(pickerType: .hours, totalSeconds: $totalSeconds)
                }
                
                HStack {
                    Text("Distance")
                        .padding(.trailing)
                    TextField("Miles", text: $miles)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
                
                if Sports.value(for: selectedSport) == .cycle {
                    HStack {
                        Text("Avg. Speed")
                            .padding(.trailing)
                        TextField("MPH", text: $avgSpeed)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                } else {
                    Button(action: { withAnimation(.spring()) { showPacePicker.toggle() } }) {
                        HStack {
                            Text("Avg. Pace")
                            Spacer()
                            Text(formattedTimer(for: Int(paceSeconds)))
                                .foregroundColor(showPacePicker ? .accentColor : .primary)
                            Image(systemName: showPacePicker ? "chevron.down" : "chevron.up")
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if showPacePicker {
                        TimePicker(pickerType: .hours, totalSeconds: $totalSeconds)
                    }
                }
                
                HStack {
                    Text("Calories")
                        .padding(.trailing)
                    TextField("CAL", text: $calories)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
                
                HStack {
                    Text("Avg. Heart Rate")
                        .padding(.trailing)
                    TextField("BPM", text: $heartRate)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
                
                HStack {
                    Text("Elevation Gain")
                        .padding(.trailing)
                    TextField("FEET", text: $elevation)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Workout")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: dismissButton(), trailing: saveButton())
        }
    }
}

extension AddView {
    
    func dismissButton() -> some View {
        Button("Cancel", action: { presentationMode.wrappedValue.dismiss() })
    }
    
    func saveButton() -> some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Text("Save")
        }
    }
    
}

struct AddView_Previews: PreviewProvider {
    static var previews: some View {
        AddView()
    }
}
