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
    @StateObject private var manager = HREditManager()
    
    @State private var calculator = HRZonesCalculator.empty()
    @State private var zones = HRZone.allCases
    @State private var activeSheet: ActiveSheet?
        
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
                    Text(manager.formattedMaxHeartRate)
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
                    Text(manager.formattedRestingHeartRate)
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
            
            Section {
                ForEach(zones, id: \.id) { zone in
                    HRSectionRow(calculator: $calculator, zone: zone)
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
        }
        .onAppear(perform: load)
        .navigationTitle("Heart")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet, onDismiss: load) { sheet in
            switch sheet {
            case .edit:
                HREditView()
                    .environmentObject(manager)
            case .editZones:
                HRZonesEditView()
            case .info:
                SafariView(urlString: URLStrings.heartRateInfo)
            case .explanation:
                HeartRateInfoView()
            }
        }
    }
}

extension HeartRateView {
    
    func load() {
        Task(priority: .userInitiated) {
            await manager.load()
            loadZonesCalculator()
        }
    }
    
    func loadZonesCalculator() {
        calculator = HealthProvider.shared.heartRateZonesCalculator()
        zones = HRZone.allCases
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
    @Environment(\.isEnabled) var isEnabled
    
    private let opacityValue = 0.5
    
    @Binding var calculator: HRZonesCalculator
    var zone: HRZone
    
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
        calculator.rangeForZone(zone)
    }
    
    var percentRange: HRZonesCalculator.ZonePercentRange {
        calculator.percentRangeForZone(zone)
    }
}
