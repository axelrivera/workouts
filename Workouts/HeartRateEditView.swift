//
//  HeartRateEditView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/24/21.
//

import SwiftUI

struct HeartRateEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var zoneManager: HRZoneManager
    
    var body: some View {
        NavigationView {
            Form {
                ForEach(HRZone.allCases) {
                    HREditSectionRow(zone: $0)
                        .environmentObject(zoneManager)
                }
            }
            .navigationBarTitle("Edit Zones")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: resetButton(), trailing: doneButton())
        }
    }
    
    func resetButton() -> some View {
        Button(action: { zoneManager.autoCalculate() }) {
            Text("Reset")
                .font(.body)
                .foregroundColor(.red)
        }
    }
    
    func doneButton() -> some View {
        Button("Done", action: { presentationMode.wrappedValue.dismiss() })
    }
}

struct HeartRateEditView_Previews: PreviewProvider {
    static var previews: some View {
        HeartRateEditView()
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
                    .font(.title3)
                    .foregroundColor(zone.color)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Text(zone.zoneString)
                    .font(.body)
                    .foregroundColor(zone.color)
            }
            
            Text(textString())
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if readOnly {
                inputLabel()
            } else {
                Stepper(
                    onIncrement: { zoneManager.incrementZone(zone) },
                    onDecrement: { zoneManager.decrementZone(zone)}) {
                    inputLabel()
                }
            }
        }
    }
    
    var readOnly: Bool { zone == .zone1 }
    
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
                .background(readOnly ? Color.systemFill : zone.color.opacity(0.3))
                .cornerRadius(5)
                
            
            Text("-")
            
            Text(range.high > 0 ? "\(range.high)" : "∞")
                .padding(5)
                .background(Color.systemFill)
                .cornerRadius(5)
        }
    }
    
}
