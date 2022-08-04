//
//  HeartRateView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/24/21.
//

import SwiftUI

struct HeartRateView: View {
    enum ActiveSheet: Identifiable {
        case edit, editZones, info, explanation
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State private var activeSheet: ActiveSheet?
    
    @StateObject private var zoneManager = HRZoneManager()
    @StateObject private var editManager = HREditManager()
        
    var body: some View {
        Form {
            Section {
                HStack {
                    Label {
                        Text("Max Heart Rate")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "bolt.heart.fill")
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    Text(editManager.formattedMaxHeartRate)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Label {
                        Text("Resting Heart Rate")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }

                    Spacer()
                    Text(editManager.formattedRestingHeartRate)
                        .foregroundColor(.primary)
                }
                
                Button(action: { activeSheet = .edit }) {
                    Text("Edit Heart Rate")
                }
            } header: {
                HStack {
                    Text("Heart Rate")
                    Spacer()
                    Button(action: { activeSheet = .info }) {
                        Image(systemName: "info.circle")
                            .font(.body)
                    }
                }
            } footer: {
                Text("Max and resting heart rates are used to calculate heart rate zones and training load.")
            }
            .task { await editManager.load() }
            
            Section {
                ForEach(HRZone.allCases) { zone in
                    HRSectionRow(zone: zone)
                        .environmentObject(zoneManager)
                }
                
                Button(action: { activeSheet = .editZones }) {
                    Text("Edit Heart Rate Zones")
                }
            } header: {
                HStack {
                    Text("Heart Rate Zones")
                    Spacer()
                    Button(action: { activeSheet = .explanation }) {
                        Image(systemName: "info.circle")
                            .font(.body)
                    }
                }
            }
            .onAppear { zoneManager.load() }
        }
        .navigationTitle("Heart")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet, onDismiss: { editManager.load() }) { sheet in
            switch sheet {
            case .edit:
                HREditView()
                    .environmentObject(editManager)
            case .editZones:
                HRZonesEditView()
                    .environmentObject(zoneManager)
            case .info:
                SafariView(urlString: URLStrings.heartRateInfo)
            case .explanation:
                HeartRateInfoView()
            }
        }
    }
}

struct HeartRateView_Previews: PreviewProvider {
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    static var previews: some View {
        NavigationView {
            HeartRateView()
                .environmentObject(purchaseManager)
        }
        .preferredColorScheme(.dark)
    }
}

struct HRSectionRow: View {
    var zone: HRZone
    
    @Environment(\.isEnabled) var isEnabled
    @EnvironmentObject var manager: HRZoneManager
    
    private let opacityValue = 0.5
    
    var zoneColor: Color {
        isEnabled ? zone.color : zone.color.opacity(opacityValue)
    }
    
    var primaryColor: Color {
        isEnabled ? .primary : .primary.opacity(opacityValue)
    }
    
    var secondaryColor: Color {
        isEnabled ? .secondary : .secondary.opacity(opacityValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5.0) {
            HStack(alignment: .lastTextBaseline) {
                Text(zone.name)
                    .font(.fixedTitle3)
                    .foregroundColor(zoneColor)
                
                Spacer()
                
                Text(zone.zoneString)
                    .font(.fixedBody)
                    .foregroundColor(zoneColor)
            }
            
            HStack {
                Text(HRZonesCalculator.stringForRange(range))
                    .font(.body)
                    .foregroundColor(primaryColor)
                Spacer()
                Text(HRZonesCalculator.stringForPercentRange(percentRange))
                    .font(.fixedSubheadline)
                    .foregroundColor(secondaryColor)
            }
        }
    }
    
    var range: HRZonesCalculator.ZoneRange {
        manager.calculator.rangeForZone(zone)
    }
    
    var percentRange: HRZonesCalculator.ZonePercentRange {
        manager.calculator.percentRangeForZone(zone)
    }
}
