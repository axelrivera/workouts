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
    
    enum ActiveAlert: Identifiable {
        case allConfirmation
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
    
    @StateObject private var zoneManager = HRZoneManager()
    @StateObject private var editManager = HREditManager()
        
    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Max Heart Rate", systemImage: "arrow.up.heart.fill")
                    Spacer()
                    Text(editManager.estimateMaxHeartRateString)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Resting Heart Rate", systemImage: "arrow.down.heart.fill")
                    Spacer()
                    Text(editManager.recentRestingHeartRateString)
                        .foregroundColor(.secondary)
                }
                
                Button(action: { activeSheet = .edit }) {
                    Label("Edit Heart Rate", systemImage: "slider.horizontal.3")
                }
            }
            .onAppear { editManager.loadValues() }
            
            Section {
                ForEach(HRZone.allCases) { zone in
                    HRSectionRow(zone: zone)
                        .environmentObject(zoneManager)
                }
                
                Button(action: { activeSheet = .editZones }) {
                    Label("Edit Zones", systemImage: "slider.horizontal.3")
                }
            } header: {
                Text("Heart Rate Zones")
            }
            
            Section {
                Button(action: { activeAlert = .allConfirmation }) {
                    Label("Apply to All Workouts", systemImage: "calendar.badge.clock")
                }
            }
            
//            Section(header: Text("Help")) {
//                Button(action: { activeSheet = .info }) {
//                    Label("Learn More", systemImage: "info.circle")
//                }
//
//                Button(action: { activeSheet = .explanation }) {
//                    Label("Heart Rate Zones Explained", systemImage: "lightbulb")
//                }
//            }
        }
        .navigationTitle("Heart Rate")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
                HREditView(manager: editManager)
            case .editZones:
                HRZonesEditView(action: saveAction)
                    .environmentObject(HRZoneManager())
            case .info:
                SafariView(urlString: URLStrings.heartRateInfo)
            case .explanation:
                HeartRateInfoView()
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .allConfirmation:
                let title = "Update All Workouts?"
                let message = "This action will update all your existing workouts with your current Max Heart Rate and Current Zones."
                
                return Alert.showAlertWithTitle(title, message: message, action: applyAllAction)
            }
        }
    }
}

// MARK: - Actions

extension HeartRateView {
    
    func saveAction(heartRate: Int, values: [Int]) {
        AnalyticsManager.shared.capture(.savedHRZone)
        
        zoneManager.maxHeartRate = Double(heartRate)
        zoneManager.values = values
        AppSettings.maxHeartRate = heartRate
        AppSettings.heartRateZones = values
        activeSheet = nil
    }
    
    func applyAllAction() {
        AnalyticsManager.shared.capture(.applyAllHRZones)
        
        let heartRate = AppSettings.maxHeartRate
        let values = AppSettings.heartRateZones
        Workout.batchUpdateHeartRateZones(with: heartRate, values: values, in: managedObjectContext)
    }
    
}

struct HeartRateView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
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
    @EnvironmentObject var zoneManager: HRZoneManager
    
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
                Text(HRZoneManager.stringForRange(range))
                    .font(.body)
                    .foregroundColor(primaryColor)
                Spacer()
                Text(HRZoneManager.stringForPercentRange(percentRange))
                    .font(.fixedSubheadline)
                    .foregroundColor(secondaryColor)
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
