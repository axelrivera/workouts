//
//  HRZonesEditView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/24/21.
//

import SwiftUI

extension HRZonesEditView {
    
    enum DisplayType {
        case config, workout
    }
    
}

struct HRZonesEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var zoneManager: HRZoneManager
    
    let action: HRZoneManagerAction
    
    init(action: @escaping HRZoneManagerAction) {
        self.action = action
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Max Heart Rate")
                        Spacer()
                        Text(zoneManager.maxHeartRateString)
                            .foregroundColor(.secondary)
                    }
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
            .onAppear { AnalyticsManager.shared.logPage(.editHRZones)}
            .navigationTitle("Edit Zones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { presentationMode.wrappedValue.dismiss() })
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
        }
    }
    
}

// MARK: - Actions

extension HRZonesEditView {
    
    func save() {
        action(Int(zoneManager.maxHeartRate), zoneManager.values)
    }
    
}

struct HRZonesEditView_Previews: PreviewProvider {
    
    static func saveAction(_ heartRate: Int, _ values: [Int]) {
        // no-op
    }
    
    static var previews: some View {
        HRZonesEditView(action: saveAction)
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
