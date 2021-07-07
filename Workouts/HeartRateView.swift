//
//  HeartRateView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/24/21.
//

import SwiftUI

struct HeartRateView: View {
    enum ActiveSheet: Identifiable {
        case edit
        var id: Int { hashValue }
    }
    
    @StateObject var zoneManager = HRZoneManager()
    @State private var activeSheet: ActiveSheet?
    
    let heartRateValues: [Int] = Array(120 ... 220)
    
    var body: some View {
        Form {
            Section(header: Color.clear.frame(height: 20)) {
                Picker("Max Heart Rate", selection: $zoneManager.maxHeartRate) {
                    ForEach(heartRateValues, id: \.self) {
                        Text("\($0) bpm")
                    }
                }
                
                Button(action: { zoneManager.autoCalculate() }) {
                    Label("Auto Calculate", systemImage: "plusminus")
                }
            }
            
            Section {
                ForEach(HRZone.allCases) { zone in
                    HRSectionRow(zone: zone)
                        .environmentObject(zoneManager)
                }
            }
            
            Button(action: { activeSheet = .edit }) {
                Label("Edit Zones", systemImage: "slider.horizontal.3")
            }
        }
        .navigationBarTitle("Heart Rate Zones")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
                HeartRateEditView()
                    .environmentObject(zoneManager)
            }
        }
    }
}

struct HeartRateView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HeartRateView()
        }
        .preferredColorScheme(.dark)
    }
}

struct HRSectionRow: View {
    var zone: HRZone
    @EnvironmentObject var zoneManager: HRZoneManager

    var body: some View {
        VStack(alignment: .leading, spacing: 5.0) {
            HStack(alignment: .lastTextBaseline) {
                Text(zone.name)
                    .font(.title3)
                    .foregroundColor(zone.color)
                
                Spacer()
                
                Text(zone.zoneString)
                    .font(.body)
                    .foregroundColor(zone.color)
            }
            
            HStack {
                Text(HRZoneManager.stringForRange(range))
                    .font(.body)
                Spacer()
                Text(HRZoneManager.stringForPercentRange(percentRange))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var range: HRZoneManager.ZoneRange {
        zoneManager.rangeForZone(zone)
    }
    
    var percentRange: HRZoneManager.ZonePercentRange {
        zoneManager.percentRangeForZone(zone)
    }
}
