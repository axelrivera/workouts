//
//  HeartRateEditView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/24/21.
//

import SwiftUI

extension HeartRateEditView {
    
    enum DisplayType {
        case config, workout
    }
    
}

struct HeartRateEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var zoneManager: HRZoneManager
    
    let action: HRZoneManagerAction
    
    init(action: @escaping HRZoneManagerAction) {
        self.action = action
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text("Your maximum heart rate is about 220 minus your age. For example, if you're 30 years old, subtract 30 from 220 to get a maximum heart rate of 190 bpm.")) {
                    HStack {
                        Text("Max Heart Rate")
                        Spacer()
                        Text(zoneManager.maxHeartRateString)
                            .foregroundColor(.red)
                    }
                    Slider(value: $zoneManager.maxHeartRate, in: 140...220, step: 1)
                }
                
                Section {
                    ForEach(HRZone.allCases) {
                        HREditSectionRow(zone: $0)
                            .environmentObject(zoneManager)
                    }
                }
                
                Section(footer: Text("Resetting will use your Max Heart Rate to calculate new zones based on default values. You can adjust further to meet your training goals.")) {
                    Button("Reset Zones", action: zoneManager.autoCalculate)
                        .accentColor(.red)
                }
            }
            .navigationTitle("Edit Zones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: save) {
                        Text("Save")
                            .bold()
                    }
                }
            }
        }
    }
    
}

// MARK: - Actions

extension HeartRateEditView {
    
    func save() {
        action(Int(zoneManager.maxHeartRate), zoneManager.values)
    }
    
}

struct HeartRateEditView_Previews: PreviewProvider {
    
    static func saveAction(_ heartRate: Int, _ values: [Int]) {
        // no-op
    }
    
    static var previews: some View {
        HeartRateEditView(action: saveAction)
            .environmentObject(HRZoneManager())
            .preferredColorScheme(.dark)
    }
}

// MARK: - Section Row

struct HREditSectionRow: View {
    var zone: HRZone
    @EnvironmentObject var zoneManager: HRZoneManager
        
    var body: some View {
        VStack(alignment: .leading, spacing: 5.0) {
            HStack(alignment: .lastTextBaseline) {
                Text(zone.name)
                    .font(.fixedTitle3)
                    .foregroundColor(zone.color)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Text(zone.zoneString)
                    .font(.fixedBody)
                    .foregroundColor(zone.color)
            }
            
            Text(textString())
                .font(.fixedSubheadline)
                .foregroundColor(.secondary)
                        
            Stepper(
                onIncrement: { zoneManager.incrementZone(zone) },
                onDecrement: { zoneManager.decrementZone(zone)}) {
                inputLabel()
            }
        }
    }
        
    var range: HRZoneManager.ZoneRange {
        zoneManager.rangeForZone(zone)
    }
    
    var percentRange: HRZoneManager.ZonePercentRange {
        zoneManager.percentRangeForZone(zone)
    }
    
    func textString() -> String {
        HRZoneManager.stringForPercentRange(percentRange)
    }
    
    func inputLabel() -> some View {
        HStack {
            Text("\(range.low)")
                .padding(5)
                .background(zone.color.opacity(0.3))
                .cornerRadius(5)
                
            
            Text("-")
            
            Text(range.high > 0 ? "\(range.high)" : "∞")
                .padding(5)
                .background(Color.systemFill)
                .cornerRadius(5)
        }
    }
    
}
