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
    @StateObject var manager = HRZoneManager()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Max Heart Rate")
                        Spacer()
                        Text(manager.maxHeartRateString)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    ForEach(HRZone.allCases) {
                        HREditSectionRow(zone: $0)
                            .environmentObject(manager)
                    }
                }
                
                Section(footer: Text("Resetting will use your Max Heart Rate to calculate new zones based on default values. You can adjust further to meet your training goals.")) {
                    Button("Reset Zones", action: manager.autoCalculate)
                        .accentColor(.red)
                }
            }
            .onAppear(perform: load)
            .navigationTitle("Edit Zones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss)
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
    
    func load() {
        AnalyticsManager.shared.logPage(.editHRZones)
        manager.load()
    }
    
    func save() {
        AnalyticsManager.shared.capture(.savedHRZone)
        AppSettings.heartRateZonePercents = manager.calculator.percentValues
        dismiss()
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
    
}

struct HRZonesEditView_Previews: PreviewProvider {
    
    static var previews: some View {
        HRZonesEditView()
            .environmentObject(HRZoneManager())
            .preferredColorScheme(.dark)
    }
}

// MARK: - Section Row

struct HREditSectionRow: View {
    var zone: HRZone
    @EnvironmentObject var manager: HRZoneManager
        
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
                onIncrement: { manager.incrementZone(zone) },
                onDecrement: { manager.decrementZone(zone)}) {
                inputLabel()
            }
        }
    }
        
    var range: HRZonesCalculator.ZoneRange {
        manager.calculator.rangeForZone(zone)
    }
    
    var percentRange: HRZonesCalculator.ZonePercentRange {
        manager.calculator.percentRangeForZone(zone)
    }
    
    func textString() -> String {
        HRZonesCalculator.stringForPercentRange(percentRange)
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
